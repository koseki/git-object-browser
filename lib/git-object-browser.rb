# -*- coding: utf-8 -*-

# http://book.git-scm.com/7_how_git_stores_objects.html
# http://code.google.com/p/git-core/source/browse/Documentation/technical/index-format.txt

require "git-object-browser/version"

require 'zlib'
require 'digest/sha1'
require 'json'
require 'time'
require 'stringio'
require 'optparse'

require "git-object-browser/main"
require "git-object-browser/models/ref"
require "git-object-browser/models/bindata"
require "git-object-browser/models/directory"
require "git-object-browser/models/git_object"
require "git-object-browser/models/index"
require "git-object-browser/models/index_entry"
require "git-object-browser/models/index_reuc_extension"
require "git-object-browser/models/index_tree_extension"
require "git-object-browser/models/info_refs"
require "git-object-browser/models/pack_file"
require "git-object-browser/models/pack_index"
require "git-object-browser/models/packed_object"
require "git-object-browser/models/packed_refs"
require "git-object-browser/models/plain_file"
require "git-object-browser/models/wrapped_object"
require "git-object-browser/server/main"
require "git-object-browser/server/git_servlet"

require "git-object-browser/dumper/main"
require "git-object-browser/dumper/objects_dumper"
require "git-object-browser/dumper/index_dumper"
require "git-object-browser/dumper/directories_dumper"
require "git-object-browser/dumper/plain_files_dumper"
require "git-object-browser/dumper/refs_dumper"
require "git-object-browser/dumper/packed_refs_dumper"
require "git-object-browser/dumper/pack_indexes_dumper"
require "git-object-browser/dumper/packed_objects_dumper"
require "git-object-browser/dumper/info_refs_dumper"

GitObjectBrowser::Main.new().execute if __FILE__ == $0
