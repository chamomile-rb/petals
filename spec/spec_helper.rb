# frozen_string_literal: true

require "chamomile/leaves"

RSpec.configure do |config|
  config.order = :random
  Kernel.srand config.seed
end
