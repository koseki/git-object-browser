# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class ObjectsDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump
        obj_files = []
        Dir.chdir(@root) do
          Dir.glob("objects/**/*") do |path|
            obj_files << path if File.file?(path) && path =~ %r{/[a-z0-9]{38}$}
          end
        end
        return if obj_files.empty?

        obj_files.each do |path|
          outfile = File.join(@outdir, "#{ path }.json")
          next if File.exist?(outfile)

          FileUtils.mkdir_p(File.dirname(outfile))

          puts "Write: #{path}\n"
          obj_file = File.join(@root, path)
          File.open(obj_file) do |input|
            File.open(outfile, "w") do |output|
              dump_object(input, output, path)
            end
          end
        end
      end

      def dump_object(input, output, path)
        obj =  GitObjectBrowser::Models::GitObject.new(input).parse
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, path, obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end
    end
  end
end
