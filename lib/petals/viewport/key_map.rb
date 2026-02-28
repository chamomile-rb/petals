# frozen_string_literal: true

module Petals
  class Viewport
    DEFAULT_KEY_MAP = KeyBinding.normalize({
                                             up: [[:up, []], ["k", []]],
                                             down: [[:down, []], ["j", []]],
                                             page_up: [[:page_up, []], ["b", []]],
                                             page_down: [[:page_down, []], ["f", []], [" ", []]],
                                             half_page_up: [["u", [:ctrl]]],
                                             half_page_down: [["d", [:ctrl]]],
                                             goto_top: [["g", []]],
                                             goto_bottom: [["G", [:shift]]],
                                             left: [[:left, []], ["h", [:alt]]],
                                             right: [[:right, []], ["l", [:alt]]],
                                           })
  end
end
