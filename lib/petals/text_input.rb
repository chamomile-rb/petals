# frozen_string_literal: true

module Petals
  # Single-line text input with cursor movement, editing, and echo modes.
  class TextInput
    ECHO_NORMAL   = :normal
    ECHO_PASSWORD = :password
    ECHO_NONE     = :none

    attr_reader :value, :position, :err, :echo_char
    attr_accessor :prompt, :placeholder, :char_limit, :width,
                  :echo_mode, :key_map

    def initialize(prompt: "", placeholder: "", char_limit: 0, width: 0,
                   echo_mode: ECHO_NORMAL, echo_char: "*", key_map: DEFAULT_KEY_MAP,
                   validate: nil)
      @prompt = prompt
      @placeholder = placeholder
      @char_limit = char_limit
      @width = width
      @echo_mode = echo_mode
      self.echo_char = echo_char
      @key_map = key_map
      @validate = validate
      @value = ""
      @position = 0
      @focused = false
      @offset = 0
      @err = nil
    end

    # Focus management

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

    def echo_char=(c)
      @echo_char = c.to_s[0] || "*"
    end

    # Value access

    def value=(v)
      v = v.to_s
      v = v[0, @char_limit] if @char_limit.positive? && v.length > @char_limit
      @value = v
      @position = @position.clamp(0, @value.length)
      run_validate
      recalc_offset
    end

    def position=(p)
      @position = p.clamp(0, @value.length)
      recalc_offset
    end

    # Handle an incoming event. Primary API — replaces the old `update` name.
    def handle(msg)
      return unless @focused

      case msg
      when Chamomile::KeyEvent
        handle_key(msg)
      when Chamomile::PasteEvent
        handle_paste(msg)
      end

      nil
    end

    # Backward compat alias
    alias update handle

    def view
      return "#{@prompt}#{@placeholder}" if @value.empty? && !@placeholder.empty? && !@focused

      display = build_display_value
      visible = visible_portion(display)

      if @focused
        cursor_pos = @position - @offset
        if cursor_pos >= 0 && cursor_pos < visible.length
          before = visible[0, cursor_pos]
          cursor_char = visible[cursor_pos]
          after = visible[(cursor_pos + 1)..]
          "#{@prompt}#{before}\e[7m#{cursor_char}\e[0m#{after}"
        else
          # Cursor at end
          "#{@prompt}#{visible}\e[7m \e[0m"
        end
      else
        "#{@prompt}#{visible}"
      end
    end

    private

    def handle_key(msg)
      kb = KeyBinding

      if kb.key_matches?(msg, @key_map, :line_start)
        @position = 0
      elsif kb.key_matches?(msg, @key_map, :line_end)
        @position = @value.length
      elsif kb.key_matches?(msg, @key_map, :character_forward)
        @position += 1 if @position < @value.length
      elsif kb.key_matches?(msg, @key_map, :character_backward)
        @position -= 1 if @position.positive?
      elsif kb.key_matches?(msg, @key_map, :word_forward)
        @position = next_word_boundary
      elsif kb.key_matches?(msg, @key_map, :word_backward)
        @position = prev_word_boundary
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
        insert_char(msg.key)
      end

      recalc_offset
    end

    def handle_paste(msg)
      text = msg.content.gsub(/[^[:print:]\t]/, "")
      return if text.empty?

      if @char_limit.positive?
        available = @char_limit - @value.length
        return if available <= 0

        text = text[0, available] if text.length > available
      end

      @value = @value[0, @position].to_s + text + @value[@position..].to_s
      @position += text.length
      run_validate
      recalc_offset
    end

    def printable?(msg)
      return false unless msg.key.is_a?(String) && msg.key.length == 1
      return false unless msg.mod.empty? || msg.mod == [:shift]

      msg.key.match?(/[[:print:]]/)
    end

    def insert_char(char)
      return if @char_limit.positive? && @value.length >= @char_limit

      @value = @value[0, @position].to_s + char + @value[@position..].to_s
      @position += 1
      run_validate
    end

    # Deletion operations

    def delete_char_backward
      return if @position.zero?

      @value = @value[0, @position - 1].to_s + @value[@position..].to_s
      @position -= 1
      run_validate
    end

    def delete_char_forward
      return if @position >= @value.length

      @value = @value[0, @position].to_s + @value[(@position + 1)..].to_s
      run_validate
    end

    def delete_word_backward
      return if @position.zero?

      target = prev_word_boundary
      @value = @value[0, target].to_s + @value[@position..].to_s
      @position = target
      run_validate
    end

    def delete_word_forward
      return if @position >= @value.length

      target = next_word_boundary
      @value = @value[0, @position].to_s + @value[target..].to_s
      run_validate
    end

    def delete_before_cursor
      return if @position.zero?

      @value = @value[@position..].to_s
      @position = 0
      run_validate
    end

    def delete_after_cursor
      return if @position >= @value.length

      @value = @value[0, @position].to_s
      run_validate
    end

    # Word boundary helpers — whitespace-delimited.
    # In password/none mode, word ops jump to start/end.

    def next_word_boundary
      return @value.length if @echo_mode != ECHO_NORMAL

      pos = @position
      # Skip current non-space chars
      pos += 1 while pos < @value.length && @value[pos] != " "
      # Skip spaces
      pos += 1 while pos < @value.length && @value[pos] == " "
      pos
    end

    def prev_word_boundary
      return 0 if @echo_mode != ECHO_NORMAL

      pos = @position
      # Skip spaces behind cursor
      pos -= 1 while pos.positive? && @value[pos - 1] == " "
      # Skip non-space chars
      pos -= 1 while pos.positive? && @value[pos - 1] != " "
      pos
    end

    # Horizontal scrolling

    def recalc_offset
      if @width.positive?
        content_width = @width - @prompt.length
        content_width = 1 if content_width < 1

        @offset = @position if @position < @offset
        @offset = @position - content_width + 1 if @position >= @offset + content_width
        @offset = 0 if @offset.negative?
      else
        @offset = 0
      end
    end

    def visible_portion(display)
      if @width.positive?
        content_width = @width - @prompt.length
        content_width = 1 if content_width < 1
        display[@offset, content_width] || ""
      else
        display
      end
    end

    # Display value based on echo mode

    def build_display_value
      case @echo_mode
      when ECHO_PASSWORD
        @echo_char * @value.length
      when ECHO_NONE
        ""
      else
        @value
      end
    end

    # Validation

    def run_validate
      @err = @validate&.call(@value)
    end
  end
end
