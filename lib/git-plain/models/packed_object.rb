# -*- coding: utf-8 -*-

# https://github.com/git/git/blob/master/builtin/unpack-objects.c
# https://github.com/git/git/blob/master/patch-delta.c
# https://github.com/mojombo/grit/blob/master/lib/grit/git-ruby/internal/pack.rb
module GitPlain

  module Models

    class PackedObject < BinFile

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
        @offset = offset
        header = parse_header(offset)
        @type = header[:type]
        @size = header[:size]

        if @type == 'OBJ_OFS_DELTA'
          @delta_offset = header[:delta_offset]

          store = Zlib::Inflate.new
          buffer = ""
          while buffer.size < @size
            rawdata = raw(4096)
            if rawdata.size == 0
              raise "inflate error"
            end
            buffer << store.inflate(rawdata)
          end
          store.close

          tmp = @in
          @in = StringIO.new(buffer)
          @base_size  = parse_delta_size
          @delta_size = parse_delta_size
          @delta_commands = []
          while ! @in.eof?
            cmd = byte
            if cmd & 0b10000000 != 0
              (offset, size) = parse_base_offset_and_size(cmd)
              @delta_commands << { :source => :base, :offset => offset, :size => size }
            elsif cmd != 0
              begin
                data = raw(cmd).encode('UTF-8')
              rescue Exception
                data = "(not UTF-8)"
              end
              @delta_commands << { :source => :delta, :size => cmd, :data => data }
            else
              raise "delta command = 0"
            end
          end
          @in = tmp

          File.open("/tmp/git-plain-buffer", "w") do |io|
            io << buffer
          end
        end

        self
      end

      def parse_header(offset)
        seek(offset)

        (type, size) = parse_type_and_size
        type = TYPES[type]
        header = { :type => type, :size => size }
        header[:delta_offset] = offset - parse_delta_offset if type == 'OBJ_OFS_DELTA'

        return header
      end

      def parse_type_and_size
        hdr      = byte
        continue = (hdr & 0b10000000)
        type     = (hdr & 0b01110000) >> 4
        size     = (hdr & 0b00001111)
        size_len = 4
        while continue != 0
          hdr        = byte
          continue   = (hdr & 0b10000000)
          size      += (hdr & 0b01111111) << size_len
          size_len  += 7
        end
        return [type, size]
      end
      private :parse_type_and_size

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
      private :parse_delta_size

      # unpack-objects.c unpack_delta_entry
      def parse_delta_offset
        offset = -1
        begin
          hdr        = byte
          continue   = hdr & 0b10000000
          low_offset = hdr & 0b01111111
          offset = ((offset + 1) << 7) | low_offset
        end while continue != 0
        return offset
      end
      private :parse_delta_offset

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
        return [offset,size]
      end
      private :parse_base_offset_and_size

      def to_hash
        return {
          :type => @type,
          :size => @size,
          :delta_offset => @delta_offset,
          :base_size => @base_size,
          :delta_size => @delta_size,
          :delta_commands => @delta_commands,
        }
      end

      def self.path?(relpath)
        return relpath =~ %r{\Aobjects/pack/pack-[0-9a-f]{40}.pack\z}
      end
    end
  end
end
