
module GitObjectBrowser

  module Models

    class Ref
      def initialize(input)
        @content = input.read(nil)

        if @content =~ %r{\Aref:\s*(.+)}
          @ref = $1
        elsif @content =~ %r{\A([0-9a-f]{40})}
          @sha1 = $1
        end
      end

      def to_hash
        return {
          :ref     => @ref,
          :sha1    => @sha1,
          :content => @content
        }
      end

      def self.path?(relpath)
        ref_names = %w{HEAD FETCH_HEAD ORIG_HEAD MERGE_HEAD CHERRY_PICK_HEAD}
        return (ref_names.include?(relpath) || relpath =~ %r{\Arefs/})
      end

    end

  end
end
