# -*- coding: utf-8 -*-

# http://book.git-scm.com/7_how_git_stores_objects.html
# http://code.google.com/p/git-core/source/browse/Documentation/technical/index-format.txt

require "git-plain/version"

require 'zlib'
require 'digest/sha1'
require 'stringio'

require "git-plain/binfile"
require "git-plain/object_dumper"
require "git-plain/index_dumper"

module GitPlain
  class Main
    def execute
      target = find_target
      outdir = target + "/plain"
      Dir.mkdir(outdir) unless File.exist?(outdir)
      if File.exist?(target + "/index")
        STDERR << "Write: .git/plain/index\n"
        File.open(target + "/index") do |input|
          File.open(outdir + "/index", "w") do |output|
            dumper = GitPlain::IndexDumper.new(input, output)
            dumper.dump
          end
        end
      end

      obj_files = []
      Dir.chdir(target) do
        Dir.glob("objects/**/*") do |path|
          obj_files << path if File.file?(path) && path =~ %r{/[a-z0-9]{38}$}
        end
      end
      return if obj_files.empty?
      Dir.mkdir(outdir + "/objects") unless File.exist?(outdir + "/objects")

      obj_files.each do |path|
        outfile = outdir + "/" + path
        next if File.exist?(outfile)

        parent = File.dirname(outfile)
        Dir.mkdir(parent) unless File.exist?(parent)

        STDERR << "Write: .git/plain/#{path}\n"
        File.open(target + "/" + path) do |input|
          File.open(outfile, "w") do |output|
            dumper = GitPlain::ObjectDumper.new(input, output)
            dumper.dump
          end
        end
      end

    end

    def find_target
      target = Dir.pwd
      begin
        if File.exist?(target + "/.git")
          return target + "/.git"
        end
        target = File.dirname(target)
      end while target != "/" # XXX 

      throw Exception.new(".git not found")
    end
  end

end
