# frozen_string_literal: true

module Petals
  SpinnerTickMsg = Data.define(:id, :tag, :time)

  # Animated spinner with configurable frame types and tick-based updates.
  class Spinner
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
        "#{@id_pid}-#{@next_id}"
      end
    end

    attr_reader :id, :spinner_type

    def initialize(type: Spinners::LINE)
      @id = self.class.next_id
      @spinner_type = type
      @frame = 0
      @tag = 0
    end

    # Returns a command that sleeps for the frame interval then produces a SpinnerTickMsg.
    def tick_cmd
      captured_id = @id
      captured_tag = @tag
      fps = @spinner_type.fps
      -> {
        sleep(1.0 / fps)
        SpinnerTickMsg.new(id: captured_id, tag: captured_tag, time: Time.now)
      }
    end

    # Advance frame if msg is a matching SpinnerTickMsg; return [self, cmd].
    def update(msg)
      return [self, nil] unless msg.is_a?(SpinnerTickMsg)
      return [self, nil] unless msg.id == @id && msg.tag == @tag

      @frame = (@frame + 1) % @spinner_type.frames.size
      @tag += 1
      [self, tick_cmd]
    end

    # Current frame string.
    def view
      @spinner_type.frames[@frame]
    end

    # Reset to first frame, invalidate in-flight ticks.
    def reset
      @frame = 0
      @tag += 1
      self
    end

    # Change spinner type, reset frame, invalidate in-flight ticks.
    def spinner_type=(type)
      @spinner_type = type
      @frame = 0
      @tag += 1
    end
  end
end
