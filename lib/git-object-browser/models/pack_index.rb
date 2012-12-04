# -*- coding: utf-8 -*-
module GitObjectBrowser

  module Models

    # v2
    #   signature  4bytes
    #   version    4bytes
    #   fanout     4bytes * 256
    #   sha1      20bytes * fanout[255]
    #   crc        4bytes * fanout[255]
    #   offset     4bytes * fanout[255]
    class PackIndex < BinFile

      def initialize(input)
        super(input)
      end

      def parse
        parse_fanout

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

        self
      end

      def parse_fanout
        return if @fanout

        seek(0)
        signature = raw(4)
        signature_v2 = [255, 'tOc'].pack('Ca*')

        raise "FIXME" if signature != signature_v2
        @version = int
        raise "FIXME" if @version != 2

        @fanout = []
        256.times do |i|
          @fanout << int
        end
      end

      def find(sha1_hex)
        parse_fanout
        sha1 = [sha1_hex].pack("H*")
        fanout_idx = sha1.unpack("C").first

        lo = fanout_idx == 0 ? 0 : @fanout[fanout_idx - 1]
        hi = @fanout[fanout_idx]

        while lo < hi
          mid = (lo + hi) / 2
          mid_sha1 = get_sha1(mid)
          puts "#{mid} #{mid_sha1.unpack("H*")}"
          if mid_sha1 == sha1
            return {
              :sha1   => sha1_hex,
              :crc    => get_crc_hex(mid),
              :offset => get_offset(mid)
            }
          elsif sha1 < mid_sha1
            hi = mid
          else
            lo = mid + 1
          end
        end
        nil
      end

      def get_sha1(pos)
        if @version == 2
          seek(4 + 4 + 4 * 256 + 20 * pos)
        else
          raise "FIXME version 1"
        end
        raw(20)
      end

      def get_crc_hex(pos)
        if @version == 2
          seek(4 + 4 + 4 * 256 + 20 * @fanout[255] + 4 * pos)
        else
          raise "FIXME version 1"
        end
        hex(4)
      end

      def get_offset(pos)
        if @version == 2
          seek(4 + 4 + 4 * 256 + 20 * @fanout[255] + 4 * @fanout[255] + 4 * pos)
        else
          raise "FIXME version 1"
        end
        int
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

      def load_object_types(input)
        obj = PackedObject.new(self, input)
        @entries.each do |entry|
          header = obj.parse_header(entry[:offset])
          if header[:type] == 'ofs_delta'
            obj.parse_ofs_delta_header(entry[:offset], header)
          elsif header[:type] == 'ref_delta'
            obj.parse_ref_delta_header(header)
          end
          entry.merge!(header)
        end
      end

    end
  end
end
