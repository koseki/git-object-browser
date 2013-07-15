
module GitObjectBrowser

  module Models

    class WrappedObject < Hash

      def initialize(root, path, obj)
        super()
        self[:type] = {
          Directory    => 'directory',
          PlainFile    => 'file',
          Index        => 'index',
          GitObject    => 'object',
          Ref          => 'ref',
          PackIndex    => 'pack_index',
          PackFile     => 'pack_file',
          PackedObject => 'packed_object',
          InfoRefs     => 'info_refs',
          PackedRefs   => 'packed_refs',
        }[obj.class]

        self[:object] = obj.to_hash
        self[:root] = root
        self[:path] = path
        self[:working_dir] = File.basename(File.dirname(root.to_s))

        case(self[:type])
        when 'packed_object'
          sha1 = self[:object][:object][:sha1]
          unpacked_file = File.join(root.to_s, 'objects', sha1[0..1], sha1[2..-1]).to_s
          self[:unpacked] = File.exist?(unpacked_file)
        when 'pack_index'
          self.merge!(obj.page_data)
        end
      end
    end
  end
end
