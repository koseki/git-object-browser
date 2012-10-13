module GitPlain

  module Models

    class GitObject < BinFile

      attr_reader :sha1, :type, :size, :entries, :contents

      def initialize(input)
        super(input)
        parse
      end

      def parse
        store = Zlib::Inflate.inflate(@in.read)
        @sha1 = Digest::SHA1.hexdigest(store)
        @in   = StringIO.new(store)

        @type = find_char " "
        @size = find_char "\0"

        if @type == "tree"
          @entries = parse_tree_entries
        else 
          @contents = @in.read
        end
      end

      def parse_tree_entries
        entries = []
        loop do
          entry = {}
          entry[:mode]     = find_char " "
          break if entry[:mode].empty?
          entry[:filename] = find_char "\0"
          entry[:sha1]     = hex(20)
          entries << entry
        end
        return entries
      end
    end
  end
end
