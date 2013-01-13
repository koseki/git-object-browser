require 'spec_helper'

module GitObjectBrowser
  describe Main do
    subject { Main.new }

    describe '#find_target' do
      it 'return git directory under the current directory' do
        dir = subject.find_target(File.join(FIXTURES_DIR, 'worktree'), '_git')
        dir.should match %r{/spec/fixtures/worktree/_git\z}
      end

      it 'return git directory under the parent directory' do
        dir = subject.find_target(File.join(FIXTURES_DIR, 'worktree/subdir'), '_git')
        dir.should match %r{/spec/fixtures/worktree/_git\z}
      end

      it 'return current git directory' do
        dir = subject.find_target(File.join(FIXTURES_DIR, 'worktree/_git'), '_git')
        dir.should match %r{/spec/fixtures/worktree/_git\z}
      end

      it 'use current directory if no arguments' do
        Dir.chdir(File.join(FIXTURES_DIR, 'worktree')) do
          dir = subject.find_target(nil, '_git')
          dir.should match %r{/spec/fixtures/worktree/_git\z}
        end
      end
    end
  end
end
