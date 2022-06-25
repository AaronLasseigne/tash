# frozen_string_literal: true

require_relative 'lib/tash/version'

Gem::Specification.new do |spec|
  spec.name = 'tash'
  spec.version = Tash::VERSION
  spec.license = 'MIT'

  spec.authors = ['Aaron Lasseigne']
  spec.email = ['aaron.lasseigne@gmail.com']

  spec.summary = 'A hash that allows for transformation of its keys.'
  spec.description = <<~'TEXT'
    A hash that allows for transformation of its keys. A transformation block
    is given to change the key. Keys can be looked up with any value that
    transforms into the same key. This means a hash can be string/symbol
    insensitive, case insensitive, can convert camel case JSON keys to snake
    case Ruby keys, or anything else based on the block you provide.
  TEXT
  spec.homepage = 'https://github.com/AaronLasseigne/tash'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 2.7.0'

  spec.files =
    %w[CHANGELOG.md CONTRIBUTING.md LICENSE.md README.md] +
    Dir.glob(File.join('lib', '**', '*.rb')) +
    Dir.glob(File.join('sig', '*.rbs'))
  spec.test_files = Dir.glob(File.join('spec', '**', '*.rb'))
end
