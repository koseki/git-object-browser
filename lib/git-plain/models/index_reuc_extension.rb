module GitPlain

  module Models

    class IndexReucExtension < BinFile

      attr_reader :signature, :total_length

      def initialize(input)
        super(input)
        parse
      end

      def parse
        @signature = raw(4) # REUC
        @total_length = int

        raw(@total_length) # TODO 
      end

    end
  end
end
