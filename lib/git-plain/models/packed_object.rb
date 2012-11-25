# -*- coding: utf-8 -*-

# https://github.com/git/git/blob/master/builtin/unpack-objects.c
# https://github.com/git/git/blob/master/patch-delta.c
# https://github.com/mojombo/grit/blob/master/lib/grit/git-ruby/internal/pack.rb
module GitPlain

  module Models

    class PackedObject < BinFile

      attr_reader :header, :raw_data
      attr_reader :object, :object_type, :object_size

      TYPES = %w{
        undefined
        OBJ_COMMIT
        OBJ_TREE
        OBJ_BLOB
        OBJ_TAG
        undefined
        OBJ_OFS_DELTA
        OBJ_REF_DELTA
      }

      def initialize(input)
        super(input)
      end

      def parse(offset)
        parse_raw(offset)
        p @raw_data

        input = StringIO.new(@raw_data)
        type = @object_type.sub(/\AOBJ_/, '').downcase
        @object = GitObject.new(input).parse_inflated(type, @object_size)

        self
      end

      def parse_raw(offset)
        @offset = offset
        @header = parse_header(offset)

        if @header[:type] == 'OBJ_OFS_DELTA'
          obj_ofs_delta
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
        header = { :type => type, :size => size, :header_size => header_size }

        if type == 'OBJ_OFS_DELTA'
          (delta_offset, delta_header_size) = parse_delta_offset
          header[:delta_offset] = offset - delta_offset
          header[:header_size] += delta_header_size
        end

        return header
      end

      def to_hash
        return {
          :type => @header[:type],
          :size => @header[:size],
          :object_type => @object_type,
          :object_size => @object_size,
          :header_size => @header[:header_size],
          :delta_offset => @header[:delta_offset],
          :base_size => @base_size,
          :delta_size => @delta_size,
          :delta_commands => @delta_commands,
          :object => @object.to_hash,
        }
      end

      def self.path?(relpath)
        return relpath =~ %r{\Aobjects/pack/pack-[0-9a-f]{40}.pack\z}
      end


      private

      def obj_ofs_delta
        begin
          pack = PackedObject.new(@in)
          pack.parse_raw(@header[:delta_offset])
          @object_type = pack.object_type
          @base = pack.raw_data
        ensure
          seek(@offset + @header[:header_size])
        end

        buffer = zlib_inflate

        tmp = @in
        begin
          @in = StringIO.new(buffer)
          patch_delta
        ensure
          @in = tmp
        end
      end

      def patch_delta
        @base_size  = parse_delta_size
        if @base.size != @base_size
          raise 'incollect base size'
        end

        @delta_size = parse_delta_size
        @object_size = @delta_size
        @delta_commands = []
        @raw_data = ''
        while ! @in.eof?
          delta_command
        end
      end

      def delta_command
        cmd = byte
        if cmd & 0b10000000 != 0
          (offset, size) = parse_base_offset_and_size(cmd)
          @delta_commands << { :source => :base, :offset => offset, :size => size }
          @raw_data << @base[offset, size]
        elsif cmd != 0
          size = cmd
          data = raw(size)
          @raw_data << data
          begin
            cmd_data = data.encode('UTF-8')
          rescue Exception
            cmd_data = '(not UTF-8)'
          end
          @delta_commands << { :source => :delta, :size => size, :data => cmd_data }
        else
          raise 'delta command is 0'
        end
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
