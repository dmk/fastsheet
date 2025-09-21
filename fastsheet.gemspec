# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastsheet/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastsheet'
  spec.version       = Fastsheet::VERSION
  spec.authors       = ['Dima Koval']
  spec.email         = ['kovaldimitri@gmail.com']

  spec.summary       = 'Fast XLSX reader'
  spec.description   = 'Fastest ruby gem for reading Excel documents.'

  spec.homepage      = 'https://github.com/dmk/fastsheet'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.require_paths = ['lib']
  spec.extensions = %w[extconf.rb]
  spec.required_ruby_version = '>= 3.2'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
