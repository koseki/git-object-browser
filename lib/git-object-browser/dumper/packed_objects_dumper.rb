# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class PackedObjectsDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump(path, index)
        File.open(File.join(@root, path)) do |input|
          index.entries.each do |entry|
            dump_packed_object(index, input, entry[:offset], path)
          end
        end
      end

      def dump_packed_object(index, input, offset, path)
        obj = GitObjectBrowser::Models::PackedObject.new(index, input).parse(offset)
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, path, obj)

        ostr = "0000#{ offset }"
        outfile = File.join(@outdir, path, ostr[-2,2], ostr[-4,2], "#{ offset }.json")
        FileUtils.mkdir_p(File.dirname(outfile))

        File.open(outfile, 'w') do |output|
          output << JSON.pretty_generate(wrapped.to_hash)
        end
      end
    end
  end
end
