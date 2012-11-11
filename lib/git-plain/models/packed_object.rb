# -*- coding: utf-8 -*-
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

      def initialize(input, offset)
        super(input)
        @offset = offset
        parse
      end

      def parse
        skip(@offset)
        header   = byte
        continue = header >> 7
        type     = (header & 0b01110000) >> 4
        @size    = (header & 0b00001111)
        @type    = TYPES[type]
        size_len = 4
        while continue == 1
          header    = byte
          continue  = header >> 7
          @size    += (header & 0b01111111) << size_len
          size_len += 7
        end
      end

      def to_hash
        return {
          :size => @size,
          :type => @type,
        }
      end

      def self.path?(relpath)
        return relpath =~ %r{\Aobjects/pack/pack-[0-9a-f]{40}.pack\z}
      end
    end
  end
end
