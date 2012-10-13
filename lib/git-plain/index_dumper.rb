# -*- coding: utf-8 -*-

module GitPlain

  class IndexDumper < BinFile

    def initialize(input, output)
      @in = input
      @out = output
    end

    def dump
      dirc = raw(4)
      if dirc != "DIRC"
        throw Exception.new("Illegal format.")
      end

      @out << "----------------------------------------------------------------\n"
      @out << "header\n"
      @out << "----------------------------------------------------------------\n"

      (@version, @entries) = dump_header

      @out << "\n"

      @entries.times do |i|
        @out << "----------------------------------------------------------------\n"
        @out << "entry: #{i+1}\n"
        @out << "----------------------------------------------------------------\n"
        dump_entry(i)
        @out << "\n"
      end

      while sig = read_extension_signature
        @out << "----------------------------------------------------------------\n"
        @out << "extension: #{sig}\n"
        @out << "----------------------------------------------------------------\n"
        self.send("dump_extension_#{sig.downcase}")
        # skip_extension
        # @out << "(skip)\n"
        @out << "\n"
      end

      @out << "----------------------------------------------------------------\n"
      @out << "checksum\n"
      @out << "----------------------------------------------------------------\n"
      sha1 = hex(20)
      @out << "sha1: #{sha1}\n"
    end

    def dump_header
      version = int
      entries = int

      @out << "version: #{version}\n"
      @out << "entries: #{entries}\n"

      return [version, entries]
    end

    def dump_entry(index)
      ctime = int
      cnano = int
      mtime = int
      mnano = int
      dev   = int
      ino   = int

      mode = binstr(4)
      object_type     = mode[16..19]
      unused          = mode[20..22]
      unix_permission = mode[23..31]

      uid   = int
      gid   = int
      size  = int

      sha1 = hex(20) 

      # --- 60 bytes

      flags = binstr(2)

      if @version == 2
        assume_valid_flag = flags[0..0]
        extended_flag     = flags[1..1]
        stage             = flags[2..3]
      elsif @version == 3
        reserved          = flags[0..0]
        skip_worktree     = flags[1..1]
        intent_to_add     = flags[2..2]
      end

      name_length = ["0000" + flags[4..15]].pack("B*").unpack("n")[0]

      path = ""

      token = raw(2)

      # --- 64 bytes

      begin
        path += token.unpack("Z*").first
        break if token.unpack("C*").last == 0
      end while(token = raw(8))

      @out << "            ctime: #{ctime}\n"
      @out << "       ctime nano: #{cnano}\n"
      @out << "            mtime: #{mtime}\n"
      @out << "       mtime nano: #{mnano}\n"
      @out << "              dev: #{dev}\n"
      @out << "              ino: #{ino}\n"
      @out << "      object_type: #{object_type}\n"
      @out << "  unix_permission: #{unix_permission}\n"
      @out << "              uid: #{uid}\n"
      @out << "              gid: #{gid}\n"
      @out << "             size: #{size}\n"
      @out << "             sha1: #{sha1}\n"
      if @version == 2
        @out << "assume_valid_flag: #{assume_valid_flag}\n"
        @out << "    extended_flag: #{extended_flag}\n"
        @out << "            stage: #{stage}\n"
      elsif @version == 3
        @out << "    skip_worktree: #{skip_worktree}\n"
        @out << "    intent_to_add: #{intent_to_add}\n"
      end
      @out << "      name_length: #{name_length}\n"
      @out << "             path: #{path}\n"
    end

    def read_extension_signature
      signature = raw(4)
      if signature == "TREE" || signature == "REUC"
        return signature
      end
      @in.seek(-4, IO::SEEK_CUR)
      return nil
    end

    def skip_extension
      length = int
      raw(length)
    end

    def dump_extension_tree
      total_length = int
      length = 0
      while (length < total_length)
        path_component = find_char "\0"
        entry_count = find_char " "
        subtree_count = find_char "\n"
        sha1 = hex(20)

        length += path_component.bytesize + 1
        length += entry_count.bytesize + 1
        length += subtree_count.bytesize + 1
        length += 20

        @out << "   path_component: #{path_component}\n"
        @out << "      entry_count: #{entry_count}\n"
        @out << "    subtree_count: #{subtree_count}\n"
        @out << "             sha1: #{sha1}\n\n"
        
      end
    end

    def dump_extension_reuc
      skip_extension
    end
  end

end
