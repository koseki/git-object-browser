module GitPlain
  class ObjectDumper < BinFile

    def initialize(input, output)
      @in = input
      @out = output
    end

    def dump
      store = Zlib::Inflate.inflate(@in.read)
      sha1 = Digest::SHA1.hexdigest(store)
      @in = StringIO.new(store)

      type = space_terminated_str
      size = null_terminated_str

      @out << "type: #{type}\n"
      @out << "size: #{size}\n"
      @out << "sha1: #{sha1}\n"
      @out << "\n"
      if type == "tree"
        1 while dump_tree_entry
        # @out << @in.read
      else 
        @out << @in.read
      end
    end

    # man git-ls-tree
    def dump_tree_entry
      mode = space_terminated_str
      return false if mode.empty?

      mode = " " + mode if mode.length < 6

      filename = null_terminated_str
      sha1 = hex(20)

      @out << "#{mode} #{sha1} #{filename}\n"

      return true
    end
  end
end
