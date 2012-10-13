# -*- coding: utf-8 -*-

module GitPlain

  class ObjectDumper

    def initialize(input, output)
      @object = Models::GitObject.new(input)
      @out = output
    end

    def dump
      @out << "type: #{@object.type}\n"
      @out << "size: #{@object.size}\n"
      @out << "sha1: #{@object.sha1}\n"
      @out << "\n"
      if @object.type == "tree"
        dump_tree_entries
      else
        @out << @object.contents
      end
    end

    # man git-ls-tree
    def dump_tree_entries
      @object.entries.each do |entry|
        @out << "#{entry[:mode]} #{entry[:sha1]} #{entry[:filename]}\n"
      end
    end
  end
end
