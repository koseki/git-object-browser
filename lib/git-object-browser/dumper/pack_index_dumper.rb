# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class PackIndexDumper
      attr_reader :pack_index

      def initialize(input, output)
        @pack_index = GitObjectBrowser::Models::PackIndex.new(input)
        @out = output
      end

      def dump
        @out << JSON.pretty_generate(@pack_index.parse.to_hash)
      end

    end
  end
end
