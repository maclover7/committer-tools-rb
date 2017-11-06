# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'committer-tools/version'

Gem::Specification.new do |spec|
  spec.name          = 'committer-tools'
  spec.version       = '0.1.0'
  spec.authors       = 'Jon Moss'
  spec.email         = 'me@jonathanmoss.me'

  spec.summary       = 'A Node.js collaborator CLI utility.'
  spec.description   = 'A Node.js collaborator CLI utility.'
  spec.homepage      = 'https://github.com/maclover7/committer-tools-rb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rest-client'
end
