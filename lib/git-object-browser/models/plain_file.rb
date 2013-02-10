
module GitObjectBrowser

  module Models

    class PlainFile
      def initialize(input)
        @in = input
      end

      def parse
        @content = @in.read(nil)
        @content = @content.force_encoding('UTF-8')
        @content = '(not UTF-8)' unless @content.valid_encoding?
        @content = @content[0, 3000] + "\n..." if @content.length > 3000
        self
      end

      def to_hash
        return { :content => @content }
      end
    end
  end
end
