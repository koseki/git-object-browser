# -*- coding: utf-8 -*-

# http://book.git-scm.com/7_how_git_stores_objects.html
# http://code.google.com/p/git-core/source/browse/Documentation/technical/index-format.txt

require "git-object-browser/version"

require 'zlib'
require 'digest/sha1'
require 'json'
require 'time'
require 'stringio'

require "git-object-browser/models/ref"
require "git-object-browser/models/binfile"
require "git-object-browser/models/directory"
require "git-object-browser/models/git_object"
require "git-object-browser/models/index"
require "git-object-browser/models/index_entry"
require "git-object-browser/models/index_reuc_extension"
require "git-object-browser/models/index_tree_extension"
require "git-object-browser/models/pack_file"
require "git-object-browser/models/pack_index"
require "git-object-browser/models/packed_object"
require "git-object-browser/models/packed_refs"
require "git-object-browser/server/main"
require "git-object-browser/server/git_servlet"

require "git-object-browser/dumper"
require "git-object-browser/object_dumper"
require "git-object-browser/index_dumper"

module GitObjectBrowser

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
      target = ARGV[1]
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

GitObjectBrowser::Main.new().execute if __FILE__ == $0
