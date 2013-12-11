# -*- encoding: utf-8 -*-
require File.expand_path('../lib/spread2rdf/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'spread2rdf'
  gem.authors       = ['Marcel Otto']
  gem.email         = %w[marcelotto.de@gmail.com]
  gem.summary       = %q{a DSL-based converter for spreadsheets to RDF}
  gem.description   = %q{Spread2RDF is a converter for complex spreadsheets to RDF and a DSL for specifying the mapping rules for this conversion.}
  gem.homepage      = 'http://github.com/marcelotto/spread2rdf'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.version       = Spread2RDF::VERSION.to_s.dup
  gem.bindir        = 'bin'
  gem.executables   = ['spread2rdf']

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency('activesupport', '~> 3.2.3')
  gem.add_dependency('awesome_print', '~> 1.1.0')

  gem.add_dependency('roo', '~> 1.12.2')
  gem.add_dependency('rubyzip', '~> 1.0.0') # for the roo-xlsm-fix

  gem.add_dependency('linkeddata', '~> 1.1.0')
  gem.add_dependency('equivalent-xml', '~> 0.3.0')

  gem.add_dependency('ocra', '~> 1.3.1')
  gem.add_dependency('bundler') # needed for ocra

  gem.add_development_dependency('rake')
  gem.add_development_dependency('pry', '~> 0.9.12.2')
  gem.add_development_dependency('pry-nav', '~> 0.2.3')

end
