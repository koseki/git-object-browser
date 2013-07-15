# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class PlainFilesDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump
        obj_files = []

        # ! info/refs
        # info
        # logs
        # objects/info

        plain_files = []
        subdirs = []

        Dir.chdir(@root) do
          Dir.glob('*') do |path|
            next if %w{HEAD FETCH_HEAD ORIG_HEAD MERGE_HEAD CHERRY_PICK_HEAD}.include?(path)
            next if %w{dump index objects refs packed-refs}.include?(path)

            full_path = File.join(@root, path)
            if File.directory?(full_path)
              subdirs << path
            else
              plain_files << path
            end
          end
        end
        subdirs << 'objects/info'

        subdirs.each do |dir|
          next unless File.directory?(File.join(@root, dir))
          Dir.chdir(File.join(@root, dir)) do
            Dir.glob('**/*') do |path|
              # skip info/refs (InfoRefs)
              next if dir == 'info' && path == 'refs'
              if File.file?(File.join(@root, dir, path))
                plain_files << File.join(dir, path)
              end
            end
          end
        end

        plain_files.each do |path|
          outfile = File.join(@outdir, "#{ path }.json")
          FileUtils.mkdir_p(File.dirname(outfile))

          puts "Write: #{path}\n"
          file = File.join(@root, path)
          File.open(file) do |input|
            File.open(outfile, "w") do |output|
              dump_object(input, output, path)
            end
          end
        end
      end

      def dump_object(input, output, path)
        obj =  GitObjectBrowser::Models::PlainFile.new(input).parse
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, path, obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end
    end
  end
end

