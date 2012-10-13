
module GitPlain

  module Server

    class GitServlet < WEBrick::HTTPServlet::AbstractServlet
      def initialize(target)
        @target = File.expand(target)
      end

      def do_GET(request, response)
        # status, content_type, body = do_stuff_with request

        response.status = 200
        response['Content-Type'] = 'text/plain'
        response.body = 'Hello, World!'
      end
    end
  end
end
