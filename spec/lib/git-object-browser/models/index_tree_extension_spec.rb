# -*- coding: utf-8 -*-

require 'spec_helper.rb'

module GitObjectBrowser::Models
  describe IndexTreeExtension do

    let(:input) { File.open(File.join(FIXTURES_DIR, 'git/indexes', infile)) }
    subject { Index.new(input) }
    after { input.close if input && ! input.closed? }

    context 'when tree extension exists' do
      let(:infile) { '001' }

      it 'should parse extension signature and length' do
        data = subject.parse.to_hash
        tree = data['extensions'][0]
        tree['signature'].should eq 'TREE'
        tree['total_length'].should eq 25
      end

      it 'should parse entries' do
        entries = subject.parse.to_hash['extensions'][0]['entries']
        entries.length.should eq 1
        entry = entries.first
        entry['sha1'].should eq 'c36491256978d26c08cd7aa97eee0f5631f96659'
        entry['entry_count'].should eq 2
        entry['subtree_count'].should eq 0
      end
    end

    context 'when extension includes no entries' do
      let(:infile) { '002-empty-tree-extension' }

      it 'should parse extension signature and length' do
        data = subject.parse.to_hash
        tree = data['extensions'][0]
        tree['signature'].should eq 'TREE'
        tree['total_length'].should eq 6
      end

      it 'should return -1 entry_count' do
        entries = subject.parse.to_hash['extensions'][0]['entries']
        entries.length.should eq 1
        entry = entries.first
        entry['entry_count'].should eq -1
        entry['subtree_count'].should eq 0
        entry['path_component'].should eq ''
        entry['sha1'].should be_nil
      end

      it 'return correct hash' do
        data = subject.parse.to_hash
        data['sha1'].should eq 'cb9dab99534f6561c467b2fcbbd7cf54a9e8fc05'
      end
    end
  end
end
