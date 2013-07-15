# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class RefsDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump
        ref_files = []
        Dir.chdir(@root) do
          Dir.glob("refs/**/*") do |path|
            ref_files << path if File.file?(path)
          end
        end
        return if ref_files.empty?

        ref_files.each do |path|
          outfile = File.join(@outdir, "#{ path }.json")
          FileUtils.mkdir_p(File.dirname(outfile))

          puts "Write: #{path}\n"
          ref_file = File.join(@root, path)
          File.open(ref_file) do |input|
            File.open(outfile, "w") do |output|
              dump_object(input, output, path)
            end
          end
        end
      end

      def dump_object(input, output, path)
        obj =  GitObjectBrowser::Models::Ref.new(input)
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, path, obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end
    end
  end
end

