
module GitPlain

  module Server

    class GitServlet < WEBrick::HTTPServlet::AbstractServlet
      def initialize(server, target)
        @target = File.expand_path(target)
      end

      def do_GET(request, response)
        # status, content_type, body = do_stuff_with request

        path = request.path
        unless path =~ %r{/.git(?:/(.*))?}
          not_found(response)
          return
        end

        @relpath = $1.to_s
        path = File.join(@target, @relpath)
        unless File.exist?(path)
          not_found(response)
          return
        end

        if path =~ /\.\./
          not_found(response)
          return
        end

        return if response_directory(response)
        return if response_index(response)
        return if response_object(response)
        return if response_ref(response)
        return if response_pack_index(response)
        return if response_packed_refs(response)

        response_file(response)
      end

      def response_wrapped_object(response, type, obj)
        ok(response)
        hash = {}
        hash["type"] = type
        hash["object"] = obj.to_hash
        hash["root"] = @target
        hash["path"] = @relpath
        hash["wroking_dir"] = File.basename(File.dirname(@target))
        
        response.body = ::JSON.generate(hash)
      end

      def response_directory(response)
        return false unless File.directory?(File.join(@target, @relpath))

        obj = GitPlain::Models::Directory.new(@target, @relpath)
        response_wrapped_object(response, "directory", obj)
        return true
      end

      def response_index(response)
        return false unless @relpath == "index"

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitPlain::Models::Index.new(input)
        end
        response_wrapped_object(response, "index", obj)
        return true
      end

      def response_object(response)
        return false unless GitPlain::Models::GitObject.path?(@relpath)

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitPlain::Models::GitObject.new(input)
        end
        response_wrapped_object(response, "object", obj)
        return true
      end

      def response_ref(response)
        return false unless GitPlain::Models::Ref.path?(@relpath)

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitPlain::Models::Ref.new(input)
        end
        response_wrapped_object(response, "ref", obj)
        return true
      end

      def response_pack_index(response)
        return false unless GitPlain::Models::PackIndex.path?(@relpath)
        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitPlain::Models::PackIndex.new(input)
        end
        response_wrapped_object(response, "pack_index", obj)
        return true
      end

      def response_packed_refs(response)
        return false unless GitPlain::Models::PackedRefs.path?(@relpath)

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitPlain::Models::PackedRefs.new(input)
        end
        response_wrapped_object(response, "packed_refs", obj)
        return true
      end

      def response_file(response)
        path = File.join(@target, @relpath)
        obj = {
          "root" => @target,
          "relpath" => @relpath,
          "mtime" => File.mtime(path).to_i,
          "size" => File.size(path),
        }
        response_wrapped_object(response, "file", obj)
        return true
      end

      def ok(response)
        response.status = 200
        response['Content-Type'] = 'application/json'
      end

      def not_found(response)
        response.status = 404
        response['Content-Type'] = 'application/json'
        response.body = '{}'
      end
    end
  end
end

