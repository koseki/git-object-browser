# -*- coding: utf-8 -*-

module GitObjectBrowser

  module Dumper

    class IndexDumper

      def initialize(input, output)
        @index = GitObjectBrowser::Models::Index.new(input)
        @out = output
      end

      def dump
        @out << JSON.pretty_generate(@index.parse.to_hash)

        # template = File.join(GitObjectBrowser::Dumper::TEMPLATES_DIR, 'index.txt.erb')
        # index = @index.parse.to_hash
        # @out << ERB.new(File.read(template), nil, '-').result(binding)
      end

    end
  end
end
