# -*- coding: utf-8 -*-

require 'spec_helper.rb'

module GitObjectBrowser::Models
  describe Index do
    let(:infile) { File.join(FIXTURES_DIR, 'worktree/_git/index') }
    let(:input) { File.open(infile) }
    subject { Index.new(input) }

    it 'should parse tree extensions' do
      index = subject.parse.to_hash
      tree = index['extensions'][0]
      tree['signature'].should eq 'TREE'
      tree['total_length'].should eq 25
      tree['entries'][0]['sha1'].should eq 'c36491256978d26c08cd7aa97eee0f5631f96659'
    end
  end
end
