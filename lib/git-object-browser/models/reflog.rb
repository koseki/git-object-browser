
module GitObjectBrowser

  module Models

    class Reflog
      def initialize(input)
        @in = input
      end

      def parse
        @entries = []
        @content = @in.read(nil)
        @content = @content.force_encoding('UTF-8')
        unless @content.valid_encoding?
          @content = '(not UTF-8)'
          return self
        end
        parse_logs
        self
      end

      def parse_logs
        @content.split(/\n/).each do |line|
          log = {}
          (data, log[:message]) = line.split(/\t/, 2)
          if data.to_s =~ /\A([0-9a-f]{40}) ([0-9a-f]{40}) (.+)/
            log[:sha1_from] = $1
            log[:sha1_to]   = $2
            data = $3
            if data =~ /(.*) <(.*)> (\d+)(?: ((?:(?:\+|-)(?:\d{4}|\d{2}:\d{2}))|Z))?\z/
              log[:name]  = $1
              log[:email] = $2
              log[:unixtime] = $3
              log[:timezone] = $4
              log[:date] = GitDate.new($3, $4).to_s
            end
          end
          @entries << log
        end
      end
      private :parse_logs

      def to_hash
        return { :content => @content, :entries => @entries }
      end

      def self.path?(relpath)
        return relpath =~ %r{\Alogs/.+}
      end

    end
  end
end
