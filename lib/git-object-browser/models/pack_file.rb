# -*- coding: utf-8 -*-


module GitObjectBrowser

  module Models

    #   signature          4bytes PACK
    #   version            4bytes
    #   objects number     4bytes
    #   object entries     -> packed_object.rb
    #
    # https://github.com/git/git/blob/master/Documentation/technical/pack-format.txt
    class PackFile < Bindata
      def initialize(input)
        super(input)
      end

      def self.path?(relpath)
        return relpath =~ %r{\Aobjects/pack/pack-[0-9a-f]{40}\.pack\z}
      end

      def parse
        signature = raw(4)
        raise 'wrong signature' if signature != 'PACK'
        @version       = int
        @object_number = int
        self
      end

      def to_hash
        return {
          :version => @version,
          :object_number => @object_number
        }
      end

    end
  end
end
