# -*- coding: utf-8 -*-

require 'spec_helper.rb'

module GitObjectBrowser::Models
  describe Index do
    let(:infile) { '001' }
    let(:input) { File.open(File.join(FIXTURES_DIR, 'git/indexes', infile)) }
    subject { Index.new(input) }
    after { input.close if input && ! input.closed? }

    it 'should parse header' do
      index = subject.parse.to_hash
      index['version'].should eq 2
      index['entry_count'].should eq index['entries'].length
    end

    it 'should parse entries' do
      index = subject.parse.to_hash
      entries = index['entries']
      entries.length.should eq 2
      entries[0]['path'].should eq 'sample-a.txt'
      entries[0]['sha1'].should eq '1d3dc60b5a117054e43741d51e599ff31bb15f9f'
      entries[0]['object_type'].should eq '1000'
      entries[0]['unix_permission'].should eq '644'
      entries[0]['size'].should eq 9

      entries[1]['path'].should eq 'sample.txt'
      entries[1]['sha1'].should eq 'd234c5e057fe32c676ea67e8cb38f4625ddaeb54'
      entries[1]['object_type'].should eq '1000'
      entries[1]['unix_permission'].should eq '644'
      entries[0]['size'].should eq 9
    end

    it 'should parse extensions (index_tree_extension_spec.rb tests the content)' do
      index = subject.parse.to_hash
      extensions = index['extensions']
      extensions.length.should eq 1
    end

  end
end
