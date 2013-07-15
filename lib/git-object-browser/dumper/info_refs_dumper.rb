# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class InfoRefsDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump
        src_file = File.join(@root, "info/refs")
        dst_file = File.join(@outdir, "info/refs.json")

        return unless File.exist?(src_file)

        puts "Write: info/refs\n"
        File.open(src_file) do |input|
          File.open(dst_file, "w") do |output|
            dump_object(input, output)
          end
        end
      end

      def dump_object(input, output)
        obj =  GitObjectBrowser::Models::InfoRefs.new(input)
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, 'info/refs', obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end

    end
  end
end

