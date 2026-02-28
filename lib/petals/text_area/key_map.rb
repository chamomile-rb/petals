# frozen_string_literal: true

module Petals
  class TextArea
    DEFAULT_KEY_MAP = KeyBinding.normalize({
                                             character_forward: [[:right, []], ["f", [:ctrl]]],
                                             character_backward: [[:left, []], ["b", [:ctrl]]],
                                             word_forward: [[:right, [:alt]], [:right, [:ctrl]], ["f", [:alt]]],
                                             word_backward: [[:left, [:alt]], [:left, [:ctrl]], ["b", [:alt]]],
                                             delete_word_backward: [[:backspace, [:alt]], ["w", [:ctrl]]],
                                             delete_word_forward: [[:delete, [:alt]], ["d", [:alt]]],
                                             delete_after_cursor: [["k", [:ctrl]]],
                                             delete_before_cursor: [["u", [:ctrl]]],
                                             delete_char_backward: [[:backspace, []], ["h", [:ctrl]]],
                                             delete_char_forward: [[:delete, []], ["d", [:ctrl]]],
                                             line_start: [[:home, []], ["a", [:ctrl]]],
                                             line_end: [[:end_key, []], ["e", [:ctrl]]],
                                             line_up: [[:up, []]],
                                             line_down: [[:down, []]],
                                             new_line: [[:enter, []]],
                                             input_begin: [[:home, [:ctrl]]],
                                             input_end: [[:end_key, [:ctrl]]],
                                             page_up: [[:page_up, []]],
                                             page_down: [[:page_down, []]],
                                           })
  end
end
