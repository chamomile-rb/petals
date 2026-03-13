# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "chamomile-petals"
  spec.version       = "0.3.0"
  spec.authors       = ["Jack Killilea"]
  spec.summary       = "[DEPRECATED] Use chamomile instead"
  spec.description   = "This gem is deprecated. All components are now part of the chamomile gem (v1.0+). " \
                       "This shim pulls in chamomile and aliases Petals to Chamomile for backward compatibility."
  spec.license       = "MIT"
  spec.require_paths = ["lib"]
  spec.files         = Dir["lib/**/*.rb"]
  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "chamomile", "~> 1.0"

  spec.homepage = "https://github.com/chamomile-rb/chamomile"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = "https://github.com/chamomile-rb/chamomile"
  spec.metadata["changelog_uri"]         = "https://github.com/chamomile-rb/chamomile/blob/master/CHANGELOG.md"

  spec.post_install_message = <<~MSG
    [DEPRECATION] chamomile-petals is deprecated.
    All components are now part of the `chamomile` gem (v1.0+).
    Replace `gem "petals"` with `gem "chamomile"` in your Gemfile.
  MSG
end
