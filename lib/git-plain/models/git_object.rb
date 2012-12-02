# -*- coding: utf-8 -*-
module GitPlain

  module Models

    class GitObject < BinFile

      attr_reader :sha1, :type, :size, :entries, :contents
      attr_reader :properties, :message

      def initialize(input)
        super(input)
      end

      def parse
        content = Zlib::Inflate.inflate(@in.read)
        parse_inflated(content)
        self
      end

      def parse_inflated(content)
        @sha1 = Digest::SHA1.hexdigest(content)
        @in   = StringIO.new(content)

        @type = find_char ' '
        @size = find_char "\0"

        @type = type
        @size = size

        if @type == 'tree'
          @entries = parse_tree_entries
        else
          @contents = @in.read
          if @type == 'commit' or @type == 'tag'
            (@properties, @message) = parse_contents
          end
        end

        self
      end


      def to_hash
        return {
          'type' => @type,
          'sha1' => @sha1,
          'size' => @size,
          'entries' => @entries,
          'contents' => @contents,
          'properties' => @properties,
          'message' => @message,
        }
      end

      def self.path?(relpath)
        relpath =~ %r{\Aobjects/[0-9a-f]{2}/[0-9a-f]{38}\z}
      end


      private

      def parse_tree_entries
        entries = []
        loop do
          entry = {}
          entry[:mode]     = find_char ' '
          break if entry[:mode].empty?
          entry[:filename] = find_char "\0"
          entry[:sha1]     = hex(20)
          entries << entry
        end
        return entries
      end

      def parse_contents
        lines = @contents.split /\n/
        line = ''
        properties = []
        message = ''
        while ! lines.empty?
          line = lines.shift
          break if line.empty?
          prop = {}
          (prop['key'], prop['value']) = line.split(/ /, 2)
          if prop['value'] =~ /\A([0-9a-f]{2})([0-9a-f]{38})\z/
            prop['type'] = 'sha1'
            prop['path'] = "objects/#{ $1 }/#{ $2 }"
          elsif %w{author committer tagger}.include?(prop['key']) &&
              # couldn't find the spec...
              prop['value'].to_s =~ /\A(.*) <(.*)> (\d+)(?: ((?:(?:\+|-)(?:\d{4}|\d{2}:\d{2}))|Z))?\z/
            prop['type'] = 'user'
            prop['name'] = $1
            prop['email'] = $2
            prop['unixtime'] = $3
            prop['timezone'] = $4
            prop['date'] = Time.at($3.to_i).iso8601
          else
            prop['type'] = 'text'
          end
          properties << prop
        end
        message = lines.join "\n"

        [properties, message]
      end

    end
  end
end
