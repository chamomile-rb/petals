# frozen_string_literal: true

module Petals
  # Multi-line text editor with cursor navigation, word wrapping, and line numbers.
  class TextArea
    attr_reader :row, :col
    attr_accessor :prompt, :placeholder, :char_limit, :width, :height,
                  :max_height, :max_width, :show_line_numbers, :key_map,
                  :end_of_buffer_char

    def initialize(width: 40, height: 6, key_map: DEFAULT_KEY_MAP,
                   prompt: "", placeholder: "", char_limit: 0,
                   show_line_numbers: false, end_of_buffer_char: "~")
      @width = width
      @height = height
      @key_map = key_map
      @prompt = prompt
      @placeholder = placeholder
      @char_limit = char_limit
      @show_line_numbers = show_line_numbers
      @end_of_buffer_char = end_of_buffer_char
      @max_height = 0
      @max_width = 0
      @lines = [""]
      @row = 0
      @col = 0
      @offset = 0
      @focused = false
      @last_char_offset = 0
    end

    def focus
      @focused = true
      self
    end

    def blur
      @focused = false
      self
    end

    def focused?
      @focused
    end

    def value
      @lines.join("\n")
    end

    def value=(s)
      s = s.to_s
      s = s[0, @char_limit] if @char_limit.positive? && s.length > @char_limit
      @lines = s.split("\n", -1)
      @lines = [""] if @lines.empty?
      @row = @row.clamp(0, @lines.length - 1)
      @col = @col.clamp(0, @lines[@row].length)
      @last_char_offset = @col
      clamp_offset
    end

    def line_count
      @lines.length
    end

    def length
      value.length
    end

    def display_height
      return @height unless @max_height.positive?

      [@lines.length, @height].max.clamp(@height, @max_height)
    end

    def cursor_up
      return if @row.zero?

      @row -= 1
      @col = [@last_char_offset, @lines[@row].length].min
      clamp_offset
    end

    def cursor_down
      return if @row >= @lines.length - 1

      @row += 1
      @col = [@last_char_offset, @lines[@row].length].min
      clamp_offset
    end

    def cursor_start
      @col = 0
      @last_char_offset = @col
    end

    def cursor_end
      @col = @lines[@row].length
      @last_char_offset = @col
    end

    def move_to_begin
      @row = 0
      @col = 0
      @last_char_offset = 0
      clamp_offset
    end

    def move_to_end
      @row = @lines.length - 1
      @col = @lines[@row].length
      @last_char_offset = @col
      clamp_offset
    end

    def page_up
      rows = display_height
      @row = [@row - rows, 0].max
      @col = [@last_char_offset, @lines[@row].length].min
      clamp_offset
    end

    def page_down
      rows = display_height
      @row = [@row + rows, @lines.length - 1].min
      @col = [@last_char_offset, @lines[@row].length].min
      clamp_offset
    end

    def word
      line = @lines[@row]
      return "" if line.empty? || @col >= line.length || line[@col] =~ /\s/

      left = @col
      left -= 1 while left.positive? && line[left - 1] =~ /\S/

      right = @col
      right += 1 while right < line.length && line[right] =~ /\S/

      line[left...right]
    end

    def insert_string(s)
      s.each_char do |c|
        if c == "\n"
          split_line
        else
          insert_rune(c)
        end
      end
    end

    def insert_rune(c)
      return if c == "\n"

      return if @char_limit.positive? && length >= @char_limit

      line = @lines[@row]
      @lines[@row] = line[0, @col].to_s + c + line[@col..].to_s
      @col += 1
      @last_char_offset = @col
    end

    def reset
      @lines = [""]
      @row = 0
      @col = 0
      @offset = 0
      @last_char_offset = 0
    end

    def update(msg)
      return unless @focused

      case msg
      when Chamomile::KeyMsg
        handle_key(msg)
      when Chamomile::PasteMsg
        handle_paste(msg)
      end

      nil
    end

    def view
      return "#{@prompt}#{@placeholder}" if @lines == [""] && !@placeholder.empty? && !@focused

      view_h = display_height
      visible_lines = @lines[@offset, view_h] || []
      rendered = visible_lines.each_with_index.map do |line, i|
        actual_row = @offset + i
        render_line(line, actual_row)
      end

      # Pad with end-of-buffer chars
      while rendered.length < view_h
        prefix = @show_line_numbers ? "#{" " * gutter_width} " : ""
        rendered << "#{@prompt}#{prefix}#{@end_of_buffer_char}"
      end

      rendered.join("\n")
    end

    private

    def handle_key(msg)
      handle_navigation_key(msg) || handle_editing_key(msg)
    end

    def handle_navigation_key(msg)
      kb = KeyBinding

      if kb.key_matches?(msg, @key_map, :input_begin)
        move_to_begin
      elsif kb.key_matches?(msg, @key_map, :input_end)
        move_to_end
      elsif kb.key_matches?(msg, @key_map, :page_up)
        page_up
      elsif kb.key_matches?(msg, @key_map, :page_down)
        page_down
      elsif kb.key_matches?(msg, @key_map, :line_up)
        cursor_up
      elsif kb.key_matches?(msg, @key_map, :line_down)
        cursor_down
      elsif kb.key_matches?(msg, @key_map, :line_start)
        cursor_start
      elsif kb.key_matches?(msg, @key_map, :line_end)
        cursor_end
      elsif kb.key_matches?(msg, @key_map, :character_forward)
        move_right
      elsif kb.key_matches?(msg, @key_map, :character_backward)
        move_left
      elsif kb.key_matches?(msg, @key_map, :word_forward)
        word_forward
      elsif kb.key_matches?(msg, @key_map, :word_backward)
        word_backward
      end
    end

    def handle_editing_key(msg)
      kb = KeyBinding

      if kb.key_matches?(msg, @key_map, :new_line)
        split_line
      elsif kb.key_matches?(msg, @key_map, :delete_char_backward)
        delete_char_backward
      elsif kb.key_matches?(msg, @key_map, :delete_char_forward)
        delete_char_forward
      elsif kb.key_matches?(msg, @key_map, :delete_word_backward)
        delete_word_backward
      elsif kb.key_matches?(msg, @key_map, :delete_word_forward)
        delete_word_forward
      elsif kb.key_matches?(msg, @key_map, :delete_before_cursor)
        delete_before_cursor
      elsif kb.key_matches?(msg, @key_map, :delete_after_cursor)
        delete_after_cursor
      elsif printable?(msg)
        insert_rune(msg.key)
      end
    end

    def handle_paste(msg)
      text = msg.content.gsub(/[^[:print:]\t\n]/, "")
      return if text.empty?

      paste_lines = text.split("\n", -1)
      paste_lines.each_with_index do |line, i|
        break if @char_limit.positive? && length >= @char_limit

        split_line if i.positive?

        line.each_char do |c|
          break if @char_limit.positive? && length >= @char_limit

          insert_rune(c)
        end
      end
    end

    def printable?(msg)
      return false unless msg.key.is_a?(String) && msg.key.length == 1
      return false unless msg.mod.empty? || msg.mod == [:shift]

      msg.key.match?(/[[:print:]]/)
    end

    def split_line
      return if @char_limit.positive? && length >= @char_limit

      line = @lines[@row]
      before = line[0, @col].to_s
      after = line[@col..].to_s
      @lines[@row] = before
      @lines.insert(@row + 1, after)
      @row += 1
      @col = 0
      @last_char_offset = 0
      clamp_offset
    end

    def move_right
      if @col < @lines[@row].length
        @col += 1
        @last_char_offset = @col
      elsif @row < @lines.length - 1
        @row += 1
        @col = 0
        @last_char_offset = 0
        clamp_offset
      end
    end

    def move_left
      if @col.positive?
        @col -= 1
        @last_char_offset = @col
      elsif @row.positive?
        @row -= 1
        @col = @lines[@row].length
        @last_char_offset = @col
        clamp_offset
      end
    end

    def word_forward
      line = @lines[@row]
      pos = @col
      # Skip current non-space chars
      pos += 1 while pos < line.length && line[pos] != " "
      # Skip spaces
      pos += 1 while pos < line.length && line[pos] == " "
      @col = pos
      @last_char_offset = @col
    end

    def word_backward
      line = @lines[@row]
      pos = @col
      # Skip spaces behind cursor
      pos -= 1 while pos.positive? && line[pos - 1] == " "
      # Skip non-space chars
      pos -= 1 while pos.positive? && line[pos - 1] != " "
      @col = pos
      @last_char_offset = @col
    end

    def delete_char_backward
      if @col.positive?
        line = @lines[@row]
        @lines[@row] = line[0, @col - 1].to_s + line[@col..].to_s
        @col -= 1
        @last_char_offset = @col
      elsif @row.positive?
        # Merge with previous line
        prev_len = @lines[@row - 1].length
        @lines[@row - 1] += @lines[@row]
        @lines.delete_at(@row)
        @row -= 1
        @col = prev_len
        @last_char_offset = @col
        clamp_offset
      end
    end

    def delete_char_forward
      line = @lines[@row]
      if @col < line.length
        @lines[@row] = line[0, @col].to_s + line[(@col + 1)..].to_s
      elsif @row < @lines.length - 1
        # Merge with next line
        @lines[@row] += @lines[@row + 1]
        @lines.delete_at(@row + 1)
      end
    end

    def delete_word_backward
      return if @col.zero?

      line = @lines[@row]
      target = @col
      # Skip spaces behind cursor
      target -= 1 while target.positive? && line[target - 1] == " "
      # Skip non-space chars
      target -= 1 while target.positive? && line[target - 1] != " "
      @lines[@row] = line[0, target].to_s + line[@col..].to_s
      @col = target
      @last_char_offset = @col
    end

    def delete_word_forward
      line = @lines[@row]
      return if @col >= line.length

      target = @col
      # Skip current non-space chars
      target += 1 while target < line.length && line[target] != " "
      # Skip spaces
      target += 1 while target < line.length && line[target] == " "
      @lines[@row] = line[0, @col].to_s + line[target..].to_s
    end

    def delete_before_cursor
      return if @col.zero?

      line = @lines[@row]
      @lines[@row] = line[@col..].to_s
      @col = 0
      @last_char_offset = 0
    end

    def delete_after_cursor
      line = @lines[@row]
      return if @col >= line.length

      @lines[@row] = line[0, @col].to_s
    end

    def clamp_offset
      view_h = display_height
      @offset = @row if @row < @offset
      @offset = @row - view_h + 1 if @row >= @offset + view_h
      @offset = [0, @offset].max
    end

    def render_line(line, actual_row)
      prefix = @show_line_numbers ? "#{(actual_row + 1).to_s.rjust(gutter_width)} " : ""

      if @focused && actual_row == @row
        render_cursor_line(line, prefix)
      else
        "#{@prompt}#{prefix}#{line}"
      end
    end

    def render_cursor_line(line, prefix)
      if @col < line.length
        before = line[0, @col]
        cursor_char = line[@col]
        after = line[(@col + 1)..]
        "#{@prompt}#{prefix}#{before}\e[7m#{cursor_char}\e[0m#{after}"
      else
        "#{@prompt}#{prefix}#{line}\e[7m \e[0m"
      end
    end

    def gutter_width
      @lines.length.to_s.length
    end
  end
end
