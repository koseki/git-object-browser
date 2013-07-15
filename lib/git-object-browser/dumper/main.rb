module GitObjectBrowser
  module Dumper

    # TEMPLATES_DIR = File.join(File.dirname(__FILE__), '../../../templates/dumper')

    class Main

      def self.execute(target, outdir)
        outdir = File.expand_path(outdir)
        new(target, outdir).dump
      end

      def initialize(target, outdir)
        @target = target
        @outdir = outdir
      end

      def dump
        json_dir = File.join(@outdir, 'json')
        FileUtils.mkdir_p(json_dir) unless File.exist?(json_dir)
        [IndexDumper,
         ObjectsDumper,
         DirectoriesDumper,
        ].each do |dumper|
          dumper.new(@target, json_dir).dump
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
