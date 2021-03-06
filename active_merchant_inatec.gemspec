# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_merchant_inatec/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_merchant_inatec'
  spec.version       = ActiveMerchantInatec::VERSION
  spec.authors       = ['Janis Miezitis']
  spec.email         = ['janjiss@gmail.com']
  spec.summary       = %q{ActiveMerchant integration with inatec payment system}
  spec.description   = %q{}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activemerchant', '~> 1.47.0'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'webmock', '~> 1.20.4'
end
