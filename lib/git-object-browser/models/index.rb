module GitObjectBrowser

  module Models

    # Parse .git/index file
    class Index < Bindata

      attr_reader :version, :entry_count, :entries, :extensions, :sha1

      def initialize(input)
        super(input)
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

        self
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
            extensions << IndexTreeExtension.new(@in).parse
          elsif  signature == "REUC"
            extensions << IndexReucExtension.new(@in).parse
          else
            break
          end
        end
        return extensions
      end

      def to_hash
        entries = []
        @entries.each do |entry|
          entries << entry.to_hash
        end

        extensions = []
        @extensions.each do |extension|
          extensions << extension.to_hash
        end

        return {
          :version       => @version,
          :entry_count   => @entry_count,
          :entries       => entries,
          :extensions    => extensions,
          :sha1          => @sha1,
        }
      end

      def self.path?(relpath)
        relpath == "index"
      end

    end
  end
end
