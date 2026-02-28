# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Use local checkout for development; CI uses the gemspec dependency from rubygems
gem "chamomile", path: "../chamomile" if File.directory?(File.expand_path("../chamomile", __dir__))
