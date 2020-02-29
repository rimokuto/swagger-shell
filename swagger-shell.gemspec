
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "swagger/shell/version"

Gem::Specification.new do |spec|
  spec.name          = "swagger-shell"
  spec.version       = Swagger::Shell::VERSION
  spec.authors       = ["Junya Tokumori"]
  spec.email         = ["rimokuto@gmail.com"]

  spec.summary       = "swagger-shell"
  spec.description   = "shell cli for swagger"
  spec.homepage      = "https://github.com/rimokuto/swagger-shell"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 0.10" # TODO: net/http
  spec.add_dependency "parallel", "~> 1.12"
  spec.add_dependency "pry", "~> 0.11"
  spec.add_dependency "rb-readline", "~> 0.5" # TODO: if possible to delete

  # spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
