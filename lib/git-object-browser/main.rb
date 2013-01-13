# -*- coding: utf-8 -*-
module GitObjectBrowser
  class Main
    def execute
      target = find_target(ARGV[1])
      if ARGV[0] == "dump"
        dumper = Dumper.new(target)
        dumper.dump
      else
        Server::Main.execute(target, 8080)
      end
    end

    def find_target(target = nil, git_dir_name = '.git')
      target ||= Dir::pwd
      return target if git_dir?(target)

      if File.directory?(target)
        dir = parent_git_dir(target, git_dir_name)
        return dir if dir
      end

      raise 'Git directory not found'
    end

    def git_dir?(dir)
      return false unless File.directory?(dir)
      return false unless File.directory?(File.join(dir, 'objects'))
      return false unless File.file?(File.join(dir, 'HEAD'))
      true
    end

    def parent_git_dir(target, git_dir_name)
      begin
        gitdir = File.join(target, git_dir_name)
        return gitdir if git_dir?(gitdir)
        lastdir = target
        target = File.dirname(target)
      end while lastdir != target
      nil
    end
    private :parent_git_dir
  end
end
