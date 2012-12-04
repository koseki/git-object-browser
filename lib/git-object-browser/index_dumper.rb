# -*- coding: utf-8 -*-

module GitObjectBrowser

  class IndexDumper

    def initialize(input, output)
      @index = Models::Index.new(input)
      @out = output
    end

    def dump
      @out << "----------------------------------------------------------------\n"
      @out << "header\n"
      @out << "----------------------------------------------------------------\n"
      @out << "version: #{@index.version}\n"
      @out << "entries: #{@index.entry_count}\n"
      @out << "\n"

      @index.entries.each_with_index do |entry, i|
        @out << "----------------------------------------------------------------\n"
        @out << "entry: #{i+1}\n"
        @out << "----------------------------------------------------------------\n"
        @out << "            ctime: #{entry.ctime}\n"
        @out << "       ctime nano: #{entry.cnano}\n"
        @out << "            mtime: #{entry.mtime}\n"
        @out << "       mtime nano: #{entry.mnano}\n"
        @out << "              dev: #{entry.dev}\n"
        @out << "              ino: #{entry.ino}\n"
        @out << "      object_type: #{entry.object_type}\n"
        @out << "  unix_permission: #{entry.unix_permission}\n"
        @out << "              uid: #{entry.uid}\n"
        @out << "              gid: #{entry.gid}\n"
        @out << "             size: #{entry.size}\n"
        @out << "             sha1: #{entry.sha1}\n"
        if @version == 2
          @out << "assume_valid_flag: #{entry.assume_valid_flag}\n"
          @out << "    extended_flag: #{entry.extended_flag}\n"
          @out << "            stage: #{entry.stage}\n"
        elsif @version == 3
          @out << "    skip_worktree: #{entry.skip_worktree}\n"
          @out << "    intent_to_add: #{entry.intent_to_add}\n"
        end
        @out << "      name_length: #{entry.name_length}\n"
        @out << "             path: #{entry.path}\n"
        @out << "\n"
      end

      @index.extensions.each do |extension|
        @out << "----------------------------------------------------------------\n"
        @out << "extension: #{extension.signature}\n"
        @out << "----------------------------------------------------------------\n"
        if extension.signature == "TREE"
          dump_tree_extension(extension)
        elsif extension.signature == "REUC"
          dump_reuc_extension
        end
      end
      
      @out << "----------------------------------------------------------------\n"
      @out << "checksum\n"
      @out << "----------------------------------------------------------------\n"
      @out << "sha1: #{@index.sha1}\n"
    end

    def dump_tree_extension(tree_extension)
      tree_extension.entries.each do |entry|
        @out << "   path_component: #{entry[:path_component]}\n"
        @out << "      entry_count: #{entry[:entry_count]}\n"
        @out << "    subtree_count: #{entry[:subtree_count]}\n"
        @out << "             sha1: #{entry[:sha1]}\n\n"
      end
    end

  end

end
