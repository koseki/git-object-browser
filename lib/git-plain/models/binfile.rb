module GitPlain

  module Models

    class BinFile

      def initialize(input)
        @in = input
      end

      def raw(bytes)
        return @in.read(bytes)
      end

      def bytes(bytes)
        return @in.read(bytes).unpack("C*")
      end

      def byte
        return bytes(1).first
      end

      def int
        return @in.read(4).unpack("N").first.to_i
      end

      def hex(bytes)
        return @in.read(bytes).unpack("H*").first
      end

      def binstr(bytes)
        return @in.read(bytes).unpack("B*").first
      end

      def find_char(char)
        buf = ""
        loop do
          c = @in.read(1)
          return buf if c.nil? || c == char
          buf += c
        end
      end

      def skip(bytes)
        @in.seek(bytes, IO::SEEK_CUR)
      end

      def peek(bytes)
        result = raw(bytes)
        @in.seek(bytes * -1, IO::SEEK_CUR)
        return result
      end

    end
  end
end
