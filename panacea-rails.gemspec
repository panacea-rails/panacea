# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "panacea/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "panacea-rails"
  spec.version       = Panacea::Rails::VERSION
  spec.authors       = ["Guillermo Moreno", "Rafael Ramos", "Eduardo Figarola"]
  spec.email         = ["guillermo@michelada.io", "rafael@michelada.io", "eduardo@michelada.io"]

  spec.summary       = "Rails Apps Generator"
  spec.homepage      = "https://www.panacea.website"
  spec.license       = "MIT"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1"
  spec.add_dependency "slop", "~> 4.6"
  spec.add_dependency "tty-prompt", "~> 0.17"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rubocop", "~> 0.58"
  spec.add_development_dependency "sdoc", "~> 1.0"
end
