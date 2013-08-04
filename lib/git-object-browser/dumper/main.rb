module GitObjectBrowser
  module Dumper

    HTDOCS_DIR = File.join(File.dirname(__FILE__), '../../../htdocs')

    class Main

      def self.execute(target, outdir, step)
        outdir = File.expand_path(outdir)

        if outdir =~ %r{(?:^|/).git(?:/|$)} && outdir !~ %r{/.git/dump/?\z}
          raise 'Dump directory must be .git/dump if you dump into the .git directory.'
        end

        if File.exist?(outdir)
          Dir.chdir(outdir) do
            if !Dir.glob('*').empty? &&  Dir.glob('json/**/_git.json').empty?
              raise 'dump directory exists but it may not be the old dump directory. json/**/_git.json doesn\'t exist.'
            end
          end
        end

        new(target, outdir, step).dump
      end

      def initialize(target, outdir, step)
        @target = target
        @outdir = outdir
        @step = step
      end

      def dump
        dump_objects
        copy_htdocs
      end

      def dump_objects
        if @step
          json_dir = File.join(@outdir, 'json', @step)
        else
          json_dir = File.join(@outdir, 'json')
        end
        FileUtils.mkdir_p(json_dir) unless File.exist?(json_dir)
        [IndexDumper,
         ObjectsDumper,
         RefsDumper,
         DirectoriesDumper,
         PlainFilesDumper,
         PackIndexesDumper,
         PackedRefsDumper,
         InfoRefsDumper,
        ].each do |dumper|
          dumper.new(@target, json_dir).dump
        end
      end
      private :dump_objects

      def copy_htdocs
        puts "Copy htdocs/*"
        Dir.chdir(HTDOCS_DIR) do
          Dir.glob('*').each do |file|
            next if file == 'steps.js'
            puts "Copy: #{file}"
            FileUtils.copy_entry(file, File.join(@outdir, file))
          end
          unless File.exist?(File.join(@outdir, 'steps.js'))
            FileUtils.copy_entry('steps.js', File.join(@outdir, 'steps.js'))
          end
        end
      end
    end
  end
end
