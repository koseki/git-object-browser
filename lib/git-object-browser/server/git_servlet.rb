module GitObjectBrowser

  module Server

    class GitServlet < WEBrick::HTTPServlet::AbstractServlet

      SEARCH_PACKED_OBJECT = true

      def initialize(server, target)
        @target = File.expand_path(target)
      end

      def do_GET(request, response)
        @params = parse_params(request, response)
        unless @params
          not_found(response)
          return
        end

        unless File.exist?(@params[:abspath])
          not_found unless redirect_to_packed_object
          return
        end

        [:response_directory,
         :response_index,
         :response_object,
         :response_ref,
         :response_packed_object,
         :response_pack_file,
         :response_pack_index,
         :response_info_refs,
         :response_packed_refs,
         :response_file
        ].each { |action| return if send(action) }
      end


      private

      def parse_params(request, response)
        params = { :request => request, :response => response }

        path = request.path
        return nil unless path =~ %r{\A/json/(.+)\.json\z}
        params[:relpath] = $1.to_s

        pack_rex = 'objects/pack/pack-[0-9a-f]{40}'
        if params[:relpath] == '_git'
          params[:relpath] = ''
        elsif params[:relpath] =~ %r{\A(#{ pack_rex }\.pack)/\d{2}/\d{2}/(\d+)\z}
          params[:relpath] = $1
          params[:offset]  = $2.to_i
        elsif params[:relpath] =~ %r{\A(#{ pack_rex }\.idx)\z}
          params[:relpath] = $1
          params[:order]   = 'digest'
        elsif params[:relpath] =~ %r{\A(#{ pack_rex }\.idx)/(sha1|offset)/(\d+)\z}
          params[:relpath] = $1
          params[:order]   = $2
          params[:page]    = $3.to_i
        end
        return nil if params[:relpath] =~ /\.\./

        params[:abspath] = File.join(@target, params[:relpath])

        return params
      end

      def redirect_to_packed_object
        return false unless SEARCH_PACKED_OBJECT
        return false unless GitObjectBrowser::Models::GitObject.path?(@params[:relpath])
        sha1 = @params[:relpath].gsub(%r{\A.*/([0-9a-f]{2})/([0-9a-f]{38})\z}, '\1\2')

        Dir.chdir(@target) do
          Dir.glob('objects/pack/*.idx') do |path|
            File.open(path) do |input|
              index = GitObjectBrowser::Models::PackIndex.new(input)
              result = index.find(sha1)
              unless result.nil?
                packfile = path.sub(/\.idx\z/, '.pack')
                @params[:response].status = 302
                ostr = "0000#{ result[:offset] }"
                @params[:response]['Location'] = "/json/#{ packfile }/#{ ostr[-2,2] }/#{ ostr[-4,2] }/#{ result[:offset] }.json"
                return true
              end
            end
          end
        end
        false
      end

      def response_directory
        return false unless File.directory?(@params[:abspath])

        obj = GitObjectBrowser::Models::Directory.new(@target, @params[:relpath])
        response_wrapped_object('directory', obj)
        return true
      end

      def response_index
        return false unless @params[:relpath] == 'index'

        obj = {}
        File.open(@params[:abspath]) do |input|
          obj = GitObjectBrowser::Models::Index.new(input).parse
        end
        response_wrapped_object('index', obj)
        return true
      end

      def response_object
        return false unless GitObjectBrowser::Models::GitObject.path?(@params[:relpath])

        obj = {}
        File.open(@params[:abspath]) do |input|
          obj = GitObjectBrowser::Models::GitObject.new(input).parse
        end
        response_wrapped_object('object', obj)
        return true
      end

      def response_ref
        return false unless GitObjectBrowser::Models::Ref.path?(@params[:relpath])

        obj = {}
        File.open(@params[:abspath]) do |input|
          obj = GitObjectBrowser::Models::Ref.new(input)
        end
        response_wrapped_object('ref', obj)
        return true
      end

      def response_pack_index
        return false unless GitObjectBrowser::Models::PackIndex.path?(@params[:relpath])
        obj = {}
        File.open(@params[:abspath]) do |input|
          obj = GitObjectBrowser::Models::PackIndex.new(input).parse(@params[:order], @params[:page])
        end
        if @params[:order] != 'digest'
          File.open(index_to_pack_path) do |input|
            obj.load_object_types(input)
          end
        end
        response_wrapped_object('pack_index', obj)
        return true
      end

      def response_pack_file
        return false unless GitObjectBrowser::Models::PackFile.path?(@params[:relpath])
        obj = {}
        File.open(@params[:abspath]) do |input|
          obj = GitObjectBrowser::Models::PackFile.new(input).parse
        end
        response_wrapped_object('pack_file', obj)
        return true
      end

      def response_packed_object
        return false if @params[:offset].nil?
        return false unless GitObjectBrowser::Models::PackedObject.path?(@params[:relpath])
        obj = {}
        File.open(pack_to_index_path) do |index_input|
          index = GitObjectBrowser::Models::PackIndex.new(index_input)
          File.open(@params[:abspath]) do |input|
            obj = GitObjectBrowser::Models::PackedObject.new(index, input).parse(@params[:offset])
          end
        end
        response_wrapped_object('packed_object', obj)
        return true
      end

      def response_info_refs
        return false unless GitObjectBrowser::Models::InfoRefs.path?(@params[:relpath])

        obj = {}
        File.open(@params[:abspath]) do |input|
          obj = GitObjectBrowser::Models::InfoRefs.new(input)
        end
        response_wrapped_object('info_refs', obj)
        return true
      end

      def response_packed_refs
        return false unless GitObjectBrowser::Models::PackedRefs.path?(@params[:relpath])

        obj = {}
        File.open(@params[:abspath]) do |input|
          obj = GitObjectBrowser::Models::PackedRefs.new(input)
        end
        response_wrapped_object('packed_refs', obj)
        return true
      end

      def response_file
        obj = {}
        File.open(@params[:abspath]) do |input|
          obj = GitObjectBrowser::Models::PlainFile.new(input).parse
        end
        response_wrapped_object('file', obj)
        return true
      end


      def response_wrapped_object(type, obj)
        ok
        hash = {}
        hash[:type] = type
        hash[:object] = obj.to_hash
        hash[:root] = @target
        hash[:path] = @params[:relpath]
        hash[:wroking_dir] = File.basename(File.dirname(@target))

        if type == 'packed_object'
          sha1 = hash[:object][:object][:sha1]
          unpacked_file = File.join(@target, 'objects', sha1[0..1], sha1[2..-1]).to_s
          hash[:unpacked] = File.exist?(unpacked_file)
        end

        @params[:response].body = ::JSON.generate(hash)
      end

      def ok(response = nil)
        response ||= @params[:response]
        response.status = 200
        response['Content-Type'] = 'application/json'
      end

      def not_found(response = nil)
        response ||= @params[:response]
        response.status = 404
        response['Content-Type'] = 'application/json'
        response.body = '{}'
      end

      def index_to_pack_path
        File.join(@target, @params[:relpath].sub(/\.idx\z/, '.pack'))
      end

      def pack_to_index_path
        File.join(@target, @params[:relpath].sub(/\.pack\z/, '.idx'))
      end
    end
  end
end
