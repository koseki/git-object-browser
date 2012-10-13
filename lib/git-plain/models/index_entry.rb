module GitPlain

  module Models

    class IndexEntry < BinFile

      attr_reader :version, :ctime, :cnano, :mtime, :mnano, :dev, :ino
      attr_reader :object_type, :unix_permission
      attr_reader :uid, :gid, :size, :sha1, :path
      attr_reader :assume_valid_flag, :extended_flag, :stage
      attr_reader :skip_worktree, :intent_to_add
      attr_reader :name_length

      def initialize(input, version)
        super(input)
        @version = version
        parse
      end

      def parse
        @ctime = int
        @cnano = int
        @mtime = int
        @mnano = int # 16 byte
        @dev   = int
        @ino   = int

        mode   = binstr(4)
        @object_type     = mode[16..19]
        unused           = mode[20..22]
        @unix_permission = mode[23..31]

        @uid   = int # 32 bytes
        @gid   = int
        @size  = int
        @sha1  = hex(20)
        parse_flags # 62 bytes
        @path  = parse_path
      end

      def parse_flags
        flags  = binstr(2)
        if @version == 2
          @assume_valid_flag = flags[0..0]
          @extended_flag     = flags[1..1]
          @stage             = flags[2..3]
        elsif @version == 3
          reserved           = flags[0..0]
          @skip_worktree     = flags[1..1]
          @intent_to_add     = flags[2..2]
        end
        @name_length = ["0000" + flags[4..15]].pack("B*").unpack("n")[0]
      end

      # path: 2 + 8 * n bytes (nul pannding)
      def parse_path
        token = raw(2) # 64 bytes
        path = ""
        begin
          path += token.unpack("Z*").first
          break if token.unpack("C*").last == 0
        end while(token = raw(8))
        return path
      end

    end
  end
end
