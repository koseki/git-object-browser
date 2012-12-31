module GitObjectBrowser

  module Models

    class Bindata

      def initialize(input)
        @in = input
      end

      def switch_source(input)
        tmp = @in
        @in = input
        yield
      ensure
        @in = tmp
      end

      def raw(bytes)
        @in.read(bytes)
      end

      def bytes(bytes)
        @in.read(bytes).unpack("C*")
      end

      def byte
        bytes(1).first
      end

      def int
        @in.read(4).unpack("N").first.to_i
      end

      def hex(bytes)
        @in.read(bytes).unpack("H*").first
      end

      def binstr(bytes)
        @in.read(bytes).unpack("B*").first
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

      def seek(bytes)
        @in.seek(bytes)
      end

      def peek(bytes)
        result = raw(bytes)
        @in.seek(bytes * -1, IO::SEEK_CUR)
        result
      end

    end
  end
end
