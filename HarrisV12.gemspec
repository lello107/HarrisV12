# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'HarrisV12/version'

Gem::Specification.new do |spec|
  spec.name          = "HarrisV12"
  spec.version       = HarrisV12::VERSION
  spec.authors       = ["Marcello Romani"]
  spec.email         = ["lello107@hotmail.com"]

  spec.summary       = %q{Harris playlist version 12}
  spec.description   = %q{Read and Write Immagine Communication playlist v12}
  spec.homepage      = "http://github.com/lello107/HarrisV12"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "bindata"
  #spec.add_dependency "nokogiri"#, github: "sparklemotion/nokogiri"#
  spec.add_dependency "json"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
