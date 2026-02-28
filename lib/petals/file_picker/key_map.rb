# frozen_string_literal: true

module Petals
  class FilePicker
    DEFAULT_KEY_MAP = KeyBinding.normalize({
                                             up: [[:up, []], ["k", []]],
                                             down: [[:down, []], ["j", []]],
                                             open: [[:right, []], ["l", []], [:enter, []]],
                                             back: [[:left, []], ["h", []], [:backspace, []]],
                                             toggle_hidden: [[".", []]],
                                             page_up: [[:page_up, []], ["b", [:ctrl]]],
                                             page_down: [[:page_down, []], ["f", [:ctrl]]],
                                             goto_top: [["g", []], [:home, []]],
                                             goto_bottom: [["G", [:shift]], [:end_key, []]],
                                           })
  end
end
