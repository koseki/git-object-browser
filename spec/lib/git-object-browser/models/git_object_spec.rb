require 'spec_helper.rb'
require 'pp'

module GitObjectBrowser::Models
  describe GitObject do
    def load_json(file)
      File.read(File.join(FIXTURES_DIR, 'json', file)).strip
    end

    let(:infile) { File.join(FIXTURES_DIR, 'worktree', '_git', 'objects', sha1[0,2], sha1[2,40]) }
    let(:input) { File.open(infile) }
    subject { GitObject.new(input) }

    describe 'tag object' do
      let(:sha1) { '00cb8bfeb5b8ce906d39698e4e33b38341f5448f' }

      it 'should be parsed' do
        expect = load_json('test3-tag.json')
        JSON.pretty_generate(subject.parse.to_hash).should eq expect
      end
    end

    describe 'commit object' do
      let(:sha1) { '37d1632d3f1159dad9cfb58e6c34312ab4355c49' }

      it 'should be parsed' do
        expect = load_json('merge-a.json')
        JSON.pretty_generate(subject.parse.to_hash).should eq expect
      end
    end

    describe 'tree object' do
      let(:sha1) { 'c36491256978d26c08cd7aa97eee0f5631f96659' }

      it 'should be parsed' do
        expect = load_json('tree.json')
        JSON.pretty_generate(subject.parse.to_hash).should eq expect
      end
    end

    describe 'blob object' do
      let(:sha1) { 'd234c5e057fe32c676ea67e8cb38f4625ddaeb54' }

      it 'should be parsed' do
        expect = load_json('blob.json')
        JSON.pretty_generate(subject.parse.to_hash).should eq expect
      end
    end

  end
end
