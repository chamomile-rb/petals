# frozen_string_literal: true

module Petals
  CursorBlinkMsg = Data.define(:id, :tag)

  # Virtual text cursor with blink modes (blink, static, hide).
  class Cursor
    MODE_BLINK  = :blink
    MODE_STATIC = :static
    MODE_HIDE   = :hide

    BLINK_SPEED = 0.53

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
        "#{@id_pid}-cur-#{@next_id}"
      end
    end

    attr_reader :id, :mode, :blink_speed
    attr_accessor :char, :blinked

    def initialize(mode: MODE_BLINK, blink_speed: BLINK_SPEED)
      @id = self.class.next_id
      @mode = mode
      @blink_speed = blink_speed
      @char = " "
      @blinked = false
      @focused = false
      @tag = 0
    end

    def focus
      @focused = true
      @blinked = false
      @mode == MODE_BLINK ? blink_cmd : nil
    end

    def blur
      @focused = false
      @blinked = true
      @tag += 1
      nil
    end

    def focused?
      @focused
    end

    def mode=(new_mode)
      @mode = new_mode
      @tag += 1
      @blinked = new_mode == MODE_HIDE || !@focused
      @mode == MODE_BLINK && @focused ? blink_cmd : nil
    end

    def blink_cmd
      captured_id = @id
      captured_tag = @tag
      speed = @blink_speed
      -> {
        sleep(speed)
        CursorBlinkMsg.new(id: captured_id, tag: captured_tag)
      }
    end

    def handle(msg)
      return unless msg.is_a?(CursorBlinkMsg)
      return unless @mode == MODE_BLINK && @focused
      return unless msg.id == @id && msg.tag == @tag

      @blinked = !@blinked
      @tag += 1
      blink_cmd
    end

    alias update handle

    def view
      return @char if @mode == MODE_HIDE
      return @char if @blinked

      "\e[7m#{@char}\e[0m"
    end
  end
end
