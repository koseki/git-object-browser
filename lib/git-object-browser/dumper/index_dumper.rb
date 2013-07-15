# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class IndexDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end


      def dump
        index_file = File.join(@root, "index")
        out_file   = File.join(@outdir, "index.json")

        return unless File.exist?(index_file)

        puts "Write: index\n"
        File.open(index_file) do |input|
          File.open(out_file, "w") do |output|
            dump_object(input, output)
          end
        end
      end

      def dump_object(input, output)
        obj =  GitObjectBrowser::Models::Index.new(input).parse
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, 'index', obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end

    end
  end
end
