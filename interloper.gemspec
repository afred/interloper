# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'interloper/version'

Gem::Specification.new do |spec|
  spec.name          = "interloper"
  spec.version       = Interloper::VERSION
  spec.authors       = ["Andrew Myers"]
  spec.email         = ["afredmyers@gmail.com"]

  spec.summary       = %q{Add before and after hooks to PORO methods.}
  spec.description   = %q{Interloper adds before and after hooks to methods on plain old ruby objects.}
  spec.homepage      = "https://github.com/afred/interloper"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3.1'

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug"
end
