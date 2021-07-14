# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-buildBinary/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-buildBinary'
  spec.version       = CocoapodsBuildbinary::VERSION
  spec.authors       = ['zhangyapeng']
  spec.email         = ['zhangyapeng@58.com']
  spec.description   = %q{A short description of cocoapods-buildBinary.}
  spec.summary       = %q{A longer description of cocoapods-buildBinary.}
  spec.homepage      = 'https://github.com/199055/buildBinary'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
