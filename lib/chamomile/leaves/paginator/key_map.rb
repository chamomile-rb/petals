# frozen_string_literal: true

module Chamomile
  module Leaves
    class Paginator
      DEFAULT_KEY_MAP = KeyBinding.normalize({
                                               prev_page: [[:left, []], ["h", []], [:page_up, []]],
                                               next_page: [[:right, []], ["l", []], [:page_down, []]],
                                             })
    end
  end
end
