# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class DirectoriesDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump
        dirs = ['']
        Dir.chdir(@root) do
          Dir.glob("**/*") do |path|
            next if path == 'dump' # FIXME
            dirs << path if File.directory?(path)
          end
        end

        dirs.each do |path|
          outfile = File.join(@outdir, (path == '') ? '_git.json' : "#{ path }.json")
          FileUtils.mkdir_p(File.dirname(outfile))

          puts "Write: #{path}\n"
          obj_file = File.join(@root, path)
          File.open(outfile, "w") do |output|
            dump_object(path, output)
          end
        end
      end

      def dump_object(path, output)
        obj =  GitObjectBrowser::Models::Directory.new(@root, path)
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, path, obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end
    end
  end
end
