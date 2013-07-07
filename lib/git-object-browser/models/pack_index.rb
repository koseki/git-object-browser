# -*- coding: utf-8 -*-
module GitObjectBrowser

  module Models

    # v2
    #   signature   4bytes
    #   version     4bytes
    #   fanout      4bytes * 256
    #   sha1       20bytes * fanout[255]
    #   crc32       4bytes * fanout[255]
    #   offset      4bytes * fanout[255]
    #   pack  sha1 20bytes
    #   index sha1 20bytes
    class PackIndex < Bindata
      PER_PAGE = 200

      def initialize(input)
        super(input)
      end

      def parse(order, page)
        parse_fanout
        @page = page
        @order = order

        if order == 'digest'
          parse_digest
        elsif order == 'sha1'
          parse_sha1_page
          set_fanouts
        else
          @order = 'offset'
          parse_offset_page
          set_fanouts
        end

        # XXX Doesn't support packfile >= 2 GiB
        # x.times do |i|
        #   puts "offset[#{ i }] = #{ hex(8) }"
        # end

        seek(4 + 4 + 4 * 256 + (20 + 4 + 4) * @fanout[255])
        @packfile_sha1 = hex(20)
        @index_sha1 = hex(20)

        self
      end

      def set_fanouts
        @fanout.each_with_index do |fo, i|
          entry = @entries.select { |entry| entry[:index] == fo }
          next if entry.empty?
          entry = entry.first
          entry[:fanout_min] = entry[:fanout_min] ? [entry[:fanout_min], i].min : i
          entry[:fanout_max] = entry[:fanout_max] ? [entry[:fanout_max], i].max : i
        end

        @entries.each do |entry|
          next unless entry[:fanout_min]
          entry[:fanout_min] = '%02x' % entry[:fanout_min]
          entry[:fanout_max] = '%02x' % entry[:fanout_max]
          entry.delete(:fanout_max) if entry[:fanout_min] == entry[:fanout_max]
        end
      end
      private :set_fanouts

      def parse_digest
        index = 0
        @entries = []
        while index <= @fanout[255] - 1
          @entries << hex(20)
          index += PER_PAGE
          skip(20 * (PER_PAGE - 1)) if index <= @fanout[255] - 1
        end
      end
      private :parse_digest

      def parse_sha1_page
        @entries = []
        @first_page = @page == 1
        @last_page  = true

        index_start = PER_PAGE * (@page - 1)
        index_end   = PER_PAGE * @page - 1
        index_last  = @fanout[255] - 1
        return if index_last < index_start
        if index_last <= index_end
          index_end = index_last
        else
          @last_page = false
        end
        entry_count = index_end - index_start + 1

        skip(20 * index_start)
        entry_count.times do |i|
          entry = { :index => index_start + i, :sha1 => hex(20) }
          @entries << entry
        end
        skip(20 * (index_last - index_end))

        skip(4 * index_start)
        entry_count.times do |i|
          @entries[i][:crc32] = hex(4)
        end
        skip(4 * (index_last - index_end))

        skip(4 * index_start)
        entry_count.times do |i|
          @entries[i][:offset] = int
        end
      end
      private :parse_sha1_page

      def parse_offset_page
        @entries = []
        @first_page = @page == 1
        @last_page  = true

        index_start = PER_PAGE * (@page - 1)
        index_end   = PER_PAGE * @page - 1
        index_last  = @fanout[255] - 1
        return if index_last < index_start
        if index_last <= index_end
          index_end = index_last
        else
          @last_page = false
        end
        entry_count = index_end - index_start + 1

        # load all offsets
        skip((20 + 4) * @fanout[255])
        offsets = []
        @fanout[255].times do |i|
          offsets << [i, int]
        end

        offsets = offsets.sort { |a,b| a[1] <=> b[1] }[index_start, entry_count]
        offsets.each do |offset|
          @entries << { :index => offset[0], :offset => offset[1] }
        end

        @entries.each do |entry|
          entry[:sha1] = get_sha1_hex(entry[:index])
          entry[:crc32] = get_crc32_hex(entry[:index])
        end
      end
      private :parse_offset_page

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
          mid_sha1 = get_sha1_raw(mid)
          if mid_sha1 == sha1
            return {
              :sha1   => sha1_hex,
              :crc32  => get_crc32_hex(mid),
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

      def get_sha1_raw(pos)
        if @version == 2
          seek(4 + 4 + 4 * 256 + 20 * pos)
        else
          raise "FIXME version 1"
        end
        raw(20)
      end

      def get_sha1_hex(pos)
        if @version == 2
          seek(4 + 4 + 4 * 256 + 20 * pos)
        else
          raise "FIXME version 1"
        end
        hex(20)
      end

      def get_crc32_hex(pos)
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
        return relpath =~ %r{\Aobjects/pack/pack-[0-9a-f]{40}\.idx\z}
      end

      def to_hash
        return {
          :entries       => @entries,
          :packfile_sha1 => @packfile_sha1,
          :index_sha1    => @index_sha1,
          :first_page    => @first_page,
          :last_page     => @last_page,
          :page          => @page,
          :order         => @order
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
