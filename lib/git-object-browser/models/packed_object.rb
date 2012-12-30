# -*- coding: utf-8 -*-

# https://github.com/git/git/blob/master/sha1_file.c
# https://github.com/git/git/blob/master/patch-delta.c
# https://github.com/git/git/blob/master/builtin/unpack-objects.c
# https://github.com/mojombo/grit/blob/master/lib/grit/git-ruby/internal/pack.rb
module GitObjectBrowser

  module Models

    class PackedObject < BinFile

      attr_reader :header, :raw_data
      attr_reader :object, :object_type, :object_size

      TYPES = %w{
        undefined
        commit
        tree
        blob
        tag
        undefined
        ofs_delta
        ref_delta
      }

      def initialize(index, input)
        super(input)
        @index = index
      end

      def parse(offset)
        parse_raw(offset)

        input = "#{ @object_type } #{ object_size }\0" + @raw_data

        @object = GitObject.new(nil).parse_inflated(input)

        self
      end

      def parse_raw(offset)
        @offset = offset
        @header = parse_header(offset)

        if @header[:type] == 'ofs_delta'
          obj_ofs_delta
        elsif @header[:type] == 'ref_delta'
          obj_ref_delta
        else
          @object_type = @header[:type]
          @object_size = @header[:size]
          @raw_data = zlib_inflate
        end
      end

      def parse_header(offset)
        seek(offset)
        (type, size, header_size) = parse_type_and_size
        type = TYPES[type]
        { :type => type, :size => size, :header_size => header_size }
      end

      def parse_ofs_delta_header(offset, header)
        (delta_offset, delta_header_size) = parse_delta_offset
        header[:base_offset] = offset - delta_offset
        header[:header_size] += delta_header_size
        header
      end

      def parse_ref_delta_header(header)
        header[:base_sha1]   = hex(20)
        header[:header_size] += 20
        header
      end

      def to_hash
        return {
          :type => @header[:type],
          :size => @header[:size],
          :object_type => @object_type,
          :object_size => @object_size,
          :header_size => @header[:header_size],
          :base_offset => @header[:base_offset],
          :delta_commands => @delta_commands,
          :base_size => @base_size,
          :object => @object.to_hash,
        }
      end

      def self.path?(relpath)
        return relpath =~ %r{\Aobjects/pack/pack-[0-9a-f]{40}.pack\z}
      end

      private

      def obj_ofs_delta
        parse_ofs_delta_header(@offset, @header)
        load_base_and_patch_delta
      end

      def obj_ref_delta
        parse_ref_delta_header(@header)
        index_entry = @index.find(@header[:base_sha1])
        @header[:base_offset] = index_entry[:offset]
        load_base_and_patch_delta
      end

      def load_base_and_patch_delta
        begin
          pack = PackedObject.new(@index, @in)
          pack.parse_raw(@header[:base_offset])
          @object_type = pack.object_type
          @base = pack.raw_data
        ensure
          seek(@offset + @header[:header_size])
        end

        switch_source(StringIO.new(zlib_inflate)) { patch_delta }
      end

      def patch_delta
        @base_size  = parse_delta_size
        if @base.size != @base_size
          raise 'incollect base size'
        end

        @object_size = parse_delta_size
        @delta_commands = []
        @raw_data = ''
        while ! @in.eof?
          delta_command
        end
        if @object_size != @raw_data.size
          raise 'incollect delta size'
        end
      end

      def delta_command
        cmd = byte
        data = nil
        if cmd & 0b10000000 != 0
          (offset, size) = parse_base_offset_and_size(cmd)
          data = @base[offset, size]
          @raw_data << data
          @delta_commands << { :source => :base, :offset => offset, :size => size }
        elsif cmd != 0
          size = cmd
          data = raw(size)
          @raw_data << data
          @delta_commands << { :source => :delta, :size => size }
        else
          raise 'delta command is 0'
        end
        @delta_commands.last[:data] = shorten_utf8(data, 2000)
      end

      def shorten_utf8(bin, length)
        str = bin.force_encoding('UTF-8')
        str = '(not UTF-8)' unless str.valid_encoding?
        str = str[0, length] + '...' if str.length > length
        str
      end

      def zlib_inflate
        store = Zlib::Inflate.new
        buffer = ''
        while buffer.size < @header[:size]
          rawdata = raw(4096)
          if rawdata.size == 0
            raise 'inflate error'
          end
          buffer << store.inflate(rawdata)
        end
        store.close
        buffer
      end

      # sha1_file.c unpack_object_header_buffer
      # unpack-objects.c unpack_one
      def parse_type_and_size
        hdr      = byte
        hdr_size = 1
        continue = (hdr & 0b10000000)
        type     = (hdr & 0b01110000) >> 4
        size     = (hdr & 0b00001111)
        size_len = 4
        while continue != 0
          hdr        = byte
          hdr_size  += 1
          continue   = (hdr & 0b10000000)
          size      += (hdr & 0b01111111) << size_len
          size_len  += 7
        end
        return [type, size, hdr_size]
      end

      # delta.h get_delta_hdr_size
      def parse_delta_size
        size     = 0
        size_len = 0
        begin
          hdr       = byte
          continue  = (hdr & 0b10000000)
          size     += (hdr & 0b01111111) << size_len
          size_len += 7
        end while continue != 0
        return size
      end

      # sha1_file.c get_delta_base
      # unpack-objects.c unpack_delta_entry
      def parse_delta_offset
        offset   = -1
        hdr_size = 0
        begin
          hdr        = byte
          hdr_size  += 1
          continue   = hdr & 0b10000000
          low_offset = hdr & 0b01111111
          offset     = ((offset + 1) << 7) | low_offset
        end while continue != 0
        return [offset, hdr_size]
      end

      # patch-delta.c
      def parse_base_offset_and_size(cmd)
        offset = size = 0
        offset  = byte       if cmd & 0b00000001 != 0
        offset |= byte << 8  if cmd & 0b00000010 != 0
        offset |= byte << 16 if cmd & 0b00000100 != 0
        offset |= byte << 24 if cmd & 0b00001000 != 0
        size    = byte       if cmd & 0b00010000 != 0
        size   |= byte << 8  if cmd & 0b00100000 != 0
        size   |= byte << 16 if cmd & 0b01000000 != 0
        size = 0x10000 if size == 0
        return [offset, size]
      end

    end
  end
end
