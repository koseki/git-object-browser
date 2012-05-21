
module GitPlain
  class BinFile
    def raw(bytes)
      return @in.read(bytes)
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

    def null_terminated_str
      buf = ""
      loop do
        c = @in.read(1)
        return buf if c.nil? || c == "\0"
        buf += c
      end
    end

    def space_terminated_str
      buf = ""
      loop do
        c = @in.read(1)
        return buf if c.nil? || c == " "
        buf += c
      end
    end
  end
end
