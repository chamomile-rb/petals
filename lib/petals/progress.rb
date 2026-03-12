# frozen_string_literal: true

module Petals
  ProgressFrameMsg = Data.define(:id, :tag)

  # Animated progress bar with spring-based animation and optional gradient.
  class Progress
    DEFAULT_WIDTH = 40
    FULL_CHAR  = "\u2588"
    EMPTY_CHAR = "\u2591"

    # Spring constants
    FREQUENCY = 14.0
    DAMPING   = 2.2
    EPSILON   = 0.001
    FPS       = 60

    @next_id = 0
    @id_mutex = Mutex.new
    @id_pid = Process.pid

    def self.next_id
      @id_mutex.synchronize do
        if Process.pid != @id_pid
          @id_pid = Process.pid
          @next_id = 0
          @id_mutex = Mutex.new
        end
        @next_id += 1
        "#{@id_pid}-pg-#{@next_id}"
      end
    end

    attr_reader :id, :percent, :frequency, :damping
    attr_accessor :width, :full_char, :empty_char, :show_percentage,
                  :percentage_format, :full_color, :empty_color, :gradient

    def initialize(width: DEFAULT_WIDTH, show_percentage: true, percentage_format: " %3.0f%%",
                   full_char: FULL_CHAR, empty_char: EMPTY_CHAR,
                   full_color: nil, empty_color: nil, gradient: nil,
                   frequency: FREQUENCY, damping: DAMPING)
      @id = self.class.next_id
      @width = width
      @full_char = full_char
      @empty_char = empty_char
      @show_percentage = show_percentage
      @percentage_format = percentage_format
      @full_color = full_color
      @empty_color = empty_color
      @gradient = gradient
      @frequency = frequency.to_f
      @damping = damping.to_f
      @percent = 0.0
      @target = 0.0
      @velocity = 0.0
      @tag = 0
      @animating = false
    end

    def set_percent(p)
      @target = p.to_f.clamp(0.0, 1.0)
      start_animation
    end

    def incr_percent(v)
      set_percent(@target + v)
    end

    def decr_percent(v)
      set_percent(@target - v)
    end

    def set_spring_options(frequency, damping)
      @frequency = frequency.to_f
      @damping = damping.to_f
    end

    def animating?
      @animating
    end

    def handle(msg)
      return unless msg.is_a?(ProgressFrameMsg)
      return unless msg.id == @id && msg.tag == @tag

      dt = 1.0 / FPS
      force = (@target - @percent) * @frequency
      @velocity = (@velocity + (force * dt)) * (1.0 / (1.0 + (@damping * dt)))
      @percent += @velocity * dt
      @percent = @percent.clamp(0.0, 1.0)

      if (@percent - @target).abs < EPSILON && @velocity.abs < EPSILON
        @percent = @target
        @velocity = 0.0
        @animating = false
        @tag += 1
        nil
      else
        @tag += 1
        frame_cmd
      end
    end

    alias update handle

    def view
      render_bar(@percent)
    end

    def view_as(percent)
      render_bar(percent.to_f.clamp(0.0, 1.0))
    end

    private

    def start_animation
      @tag += 1
      if @animating
        @velocity = 0.0
        return frame_cmd
      end

      @animating = true
      frame_cmd
    end

    def frame_cmd
      captured_id = @id
      captured_tag = @tag
      -> {
        sleep(1.0 / FPS)
        ProgressFrameMsg.new(id: captured_id, tag: captured_tag)
      }
    end

    def render_bar(pct)
      pct_text = @show_percentage ? format(@percentage_format, pct * 100) : ""
      bar_width = [@width - pct_text.length, 0].max

      filled_width = (pct * bar_width).round
      empty_width = bar_width - filled_width

      bar = if @gradient && @gradient.length >= 2
              render_gradient_bar(pct, filled_width, empty_width)
            elsif @full_color || @empty_color
              render_colored_bar(filled_width, empty_width)
            else
              (@full_char * filled_width) + (@empty_char * empty_width)
            end

      bar + pct_text
    end

    def render_colored_bar(filled_width, empty_width)
      result = ""
      if @full_color && filled_width.positive?
        r, g, b = @full_color
        result += "\e[38;2;#{r};#{g};#{b}m#{@full_char * filled_width}\e[0m"
      else
        result += @full_char * filled_width
      end
      if @empty_color && empty_width.positive?
        r, g, b = @empty_color
        result += "\e[38;2;#{r};#{g};#{b}m#{@empty_char * empty_width}\e[0m"
      else
        result += @empty_char * empty_width
      end
      result
    end

    def render_gradient_bar(_pct, filled_width, empty_width)
      return @empty_char * @width if filled_width.zero?

      chars = filled_width.times.map do |i|
        t = filled_width > 1 ? i.to_f / (filled_width - 1) : 0.0
        r, g, b = lerp_color(t)
        "\e[38;2;#{r};#{g};#{b}m#{@full_char}\e[0m"
      end
      chars.join + (@empty_char * empty_width)
    end

    def lerp_color(t)
      colors = @gradient
      return colors[0] if t <= 0.0
      return colors[-1] if t >= 1.0

      scaled = t * (colors.length - 1)
      idx = scaled.floor
      idx = [idx, colors.length - 2].min
      frac = scaled - idx

      c1 = colors[idx]
      c2 = colors[idx + 1]
      [
        (c1[0] + ((c2[0] - c1[0]) * frac)).round,
        (c1[1] + ((c2[1] - c1[1]) * frac)).round,
        (c1[2] + ((c2[2] - c1[2]) * frac)).round,
      ]
    end
  end
end
