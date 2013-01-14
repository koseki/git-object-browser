# -*- encoding: utf-8 -*-
require File.expand_path('../lib/git-object-browser/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['koseki']
  gem.email         = ['koseki@gmail.com']
  gem.description   = %q{Browse git raw objects.}
  gem.summary       = %q{Browse git raw objects.}
  gem.homepage      = 'https://github.com/koseki/git-object-browser'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'git-object-browser'
  gem.require_paths = ['lib']
  gem.version       = GitObjectBrowser::VERSION
  gem.required_ruby_version = '>= 1.9.2'
end
