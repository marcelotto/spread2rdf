# -*- encoding: utf-8 -*-
require File.expand_path('../lib/excel2rdf/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Marcel Otto']
  gem.email         = %w[marcelotto.de@gmail.com]
  gem.summary       = %q{converter for Excel tables to RDF}
  gem.description   = %q{Excel2RDF is ...}
  gem.homepage      = 'http://github.com/marcelotto/excel2rdf'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'excel2rdf'
  gem.require_paths = ['lib']
  gem.version       = Excel2RDF::VERSION
  gem.bindir        = 'bin'
  gem.executables   = ['excel2rdf']

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency('activesupport', '~> 3.2.3')
  gem.add_dependency('awesome_print')

  gem.add_dependency('excelerate')
  gem.add_dependency('linkeddata')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('pry', '~> 0.9.12.2')
  gem.add_development_dependency('pry-nav', '~> 0.2.3')

end
