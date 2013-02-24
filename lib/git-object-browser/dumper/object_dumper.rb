# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class ObjectDumper

      def initialize(input, output)
        @object = GitObjectBrowser::Models::GitObject.new(input)
        @out = output
      end

      def dump
        @out << JSON.pretty_generate(@object.parse.to_hash)
      end

    end
  end
end
