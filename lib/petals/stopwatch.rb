# frozen_string_literal: true

module Petals
  StopwatchTickMsg = Data.define(:id, :tag, :time)

  # Count-up stopwatch with start/stop/reset and tick-based updates.
  class Stopwatch
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
        "#{@id_pid}-sw-#{@next_id}"
      end
    end

    attr_reader :id, :interval, :elapsed

    def initialize(interval: 1.0)
      @id = self.class.next_id
      @interval = interval
      @elapsed = 0.0
      @tag = 0
      @running = false
    end

    def start_cmd
      return nil if @running

      @running = true
      tick_cmd
    end

    def stop
      @running = false
      @tag += 1
      self
    end

    def toggle
      if @running
        stop
        nil
      else
        start_cmd
      end
    end

    def reset
      @elapsed = 0.0
      @running = false
      @tag += 1
      self
    end

    def running?
      @running
    end

    def update(msg)
      return [self, nil] unless msg.is_a?(StopwatchTickMsg)
      return [self, nil] unless msg.id == @id && msg.tag == @tag

      @elapsed += @interval
      @tag += 1
      [self, tick_cmd]
    end

    def view
      total = @elapsed.ceil.to_i
      hours = total / 3600
      minutes = (total % 3600) / 60
      seconds = total % 60

      if hours.positive?
        format("%d:%02d:%02d", hours, minutes, seconds)
      else
        format("%02d:%02d", minutes, seconds)
      end
    end

    private

    def tick_cmd
      captured_id = @id
      captured_tag = @tag
      interval = @interval
      -> {
        sleep(interval)
        StopwatchTickMsg.new(id: captured_id, tag: captured_tag, time: Time.now)
      }
    end
  end
end
