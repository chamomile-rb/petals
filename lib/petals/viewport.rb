# frozen_string_literal: true

module Petals
  # Scrollable content pane with key binding and mouse wheel support.
  class Viewport
    attr_reader :width, :height, :y_offset, :x_offset
    attr_accessor :key_map, :mouse_wheel_enabled, :mouse_wheel_delta, :soft_wrap

    def initialize(width: 80, height: 24, key_map: DEFAULT_KEY_MAP)
      @width = width
      @height = height
      @key_map = key_map
      @lines = []
      @y_offset = 0
      @x_offset = 0
      @mouse_wheel_enabled = true
      @mouse_wheel_delta = 3
      @soft_wrap = false
    end

    def width=(new_width)
      @width = new_width
      clamp_offset
      @x_offset = @x_offset.clamp(0, [max_horizontal_scroll, 0].max) unless @soft_wrap
    end

    # Backward compat alias
    alias set_width width=

    def height=(new_height)
      @height = new_height
      clamp_offset
    end

    # Backward compat alias
    alias set_height height=

    def content=(s)
      @lines = s.to_s.split("\n", -1)
      clamp_offset
      @x_offset = @x_offset.clamp(0, [max_horizontal_scroll, 0].max) unless @soft_wrap
      self
    end

    # Backward compat — preserves the return-self convention
    def set_content(s)
      self.content = s
      self
    end

    def content
      @lines.join("\n")
    end

    def total_line_count
      @soft_wrap ? wrapped_lines.length : @lines.length
    end

    def visible_line_count
      [total_line_count, @height].min
    end

    # Vertical scrolling

    def scroll_up(n = 1)
      self.y_offset = @y_offset - n
    end

    def scroll_down(n = 1)
      self.y_offset = @y_offset + n
    end

    def page_up
      scroll_up(@height)
    end

    def page_down
      scroll_down(@height)
    end

    def half_page_up
      scroll_up(@height / 2)
    end

    def half_page_down
      scroll_down(@height / 2)
    end

    def goto_top
      self.y_offset = 0
    end

    def goto_bottom
      self.y_offset = max_scroll
    end

    def y_offset=(n)
      @y_offset = n.clamp(0, max_scroll)
    end

    # Horizontal scrolling

    def scroll_left(n = 1)
      return if @soft_wrap

      self.x_offset = @x_offset - n
    end

    def scroll_right(n = 1)
      return if @soft_wrap

      self.x_offset = @x_offset + n
    end

    def x_offset=(n)
      return if @soft_wrap

      @x_offset = n.clamp(0, [max_horizontal_scroll, 0].max)
    end

    def max_horizontal_scroll
      return 0 if @lines.empty?

      longest = @lines.map(&:length).max || 0
      [longest - @width, 0].max
    end

    # Queries

    def at_top?
      @y_offset <= 0
    end

    def at_bottom?
      @y_offset >= max_scroll
    end

    def scroll_percent
      return 1.0 if max_scroll <= 0

      @y_offset.to_f / max_scroll
    end

    def ensure_visible(line)
      if line < @y_offset
        self.y_offset = line
      elsif line >= @y_offset + @height
        self.y_offset = line - @height + 1
      end
      self
    end

    # Handle an incoming event.
    def handle(msg)
      case msg
      when Chamomile::KeyEvent
        handle_key(msg)
      when Chamomile::MouseEvent
        handle_mouse(msg)
      end

      nil
    end

    # Backward compat alias
    alias update handle

    def view
      if @soft_wrap
        render_soft_wrap
      else
        render_normal
      end
    end

    private

    def max_scroll
      total = @soft_wrap ? wrapped_lines.length : @lines.length
      [total - @height, 0].max
    end

    def clamp_offset
      @y_offset = @y_offset.clamp(0, max_scroll)
    end

    def render_normal
      visible = @lines[@y_offset, @height] || []
      rendered = visible.map { |line| truncate_line(line) }
      padded = if rendered.length < @height
                 rendered + Array.new(@height - rendered.length, "")
               else
                 rendered
               end
      padded.join("\n")
    end

    def render_soft_wrap
      all = wrapped_lines
      visible = all[@y_offset, @height] || []
      padded = if visible.length < @height
                 visible + Array.new(@height - visible.length, "")
               else
                 visible
               end
      padded.join("\n")
    end

    def truncate_line(line)
      return "" if @width <= 0

      if @x_offset >= line.length
        ""
      else
        line[@x_offset, @width] || ""
      end
    end

    def wrapped_lines
      @lines.flat_map { |line| wrap_line(line) }
    end

    def wrap_line(line)
      return [""] if line.empty? || @width <= 0

      chunks = []
      pos = 0
      while pos < line.length
        chunks << line[pos, @width]
        pos += @width
      end
      chunks
    end

    def handle_key(msg)
      kb = KeyBinding
      if kb.key_matches?(msg, @key_map, :up)
        scroll_up
      elsif kb.key_matches?(msg, @key_map, :down)
        scroll_down
      elsif kb.key_matches?(msg, @key_map, :page_up)
        page_up
      elsif kb.key_matches?(msg, @key_map, :page_down)
        page_down
      elsif kb.key_matches?(msg, @key_map, :half_page_up)
        half_page_up
      elsif kb.key_matches?(msg, @key_map, :half_page_down)
        half_page_down
      elsif kb.key_matches?(msg, @key_map, :goto_top)
        goto_top
      elsif kb.key_matches?(msg, @key_map, :goto_bottom)
        goto_bottom
      elsif kb.key_matches?(msg, @key_map, :left)
        scroll_left
      elsif kb.key_matches?(msg, @key_map, :right)
        scroll_right
      end
    end

    def handle_mouse(msg)
      return unless @mouse_wheel_enabled

      case msg.button
      when :wheel_up
        scroll_up(@mouse_wheel_delta)
      when :wheel_down
        scroll_down(@mouse_wheel_delta)
      end
    end
  end
end
