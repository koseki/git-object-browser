module GitObjectBrowser

  module Models

    class IndexTreeExtension < Bindata

      attr_reader :signature, :total_length, :entries

      def initialize(input)
        super(input)
        parse
      end

      def parse
        @signature = raw(4) # TREE
        @total_length = int
        @entries = []

        length = 0
        while (length < @total_length)
          entry = {}
          entry[:path_component] = find_char "\0"
          entry[:entry_count]    = find_char " "
          entry[:subtree_count]  = find_char "\n"
          entry[:sha1]           = hex(20)
          @entries << entry

          length += entry[:path_component].bytesize + 1
          length += entry[:entry_count].bytesize + 1
          length += entry[:subtree_count].bytesize + 1
          length += 20
        end
      end

      def to_hash
        return {
          "signature" => @signature,
          "total_length" => @total_length,
          "entries" => @entries
        }
      end

    end
  end
end
