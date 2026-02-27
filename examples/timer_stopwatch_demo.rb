#!/usr/bin/env ruby
# frozen_string_literal: true

# Interactive demo: 30s timer counting down + stopwatch counting up, side by side.
# Space toggles both, r resets both, q quits.

require_relative "../lib/chamomile/leaves"

class TimerStopwatchDemo
  include Chamomile::Model

  def initialize
    @timer = Chamomile::Leaves::Timer.new(timeout: 30, interval: 0.1)
    @stopwatch = Chamomile::Leaves::Stopwatch.new(interval: 0.1)
    @timed_out = false
  end

  def init
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
        return [self, Chamomile::Commands.quit]
      when " "
        timer_cmd = @timer.toggle
        sw_cmd = @stopwatch.toggle
        cmds = [timer_cmd, sw_cmd].compact
        return [self, cmds.empty? ? nil : Chamomile::Commands.batch(*cmds)]
      when "r"
        @timer.reset
        @stopwatch.reset
        @timed_out = false
        return [self, Chamomile::Commands.batch(@timer.start_cmd, @stopwatch.start_cmd)]
      end
    when Chamomile::Leaves::TimerTickMsg
      _, cmd = @timer.update(msg)
      return [self, cmd]
    when Chamomile::Leaves::TimerTimeoutMsg
      @timed_out = true
      return [self, nil]
    when Chamomile::Leaves::StopwatchTickMsg
      _, cmd = @stopwatch.update(msg)
      return [self, cmd]
    end

    [self, nil]
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
