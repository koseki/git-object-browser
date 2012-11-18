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

        if false
        store = Zlib::Inflate.new
        buffer = ""
        while buffer.size < @size
          rawdata = raw(4096)
          if rawdata.size == 0
            # XXX
          end
          buffer << store.inflate(rawdata)
        end
        store.close
        end
      end

      def parse_header(offset)
        seek(offset)
        raw_header = byte
        continue = (raw_header & 0b10000000)
        type     = (raw_header & 0b01110000) >> 4
        size     = (raw_header & 0b00001111)
        size_len = 4
        while continue != 0
          raw_header = byte
          continue   = (raw_header & 0b10000000)
          size      += (raw_header & 0b01111111) << size_len
          size_len  += 7
        end

        type = TYPES[type]
        header = { :type => type, :size => size }
        header[:delta_offset] = parse_delta_offset(offset) if type == 'OBJ_OFS_DELTA'

        return header
      end

      def parse_delta_offset(offset)
        raw_header = byte
        continue = raw_header & 0b10000000
        doffset  = raw_header & 0b01111111
        while continue != 0
          raw_header = byte
          continue   = raw_header & 0b10000000
          low_offset = raw_header & 0b01111111
          doffset = ((doffset + 1) << 7) | low_offset
        end
        return offset - doffset
      end
      private :parse_delta_offset

      def to_hash
        return {
          :type => @type,
          :size => @size,
        }
      end

      def self.path?(relpath)
        return relpath =~ %r{\Aobjects/pack/pack-[0-9a-f]{40}.pack\z}
      end
    end
  end
end
