# -*- coding: utf-8 -*-

# http://book.git-scm.com/7_how_git_stores_objects.html
# http://code.google.com/p/git-core/source/browse/Documentation/technical/index-format.txt

require "git-plain/version"

require 'zlib'
require 'digest/sha1'
require 'stringio'

require "git-plain/models/binfile.rb"
require "git-plain/models/git_object.rb"
require "git-plain/models/index.rb"
require "git-plain/models/index_entry.rb"
require "git-plain/models/index_reuc_extension.rb"
require "git-plain/models/index_tree_extension.rb"

require "git-plain/dumper"
require "git-plain/object_dumper"
require "git-plain/index_dumper"

module GitPlain
  class Main
    def execute
      target = find_target
      dumper = Dumper.new(target)
      dumper.dump
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
