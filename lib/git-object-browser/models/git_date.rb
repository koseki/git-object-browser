# -*- coding: utf-8 -*-
module GitObjectBrowser

  module Models

    class GitDate
      attr_reader :unixtime, :timezone, :date

      def initialize(unixtime, timezone)
        @unixtime = unixtime
        @timezone = timezone
        @date = DateTime.strptime(unixtime.to_s, '%s').new_offset(parse_timezone(timezone))
      end

      def parse_timezone(timezone)
        timezone = '+00:00' if timezone == 'Z'
        return Rational(0, 24) unless timezone =~ /(\+|-)?(\d\d):?(\d\d)/
        Rational($2.to_i, 24) + Rational($3, 60) * (($1 == '-') ? -1 : 1)
      end

      def to_s
        @date.iso8601
      end
    end
  end
end
