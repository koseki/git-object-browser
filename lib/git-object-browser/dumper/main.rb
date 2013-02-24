module GitObjectBrowser
  module Dumper

    # TEMPLATES_DIR = File.join(File.dirname(__FILE__), '../../../templates/dumper')

    class Main

      def self.execute(target)
        new(target).dump
      end

      def initialize(target)
        @target = target
        @outdir = File.join(target, "dump")
      end

      def dump
        Dir.mkdir(@outdir) unless File.exist?(@outdir)
        dump_index
        dump_objects
        dump_packed
      end

      def dump_index
        index_file = File.join(@target, "index")
        out_file   = File.join(@outdir, "index")

        return unless File.exist?(index_file)

        STDERR << "Write: .git/dump/index\n"
        File.open(index_file) do |input|
          File.open(out_file, "w") do |output|
            dumper = GitObjectBrowser::Dumper::IndexDumper.new(input, output)
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

          STDERR << "Write: .git/dump/objects/#{path}\n"
          obj_file = File.join(@target, path)
          File.open(obj_file) do |input|
            File.open(outfile, "w") do |output|
              dumper = GitObjectBrowser::Dumper::ObjectDumper.new(input, output)
              dumper.dump
            end
          end
        end

      end

      def dump_packed
        files = []
        Dir.chdir(@target) do
          Dir.glob("objects/pack/*.idx") do |path|
            files << path
          end
        end
        return if files.empty?

        obj_dir = File.join(@outdir, "objects")
        Dir.mkdir(obj_dir) unless File.exist?(obj_dir)
        pack_dir = File.join(@outdir, "objects/pack")
        Dir.mkdir(pack_dir) unless File.exist?(pack_dir)

        files.each do |path|
          outfile = File.join(@outdir, path)
          packpath = path.gsub(/\.idx\z/, '.pack')

          STDERR << "Write: .git/dump/#{path}\n"
          index_file = File.join(@target, path)
          File.open(index_file) do |input|
            File.open(outfile, "w") do |output|
              dumper = GitObjectBrowser::Dumper::PackIndexDumper.new(input, output)
              dumper.dump
              index = dumper.pack_index
              entries = index.to_hash[:entries]

              File.open(File.join(@target, packpath)) do |pack_input|
                object_dumper = GitObjectBrowser::Dumper::PackedObjectDumper.new(pack_input, index)
                entries.each do |entry|
                  dump_packed_object(object_dumper, entry)
                end
              end
            end
          end
        end
      end

      def dump_packed_object(dumper, entry)
        sha1_1 = entry[:sha1][0..1]
        sha1_2 = entry[:sha1][2..-1]
        obj_dir = File.join(@outdir, "objects", sha1_1)
        Dir.mkdir(obj_dir) unless File.exist?(obj_dir)

        outfile = File.join(obj_dir,  sha1_2)
        STDERR << "Write: .git/dump/objects/#{sha1_1}/#{sha1_2}\n"

        File.open(outfile, "w") do |output|
          dumper.dump(output, entry[:offset])
        end
      end

    end
  end
end
