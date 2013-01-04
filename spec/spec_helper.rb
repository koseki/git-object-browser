require 'rubygems'
require 'spork'

#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  require 'rspec'

  FIXTURES_DIR = File.join(File.dirname(__FILE__), 'fixtures')
end

Spork.each_run do
  require 'git-object-browser'
end
