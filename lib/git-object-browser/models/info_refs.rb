
module GitObjectBrowser

  module Models

    class InfoRefs
      def initialize(input)
        @entries = []
        while (line = input.gets) do
          next if line =~ /\A\s*#/
          next unless line =~ /([0-9a-f]{40})\s*(.*)/
          entry = {}
          entry[:sha1] = $1
          entry[:ref]  = $2
          @entries << entry
        end
      end

      def to_hash
        return {
          :entries => @entries
        }
      end

      def self.path?(relpath)
        return relpath == "info/refs"
      end

    end

  end
end
