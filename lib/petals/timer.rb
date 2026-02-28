# frozen_string_literal: true

module Petals
  TimerTickMsg = Data.define(:id, :tag, :time)
  TimerTimeoutMsg = Data.define(:id, :time)

  # Countdown timer with timeout notification and tick-based updates.
  class Timer
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
        "#{@id_pid}-tm-#{@next_id}"
      end
    end

    attr_reader :id, :timeout, :interval, :remaining

    def initialize(timeout:, interval: 1.0)
      @id = self.class.next_id
      @timeout = timeout.to_f
      @interval = interval
      @remaining = @timeout
      @tag = 0
      @running = false
    end

    def start_cmd
      return nil if @running || timed_out?

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
      @remaining = @timeout
      @running = false
      @tag += 1
      self
    end

    def running?
      @running
    end

    def timed_out?
      @remaining <= 0
    end

    def update(msg)
      case msg
      when TimerTickMsg
        return unless msg.id == @id && msg.tag == @tag

        @remaining = [(@remaining - @interval), 0.0].max
        @tag += 1

        if @remaining <= 0
          @running = false
          timeout_cmd
        else
          tick_cmd
        end
      end
    end

    def view
      total = @remaining.ceil.to_i
      total = 0 if total.negative?
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
        TimerTickMsg.new(id: captured_id, tag: captured_tag, time: Time.now)
      }
    end

    # Returns a command that produces TimerTimeoutMsg (no sleep — immediate).
    def timeout_cmd
      captured_id = @id
      -> { TimerTimeoutMsg.new(id: captured_id, time: Time.now) }
    end
  end
end
