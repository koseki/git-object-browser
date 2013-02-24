# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class PackedObjectDumper

      def initialize(input, index)
        @object = GitObjectBrowser::Models::PackedObject.new(index, input)
      end

      def dump(output, offset)
        output << JSON.pretty_generate(@object.parse(offset).to_hash)
      end

    end
  end
end
