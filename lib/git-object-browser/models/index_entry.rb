module GitObjectBrowser

  module Models

    class IndexEntry < Bindata

      attr_reader :version, :ctime, :cnano, :mtime, :mnano, :dev, :ino
      attr_reader :object_type, :unix_permission
      attr_reader :uid, :gid, :size, :sha1, :path
      attr_reader :assume_valid_flag, :extended_flag, :stage
      attr_reader :skip_worktree, :intent_to_add
      attr_reader :name_length

      def initialize(input, version, last_path = nil)
        super(input)
        @version = version
        @last_path = last_path
        parse
      end

      def parse
        @ctime = int       # 4
        @cnano = int       # 8
        @mtime = int       # 12
        @mnano = int       # 16
        @dev   = int       # 20
        @ino   = int       # 24
        parse_mode         # 28
        @uid   = int       # 32
        @gid   = int       # 36
        @size  = int       # 40
        @sha1  = hex(20)   # 60
        parse_flags        # 62
        parse_path
      end

      def parse_mode
        mode = binstr(4)
        @object_type     = mode[16..19]
        unused           = mode[20..22]
        @unix_permission = sprintf('%o', mode[23..31].to_i(2))
      end
      private :parse_mode

      def parse_flags
        flags  = binstr(2)
        @assume_valid_flag = flags[0..0].to_i
        @extended_flag     = flags[1..1].to_i
        @stage             = flags[2..3]
        @name_length = ["0000" + flags[4..15]].pack("B*").unpack("n")[0]
        if @version == 3 && @extended_flag == 1
          exended          = binstr(2)
          reserved         = extended[0..0]
          @skip_worktree   = extended[1..1]
          @intent_to_add   = extended[2..2]
        end
      end
      private :parse_flags

      def parse_path
        if @version == 2 || @version == 3
          parse_path_v2
        elsif @version == 4
          parse_path_v4
        end
      end
      private :parse_path

      # path: 2 + 8 * n bytes (nul pannding)
      def parse_path_v2
        token = raw(2) # 64 bytes
        @path = ""
        begin
          @path += token.unpack("Z*").first
          break if token.unpack("C*").last == 0
        end while(token = raw(8))
      end
      private :parse_path_v2

      def parse_path_v4
        (chop_size, _) = parse_chop_size()
        @path = find_char("\0")
        if chop_size > 0
          @path = @last_path[0 .. chop_size * -1 - 1] + @path
        end
      end
      private :parse_path_v4

      def parse_chop_size
        value      = -1
        value_size = 0
        begin
          b          = byte
          value_size += 1
          continue   = b & 0b10000000
          low_value  = b & 0b01111111
          value      = ((value + 1) << 7) | low_value
        end while continue != 0
        return [value, value_size]
      end
      private :parse_chop_size

      def to_hash
        return {
          :ctime  => @ctime,
          :cnano  => @cnano,
          :mtime  => @mtime,
          :mnano  => @mnano,
          :dev    => @dev,
          :ino    => @ino,
          :object_type        => @object_type,
          :unix_permission    => @unix_permission,

          :uid    => @uid,
          :gid    => @gid,
          :size   => @size,
          :sha1   => @sha1,
          :path   => @path,

          :assume_valid_flag  => @assume_valid_flag,
          :extended_flag      => @extended_flag,
          :stage              => @stage,
          :skip_worktree      => @skip_worktree,
          :intent_to_add      => @intent_to_add,
          :name_length        => @name_length,
        }
      end

    end
  end
end
