# -*- coding: utf-8 -*-
module GitPlain

  module Models

    class PackIndex < BinFile

      def initialize(input)
        super(input)
        parse
      end

      def parse
        signature = raw(4)
        signature_v2 = [255, 'tOc'].pack('Ca*')

        throw Exception.new("FIXME") if signature != signature_v2
        version = int
        throw Exception.new("FIXME") if version != 2

        @fanout = []
        256.times do |i|
          @fanout << int
        end

        @entries = []
        @fanout[255].times do |i|
          entry = {}
          entry[:sha1] = hex(20)
          @entries << entry
        end

        @fanout[255].times do |i|
          @entries[i][:crc32] = hex(4)
        end

        @fanout[255].times do |i|
          @entries[i][:offset] = int
        end

        # XXX Doesn't support packfile >= 2 GiB 
        # x.times do |i|
        #   puts "offset[#{ i }] = #{ hex(8) }"
        # end

        @packfile_sha1 = hex(20)
        @index_sha1 = hex(20)
      end

      def self.path?(relpath)
        return relpath =~ %r{\Aobjects/pack/pack-[0-9a-f]{40}.idx\z}
      end

      def to_hash
        return {
          :fanout => @fanout,
          :entries => @entries,
          :packfile_sha1 => @packfile_sha1,
          :index_sha1 => @index_sha1,
        }
      end

    end
  end
end
