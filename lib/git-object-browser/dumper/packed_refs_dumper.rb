# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class PackedRefsDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump
        src_file = File.join(@root, "packed-refs")
        dst_file = File.join(@outdir, "packed-refs.json")

        return unless File.exist?(src_file)

        puts "Write: packed-refs\n"
        File.open(src_file) do |input|
          File.open(dst_file, "w") do |output|
            dump_object(input, output)
          end
        end
      end

      def dump_object(input, output)
        obj =  GitObjectBrowser::Models::PackedRefs.new(input)
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, 'packed-refs', obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end

    end
  end
end

