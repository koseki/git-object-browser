module GitObjectBrowser

  class Dumper

    def initialize(target)
      @target = target
      @outdir = File.join(@target, "plain")
    end

    def dump
      Dir.mkdir(@outdir) unless File.exist?(@outdir)
      dump_index
      dump_objects
    end

    def dump_index
      index_file = File.join(@target, "index")
      out_file   = File.join(@outdir, "index")

      return unless File.exist?(index_file)

      STDERR << "Write: .git/plain/index\n"
      File.open(index_file) do |input|
        File.open(out_file, "w") do |output|
          dumper = GitObjectBrowser::IndexDumper.new(input, output)
          dumper.dump
        end
      end
    end

    def dump_objects
      obj_files = []
      Dir.chdir(@target) do
        Dir.glob("objects/**/*") do |path|
          obj_files << path if File.file?(path) && path =~ %r{/[a-z0-9]{38}$}
        end
      end
      return if obj_files.empty?

      obj_dir = File.join(@outdir, "objects")
      Dir.mkdir(obj_dir) unless File.exist?(obj_dir)

      obj_files.each do |path|
        outfile = File.join(@outdir, path)
        next if File.exist?(outfile)

        parent = File.dirname(outfile)
        Dir.mkdir(parent) unless File.exist?(parent)

        STDERR << "Write: .git/plain/#{path}\n"
        obj_file = File.join(@target, path)
        File.open(obj_file) do |input|
          File.open(outfile, "w") do |output|
            dumper = GitObjectBrowser::ObjectDumper.new(input, output)
            dumper.dump
          end
        end
      end

    end
  end
end
