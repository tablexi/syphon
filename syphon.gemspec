# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'syphon/version'

Gem::Specification.new do |gem|
  gem.name          = "syphon"
  gem.version       = Syphon::VERSION
  gem.authors       = ["Alex Skryl"]
  gem.email         = ["rut216@gmail.com"]
  gem.description   = %q{A tool for adding discoverable HATEOAS JSON APIs to your Rails 3 app}
  gem.summary       = %q{Bolt-on HATEOAS JSON API DSL}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
