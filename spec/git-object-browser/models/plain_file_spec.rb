require 'spec_helper.rb'

module GitObjectBrowser::Models
  describe PlainFile do
    it 'should read content' do
      input = File.open(File.join(FIXTURES_DIR, 'git/plain_file'))
      data = PlainFile.new(input).parse.to_hash
      data.should eq({ :content => 'sample' })
    end
  end
end
