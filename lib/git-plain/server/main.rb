require 'webrick'

module GitPlain

  module Server
    
    class Main

      def initialize(target)
        @target = target
      end

      def start(port)
        root = File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))
        root = File.expand_path(File.join(root, "htdocs"))
        server = WEBrick::HTTPServer.new :Port => port, :DocumentRoot => root
        trap 'INT' do
          server.shutdown
        end
        server.start
      end

      def self.execute(target, port)
        self.new(target).start(port)
      end

    end
  end
end

