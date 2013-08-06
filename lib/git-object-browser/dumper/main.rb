module GitObjectBrowser
  module Dumper

    HTDOCS_DIR = File.join(File.dirname(__FILE__), '../../../htdocs')

    class Main

      def self.execute(target, outdir, step, diff_dir)
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

        if diff_dir
          diff_dir = File.expand_path(diff_dir)
          raise "#{ diff_dir } must be directory." unless File.directory?(diff_dir)
          raise "#{ diff_dir }/_git.json doesn't exist" unless File.exist?(File.join(diff_dir, '_git.json'))
        end

        new(target, outdir, step, diff_dir).dump
      end

      def initialize(target, outdir, step, diff_dir)
        @target = target
        @outdir = outdir
        @step = step
        @diff_dir = diff_dir

        if @step
          @json_dir = File.join(@outdir, 'json', @step)
        else
          @json_dir = File.join(@outdir, 'json')
        end
      end

      def dump
        dump_objects
        copy_htdocs
        create_diff_data
      end

      def create_diff_data
        return unless @diff_dir
        old_files = []
        Dir.chdir(@diff_dir) do
          Dir.glob("**/*").each do |file|
            next unless File.file?(file)
            next if File.directory?(file.sub(/\.json\z/, ''))
            next if %w{_git.json _diff.json}.include?(file)
            old_files << file
          end
        end

        new_files = []
        Dir.chdir(@json_dir) do
          Dir.glob("**/*").each do |file|
            next unless File.file?(file)
            next if File.directory?(file.sub(/\.json\z/, ''))
            next if %w{_git.json _diff.json}.include?(file)
            new_files << file
          end
        end

        diff_files = []

        common_files = old_files & new_files
        common_files.each do |file|
          a = File.join(@diff_dir, file)
          b = File.join(@json_dir, file)
          unless FileUtils.cmp(a, b)
            diff_files << file.sub(/\.json\z/, '')
          end
        end

        removed_files = old_files - new_files
        removed_files.each do |file|
          diff_files << file.sub(/\.json\z/, '')
        end

        added_files = new_files - old_files
        added_files.each do |file|
          diff_files << file.sub(/\.json\z/, '')
        end

        File.open(File.join(@json_dir, '_diff.json'), 'w') do |io|
          io << JSON.pretty_generate(diff_files)
        end
      end

      def dump_objects
        FileUtils.mkdir_p(@json_dir) unless File.exist?(@json_dir)
        [IndexDumper,
         ObjectsDumper,
         RefsDumper,
         DirectoriesDumper,
         PlainFilesDumper,
         PackIndexesDumper,
         PackedRefsDumper,
         InfoRefsDumper,
        ].each do |dumper|
          dumper.new(@target, @json_dir).dump
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
