module GitObjectBrowser

  module Models

    class IndexReucExtension < Bindata

      attr_reader :signature, :total_length

      def initialize(input)
        super(input)
      end

      def parse
        @signature = raw(4) # REUC
        @total_length = int

        data = raw(@total_length) # TODO

        self
      end

      def to_hash
        return {
          "signature" => @signature,
          "total_length" => @total_length,
        }
      end

    end
  end
end
