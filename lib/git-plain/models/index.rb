module GitPlain

  module Models

    # Parse .git/index file
    class Index < BinFile

      attr_reader :version, :entry_count, :entries, :extensions, :sha1

      def initialize(input)
        super(input)
        parse
      end

      def parse
        dirc = raw(4)
        if dirc != "DIRC"
          throw Exception.new("Illegal format.")
        end

        @version     = int
        @entry_count = int
        @entries     = parse_entries
        @extensions  = parse_extensions
        @sha1        = hex(20)
      end

      def parse_entries
        entries = []
        @entry_count.times do |i|
          entries << IndexEntry.new(@in, @version)
        end
        return entries
      end

      def parse_extensions
        extensions = []
        while signature = peek(4)
          if signature == "TREE"
            extensions << IndexTreeExtension.new(@in)
          elsif  signature == "REUC"
            extensions << IndexReucExtension.new(@in)
          else
            break
          end
        end
        return extensions
      end

    end
  end
end
