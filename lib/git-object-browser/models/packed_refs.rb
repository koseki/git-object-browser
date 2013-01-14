
module GitObjectBrowser

  module Models

    class PackedRefs
      def initialize(input)
        @entries = []
        while (line = input.gets) do
          next if line =~ /\A\s*#/
          next unless line =~ /(\^)?([0-9a-f]{40})\s*(.*)/
          sha1 = $2
          ref  = $3
          if $1
            entry = @entries.last
            entry[:tag_sha1] = sha1 if entry
          else
            entry = {}
            entry[:sha1] = sha1
            entry[:ref]  = ref
            @entries << entry
          end
        end
      end

      def to_hash
        return {
          :entries => @entries
        }
      end

      def self.path?(relpath)
        return relpath == "packed-refs"
      end

    end

  end
end
