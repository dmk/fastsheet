# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastsheet/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastsheet'
  spec.version       = Fastsheet::VERSION
  spec.authors       = ['Dmitry Koval']
  spec.email         = ['dkoval@heliostech.fr']

  spec.summary       = 'Fast XLSX reader'
  spec.description   = 'Fastest ruby gem for reading Excel documents.'

  spec.homepage      = 'https://github.com/dkkoval/fastsheet'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.require_paths = ['lib']
  spec.extensions = %w[extconf.rb]

  spec.add_development_dependency 'rake', '~>12.0.0'
  spec.add_development_dependency 'pry', '~>0.10.4'
end
