
module GitPlain

  module Models

    class Directory
      def initialize(root, path)
        @root = root
        @path = path
        @entries = []
        Dir.chdir(File.join(root, path)) do
          files = Dir.glob("*")
          files.each do |file|
            relpath = File.join(path, file).gsub(%r{\A/}, '')
            entry = {}
            if File.directory?(file)
              entry[:type] = "directory"
            elsif File.symlink?(file)
              entry[:type] = "symlink"
            elsif Ref::path?(relpath)
              entry[:type] = 'ref'
            elsif Index::path?(relpath)
              entry[:type] = 'index'
            elsif GitObject::path?(relpath)
              entry[:type] = 'object'
            else
              entry[:type] = "file"
            end
            entry[:basename] = file
            entry[:mtime] = File.mtime(file).to_i
            @entries << entry
          end
        end
      end

      def to_hash
        return {
          "type" => "directory",
          "path" => @path,
          "entries" => @entries
        }
      end

    end

  end
end
