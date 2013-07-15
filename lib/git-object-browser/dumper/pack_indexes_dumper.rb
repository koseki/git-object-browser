# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class PackIndexesDumper

      def initialize(root, outdir)
        @root   = root
        @outdir = outdir
      end

      def dump
        index_files = []
        Dir.chdir(@root) do
          Dir.glob('objects/pack/pack-*.idx') do |path|
            next unless path =~ %r{/pack-[0-9a-f]{40}\.idx}
            index_files << path
          end
        end
        return if index_files.empty?

        # digest, sha1 order, offset order
        index_files.each do |path|
          dump_digest(path)
          dump_ordered(path, 'sha1')
          dump_ordered(path, 'offset')
        end
      end

      def dump_digest(path)
        outfile = File.join(@outdir, "#{ path }.json")
        infile  = File.join(@root, path)
        FileUtils.mkdir_p(File.dirname(outfile))
        puts "Write: #{path}\n"

        File.open(infile) do |input|
          File.open(outfile, 'w') do |output|
            dump_object(input, output, path, 'digest', nil)
          end
        end
      end

      def dump_object(input, output, path, order, page)
        obj =  GitObjectBrowser::Models::PackIndex.new(input).parse(order, page)
        wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, path, obj)
        output << JSON.pretty_generate(wrapped.to_hash)
      end

      def dump_ordered(path, order)
        FileUtils.mkdir_p(File.join(@outdir, "#{ path }/#{ order }"))
        page = 1
        loop do
          outfile = File.join(@outdir, "#{ path }/#{ order }/#{ page }.json")
          infile  = File.join(@root, path)
          obj = nil
          File.open(infile) do |input|
            obj =  GitObjectBrowser::Models::PackIndex.new(input).parse(order, page)
          end
          break if obj.empty?

          packpath = path.sub(/\.idx\z/, '.pack')
          packfile = File.join(@root, packpath)
          File.open(packfile) do |input|
            obj.load_object_types(input)
          end

          puts "Write: #{ path }/#{ order }/#{ page }\n"
          File.open(outfile, 'w') do |output|
            wrapped = GitObjectBrowser::Models::WrappedObject.new(nil, path, obj)
            output << JSON.pretty_generate(wrapped.to_hash)
          end

          if order == 'offset'
            dumper = GitObjectBrowser::Dumper::PackedObjectsDumper.new(@root, @outdir)
            dumper.dump(packpath, obj)
          end
          page += 1
        end
      end
    end
  end
end

