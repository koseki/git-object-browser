
module GitObjectBrowser

  module Server

    class GitServlet < WEBrick::HTTPServlet::AbstractServlet
      def initialize(server, target)
        @target = File.expand_path(target)
      end

      def do_GET(request, response)
        # status, content_type, body = do_stuff_with request
        path = request.path
        unless path =~ %r{\A/json/(.+)\.json\z}
          not_found(response)
          return
        end

        @relpath = $1.to_s
        if @relpath == '_git'
          @relpath = ''
        elsif @relpath =~ %r{\A(objects/pack/pack-[0-9a-f]{40}\.pack)/\d{2}/\d{2}/(\d+)\z}
          @relpath = $1
          offset   = $2
        elsif @relpath =~ %r{\A(objects/pack/pack-[0-9a-f]{40}\.idx)/(sha1|offset)/(\d+)\z}
          @relpath = $1
          order    = $2
          page     = $3
        end
        path = File.join(@target, @relpath)

        unless File.exist?(path)
          not_found(response) unless redirect_to_packed_object(response)
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
        return if response_packed_object(response, offset)
        return if response_pack_file(response)
        return if response_pack_index(response, order, page)
        return if response_info_refs(response)
        return if response_packed_refs(response)

        response_file(response)
      end

      def redirect_to_packed_object(response)
        return false unless GitObjectBrowser::Models::GitObject.path?(@relpath)
        sha1 = @relpath.gsub(%r{\A.*/([0-9a-f]{2})/([0-9a-f]{38})\z}, '\1\2')

        Dir.chdir(@target) do
          Dir.glob('objects/pack/*.idx') do |path|
            File.open(path) do |input|
              index = GitObjectBrowser::Models::PackIndex.new(input)
              result = index.find(sha1)
              unless result.nil?
                packfile = path.sub(/\.idx\z/, '.pack')
                response.status = 302
                ostr = "0000#{ result[:offset] }"
                response["Location"] = "/json/#{ packfile }/#{ ostr[-2,2] }/#{ ostr[-4,2] }/#{ result[:offset] }.json"
                return true
              end
            end
          end
        end
        false
      end

      def response_wrapped_object(response, type, obj)
        ok(response)
        hash = {}
        hash[:type] = type
        hash[:object] = obj.to_hash
        hash[:root] = @target
        hash[:path] = @relpath
        hash[:wroking_dir] = File.basename(File.dirname(@target))

        if type == 'packed_object'
          sha1 = hash[:object][:object][:sha1]
          hash[:unpacked] = File.exist?(File.join(@target, 'objects', sha1[0..1], sha1[2..-1]).to_s)
        end

        response.body = ::JSON.generate(hash)
      end

      def response_directory(response)
        return false unless File.directory?(File.join(@target, @relpath))

        obj = GitObjectBrowser::Models::Directory.new(@target, @relpath)
        response_wrapped_object(response, "directory", obj)
        return true
      end

      def response_index(response)
        return false unless @relpath == "index"

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitObjectBrowser::Models::Index.new(input).parse
        end
        response_wrapped_object(response, "index", obj)
        return true
      end

      def response_object(response)
        return false unless GitObjectBrowser::Models::GitObject.path?(@relpath)

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitObjectBrowser::Models::GitObject.new(input).parse
        end
        response_wrapped_object(response, "object", obj)
        return true
      end

      def response_ref(response)
        return false unless GitObjectBrowser::Models::Ref.path?(@relpath)

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitObjectBrowser::Models::Ref.new(input)
        end
        response_wrapped_object(response, "ref", obj)
        return true
      end

      def response_pack_index(response, order, page)
        return false unless GitObjectBrowser::Models::PackIndex.path?(@relpath)
        obj = {}
        order ||= 'sha1'
        page = page.to_i
        page = 1 if page < 0
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitObjectBrowser::Models::PackIndex.new(input).parse(order, page)
        end
        File.open(index_to_pack_path) do |input|
          obj.load_object_types(input)
        end
        response_wrapped_object(response, "pack_index", obj)
        return true
      end

      def response_pack_file(response)
        return false unless GitObjectBrowser::Models::PackFile.path?(@relpath)
        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitObjectBrowser::Models::PackFile.new(input).parse
        end
        response_wrapped_object(response, 'pack_file', obj)
        return true
      end

      def index_to_pack_path
        File.join(@target, @relpath.sub(/\.idx\z/, '.pack'))
      end

      def pack_to_index_path
        File.join(@target, @relpath.sub(/\.pack\z/, '.idx'))
      end

      def response_packed_object(response, offset)
        return false if offset.nil?
        return false unless GitObjectBrowser::Models::PackedObject.path?(@relpath)
        obj = {}
        File.open(pack_to_index_path) do |index_input|
          index = GitObjectBrowser::Models::PackIndex.new(index_input)
          File.open(File.join(@target, @relpath)) do |input|
            obj = GitObjectBrowser::Models::PackedObject.new(index, input).parse(offset.to_i)
          end
        end
        response_wrapped_object(response, "packed_object", obj)
        return true
      end

      def response_info_refs(response)
        return false unless GitObjectBrowser::Models::InfoRefs.path?(@relpath)

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitObjectBrowser::Models::InfoRefs.new(input)
        end
        response_wrapped_object(response, "info_refs", obj)
        return true
      end

      def response_packed_refs(response)
        return false unless GitObjectBrowser::Models::PackedRefs.path?(@relpath)

        obj = {}
        File.open(File.join(@target, @relpath)) do |input|
          obj = GitObjectBrowser::Models::PackedRefs.new(input)
        end
        response_wrapped_object(response, "packed_refs", obj)
        return true
      end

      def response_file(response)
        path = File.join(@target, @relpath)
        obj = {}
        File.open(path) do |input|
          obj = GitObjectBrowser::Models::PlainFile.new(input).parse
        end
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

