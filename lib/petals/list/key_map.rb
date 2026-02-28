# frozen_string_literal: true

module Petals
  class List
    DEFAULT_KEY_MAP = KeyBinding.normalize({
                                             cursor_up: [[:up, []], ["k", []]],
                                             cursor_down: [[:down, []], ["j", []]],
                                             next_page: [[:page_down, []], ["n", [:ctrl]]],
                                             prev_page: [[:page_up, []], ["p", [:ctrl]]],
                                             goto_start: [["g", []], [:home, []]],
                                             goto_end: [["G", [:shift]], [:end_key, []]],
                                             filter: [["/", []]],
                                             clear_filter: [[:escape, []]],
                                             accept_filter: [[:enter, []]],
                                             show_full_help: [["?", []]],
                                           })
  end
end
