# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class ReflogDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump
        files = []
        Dir.chdir(@root) do
          Dir.glob("logs/**/*") do |path|
            files << path if File.file?(path)
          end
        end
        return if files.empty?

        files.each do |path|
          file = File.join(@root, path)
          next unless File.exist?(file)
          outfile = File.join(@outdir, "#{ path }.json")
          FileUtils.mkdir_p(File.dirname(outfile))

          puts "Write: #{path}\n"
          File.open(file) do |input|
            File.open(outfile, "w") do |output|
              dump_object(input, output, path)
            end
          end
        end
      end

      def dump_object(input, output, path)
        obj =  GitObjectBrowser::Models::Reflog.new(input).parse
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, path, obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end
    end
  end
end

