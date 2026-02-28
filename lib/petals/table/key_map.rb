# frozen_string_literal: true

module Petals
  class Table
    DEFAULT_KEY_MAP = KeyBinding.normalize({
                                             up: [[:up, []], ["k", []]],
                                             down: [[:down, []], ["j", []]],
                                             page_up: [[:page_up, []]],
                                             page_down: [[:page_down, []]],
                                             goto_top: [["g", []]],
                                             goto_bottom: [["G", [:shift]]],
                                           })
  end
end
