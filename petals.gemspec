# frozen_string_literal: true

require_relative "lib/petals/version"

Gem::Specification.new do |spec|
  spec.name          = "petals"
  spec.version       = Petals::VERSION
  spec.authors       = ["Chamomile Contributors"]
  spec.summary       = "Reusable TUI components for the Chamomile framework"
  spec.description   = "Spinner, TextInput, and more — composable widgets for Chamomile TUI apps"
  spec.license       = "MIT"
  spec.require_paths = ["lib"]
  spec.files         = Dir["lib/**/*.rb"]
  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "chamomile", "~> 0.1"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
