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
          (@diff_dir, @step) = find_next_dir if @step == :next
          @json_dir = File.join(@outdir, 'json', @step)
        else
          @json_dir = File.join(@outdir, 'json')
        end
      end

      def find_next_dir
        json_dir = File.join(@outdir, 'json')
        FileUtils.mkdir_p(json_dir) unless File.exist?(json_dir)
        dir = Dir.open(json_dir).map do |dir|
          if dir =~ /\Astep(\d+)\z/
            [dir, $1.to_i]
          else
            nil
          end
        end.compact.sort {|a,b| a[1] <=> b[1] }.last
        if dir
          return [File.join(json_dir, dir[0]), "step#{dir[1] + 1}"]
        else
          return [nil, "step1"]
        end
      end
      private :find_next_dir

      def dump
        dump_objects
        copy_htdocs
        create_diff_data
        create_note
        if @step
          puts "-- Complete: #{ @step }"
        end
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
        if File.exist?(@json_dir)
          puts "Remove old data: #{ @step }"
          FileUtils.rm_r(@json_dir)
        end
        FileUtils.mkdir_p(@json_dir)
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
            next if file == 'config.js'
            puts "Copy: #{file}"
            FileUtils.copy_entry(file, File.join(@outdir, file))
          end
          unless File.exist?(File.join(@outdir, 'config.js'))
            FileUtils.copy_entry('config.js', File.join(@outdir, 'config.js'))
          end
        end
      end

      def create_note
        if @step
          FileUtils.mkdir_p(File.join(@outdir, 'notes'))
          path = File.join(@outdir, 'notes', "#{ @step }.html")
          msg = "Create: notes/#{ @step }.html"
        else
          path = File.join(@outdir, 'note.html')
          msg = "Create: note.html"
        end
        unless File.exist?(path)
          puts "-- Create note"
          puts msg
          File.open(path, 'w') {}
        end
      end
    end
  end
end
