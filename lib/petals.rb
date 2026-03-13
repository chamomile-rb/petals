# frozen_string_literal: true

require "chamomile"

warn "[DEPRECATION] The `chamomile-petals` gem is deprecated. " \
     "All components are now part of `chamomile` (v1.0+). " \
     "Replace `require \"petals\"` with `require \"chamomile\"` " \
     "and change `Petals::` to `Chamomile::`."

Petals = Chamomile unless defined?(Petals)
