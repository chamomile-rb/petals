# frozen_string_literal: true

module Petals
  # A scrollable log view with auto-scroll and SQL/error highlighting.
  # Designed for streaming log panels.
  #
  # Usage:
  #   @log_view = Petals::LogView.new(max_lines: 1000)
  #   @log_view.push("GET /users 200 10ms")
  #   @log_view.push("SELECT * FROM users")
  #   rendered = @log_view.render(width: 80, height: 20)
  class LogView
    SQL_PATTERN     = /\b(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)\b/i
    ERROR_PATTERN   = /(Error|Exception|FATAL|Errno)/
    REQUEST_PATTERN = %r{\b(GET|POST|PUT|PATCH|DELETE)\s+/}

    SQL_COLOR     = "\e[38;5;33m"
    ERROR_COLOR   = "\e[38;5;196m"
    REQUEST_COLOR = "\e[38;5;34m"
    DIM_COLOR     = "\e[38;5;240m"
    RESET         = "\e[0m"

    attr_reader :paused, :line_count

    def initialize(max_lines: 1000)
      @lines         = []
      @max_lines     = max_lines
      @scroll_offset = 0
      @paused        = false
      @line_count    = 0
      @mutex         = Mutex.new
    end

    # Thread-safe line push. Called from stream command threads.
    def push(line)
      @mutex.synchronize do
        return if @paused

        @lines << highlight(line.chomp)
        @lines.shift if @lines.size > @max_lines
        @line_count += 1
        @scroll_offset += 1 if @scroll_offset.positive?
      end
    end

    def pause!  = (@paused = true)
    def resume! = (@paused = false)

    def scroll_up(n = 1)
      @mutex.synchronize do
        @scroll_offset = (@scroll_offset + n).clamp(0, [@lines.size - 1, 0].max)
      end
    end

    def scroll_down(n = 1)
      @mutex.synchronize do
        @scroll_offset = [@scroll_offset - n, 0].max
      end
    end

    def scroll_to_bottom
      @mutex.synchronize { @scroll_offset = 0 }
    end

    def at_bottom? = @scroll_offset.zero?

    def render(width:, height:)
      @mutex.synchronize do
        return "" if height <= 0

        # Clamp scroll so we can't scroll past showing the first lines
        max_scroll = [@lines.size - height, 0].max
        effective_offset = [@scroll_offset, max_scroll].min

        visible = if effective_offset.zero?
                    @lines.last(height)
                  else
                    bottom_idx = @lines.size - effective_offset
                    start_idx  = [bottom_idx - height, 0].max
                    @lines[start_idx...bottom_idx] || []
                  end

        padded = visible.map { |l| truncate_ansi(l, width) }
        padded.fill("", padded.size...height)

        if effective_offset.positive? && height > 1
          status = " #{DIM_COLOR}↑ #{effective_offset} newer lines below (G to jump to bottom)#{RESET} "
          padded[-1] = status
        end

        padded.join("\n")
      end
    end

    def clear
      @mutex.synchronize do
        @lines.clear
        @scroll_offset = 0
        @line_count = 0
      end
    end

    private

    def highlight(line)
      case line
      when ERROR_PATTERN   then "#{ERROR_COLOR}#{line}#{RESET}"
      when SQL_PATTERN     then "#{SQL_COLOR}#{line}#{RESET}"
      when REQUEST_PATTERN then "#{REQUEST_COLOR}#{line}#{RESET}"
      else line
      end
    end

    def truncate_ansi(str, width)
      visible = 0
      result  = +""
      i       = 0
      in_escape = false
      has_escape = false
      while i < str.length
        char = str[i]
        if in_escape
          result << char
          in_escape = false if char == "m"
        elsif char == "\e"
          in_escape = true
          has_escape = true
          result << char
        else
          break if visible >= width

          result << char
          visible += 1
        end
        i += 1
      end
      result << RESET if has_escape
      result
    end
  end
end
