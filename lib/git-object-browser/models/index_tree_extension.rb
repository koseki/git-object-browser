module GitObjectBrowser

  module Models

    class IndexTreeExtension < Bindata

      attr_reader :signature, :total_length, :entries

      def initialize(input)
        super(input)
      end

      def parse
        @signature = raw(4) # TREE
        @total_length = int
        @entries = []

        length = 0
        while (length < @total_length)
          entry = {}
          entry['path_component'] = find_char "\0"
          entry['entry_count']    = find_char " "
          entry['subtree_count']  = find_char "\n"

          length += entry['path_component'].bytesize + 1
          length += entry['entry_count'].bytesize + 1
          length += entry['subtree_count'].bytesize + 1

          entry['entry_count']    = entry['entry_count'].to_i
          entry['subtree_count']  = entry['subtree_count'].to_i

          if length < @total_length
            entry['sha1']           = hex(20)
            length += 20
          end
          @entries << entry
        end

        self
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
