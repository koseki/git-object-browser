# -*- coding: utf-8 -*-

# http://book.git-scm.com/7_how_git_stores_objects.html
# http://code.google.com/p/git-core/source/browse/Documentation/technical/index-format.txt

require "git-plain/version"

require 'zlib'
require 'digest/sha1'
require 'json'
require 'stringio'

require "git-plain/models/ref"
require "git-plain/models/binfile"
require "git-plain/models/directory"
require "git-plain/models/git_object"
require "git-plain/models/index"
require "git-plain/models/index_entry"
require "git-plain/models/index_reuc_extension"
require "git-plain/models/index_tree_extension"
require "git-plain/server/main"
require "git-plain/server/git_servlet"

require "git-plain/dumper"
require "git-plain/object_dumper"
require "git-plain/index_dumper"

module GitPlain

  class Main

    def execute
      target = find_target
      if ARGV[0] == "dump"
        dumper = Dumper.new(target)
        dumper.dump
      else
        Server::Main.execute(target, 8080)
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

GitPlain::Main.new().execute if __FILE__ == $0
