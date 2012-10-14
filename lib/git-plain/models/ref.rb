
module GitPlain

  module Models

    class Ref
      def initialize(input)
        line = input.gets.to_s

        if line =~ %r{\Aref:\s*(.+)}
          @ref = $1
        elsif line =~ %r{\A([0-9a-f]{40})}
          @sha1 = $1
        end
      end

      def to_hash
        return {
          "ref"  => @ref,
          "sha1" => @sha1
        }
      end

    end

  end
end
