require 'webrick'

module GitObjectBrowser

  module Server

    class Main

      def initialize(target)
        @target = target
      end

      def start(host, port)
        root = File.dirname(File.dirname(File.dirname(File.dirname(__FILE__))))
        root = File.expand_path(File.join(root, "htdocs"))
        opts = { :BindAddress => host, :Port => port, :DocumentRoot => root }
        server = WEBrick::HTTPServer.new(opts)
        server.mount('/.git', GitServlet, @target)
        trap 'INT' do
          server.shutdown
        end
        server.start
      end

      def self.execute(target, host, port)
        self.new(target).start(host, port)
      end

    end
  end
end
