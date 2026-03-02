#!/usr/bin/env ruby
# frozen_string_literal: true

# Interactive demo: 30s timer counting down + stopwatch counting up, side by side.
# Space toggles both, r resets both, q quits.

require_relative "../lib/petals"

class TimerStopwatchDemo
  include Chamomile::Model

  def initialize
    @timer = Petals::Timer.new(timeout: 30, interval: 0.1)
    @stopwatch = Petals::Stopwatch.new(interval: 0.1)
    @timed_out = false
  end

  def start
    Chamomile::Commands.batch(
      @timer.start_cmd,
      @stopwatch.start_cmd
    )
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      case msg.key
      when "q"
        return Chamomile::Commands.quit
      when " "
        timer_cmd = @timer.toggle
        sw_cmd = @stopwatch.toggle
        cmds = [timer_cmd, sw_cmd].compact
        return cmds.empty? ? nil : Chamomile::Commands.batch(*cmds)
      when "r"
        @timer.reset
        @stopwatch.reset
        @timed_out = false
        return Chamomile::Commands.batch(@timer.start_cmd, @stopwatch.start_cmd)
      end
    when Petals::TimerTickMsg
      return @timer.update(msg)
    when Petals::TimerTimeoutMsg
      @timed_out = true
      return nil
    when Petals::StopwatchTickMsg
      return @stopwatch.update(msg)
    end

    nil
  end

  def view
    lines = []
    lines << "Timer & Stopwatch Demo"
    lines << ""
    lines << "  Timer:     #{@timer.view}#{"  Time's up!" if @timed_out}"
    lines << "  Stopwatch: #{@stopwatch.view}"
    lines << ""
    lines << "  space: toggle  r: reset  q: quit"
    lines.join("\n")
  end
end

if __FILE__ == $PROGRAM_NAME
  model = TimerStopwatchDemo.new
  program = Chamomile::Program.new(model, alt_screen: true)
  program.run
end
