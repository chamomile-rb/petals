#!/usr/bin/env ruby
# frozen_string_literal: true

# Headless smoke test — exercises each example's model without a terminal.

require_relative "../lib/chamomile/leaves"

def key(k, mod: []) = Chamomile::KeyMsg.new(key: k, mod: mod)
def paste(text) = Chamomile::PasteMsg.new(content: text)
def tick = Chamomile::TickMsg.new(time: Time.now)

def run_model(model, messages, label:)
  puts "=== #{label} ==="

  # init
  init_cmd = model.init
  puts "init cmd: #{init_cmd ? "present" : "nil"}"

  # If spinner tick_cmd, execute it (stub sleep)
  if init_cmd
    allow_sleep = Thread.new do
      init_cmd.call
    rescue StandardError
      nil
    end
    allow_sleep.kill
  end

  puts "Initial view:"
  puts model.view
  puts "---"

  messages.each_with_index do |(msg, desc), _i|
    _, cmd = model.update(msg)
    puts "After #{desc}: cmd=#{cmd ? "present" : "nil"}"
    puts model.view
    puts "---"
  end
  puts
end

# ---- Spinner Demo ----
require_relative "spinner_demo"

spinner_demo = SpinnerDemo.new

# Simulate: render initial, send SpinnerTickMsg to advance, press down to change type
spinner = spinner_demo.instance_variable_get(:@spinner)
tick_msg = Chamomile::Leaves::SpinnerTickMsg.new(id: spinner.id, tag: 0, time: Time.now)

run_model(spinner_demo, [
            [tick_msg, "spinner tick"],
            [key(:down), "down arrow (next type)"],
          ], label: "Spinner Demo")

# ---- TextInput Demo ----
require_relative "text_input_demo"

ti_demo = TextInputDemo.new
run_model(ti_demo, [
            [key("H"), "type H"],
            [key("e"), "type e"],
            [key("l"), "type l"],
            [key("l"), "type l"],
            [key("o"), "type o"],
            [key(:left), "left arrow"],
            [key(:left), "left arrow"],
            [key(:backspace), "backspace"],
            [key("L"), "type L"],
            [key(:end_key), "end key"],
            [key(:enter), "enter (submit)"],
          ], label: "TextInput Demo")

# ---- Combined Demo ----
require_relative "combined_demo"

combined = CombinedDemo.new
combined_spinner = combined.instance_variable_get(:@spinner)
combined_tick = Chamomile::Leaves::SpinnerTickMsg.new(
  id: combined_spinner.id, tag: 0, time: Time.now
)

run_model(combined, [
            [combined_tick, "spinner tick"],
            [key("H"), "type H"],
            [key("i"), "type i"],
            [key("!"), "type !"],
            [key(:enter), "enter (send)"],
            [key("W"), "type W"],
            [key("o"), "type o"],
            [key("w"), "type w"],
            [key(:enter), "enter (send)"],
          ], label: "Combined Demo")

# ---- Stopwatch ----
puts "=== Stopwatch ==="
sw = Chamomile::Leaves::Stopwatch.new(interval: 1.0)
puts "Initial view: #{sw.view}"
sw.start_cmd
puts "Running: #{sw.running?}"
# Simulate a tick
tick_msg = Chamomile::Leaves::StopwatchTickMsg.new(id: sw.id, tag: sw.instance_variable_get(:@tag), time: Time.now)
sw.update(tick_msg)
puts "After 1 tick: #{sw.view} (elapsed=#{sw.elapsed})"
sw.stop
puts "Stopped: #{!sw.running?}"
sw.reset
puts "After reset: #{sw.view}"
puts

# ---- Timer ----
puts "=== Timer ==="
timer = Chamomile::Leaves::Timer.new(timeout: 5, interval: 1.0)
puts "Initial view: #{timer.view}"
timer.start_cmd
puts "Running: #{timer.running?}"
# Simulate ticks
4.times do
  tick_msg = Chamomile::Leaves::TimerTickMsg.new(id: timer.id, tag: timer.instance_variable_get(:@tag), time: Time.now)
  timer.update(tick_msg)
  puts "Tick: #{timer.view} (remaining=#{timer.remaining})"
end
# Final tick should produce timeout
tick_msg = Chamomile::Leaves::TimerTickMsg.new(id: timer.id, tag: timer.instance_variable_get(:@tag), time: Time.now)
timer.update(tick_msg)
puts "Timed out: #{timer.timed_out?}, view: #{timer.view}"
timer.reset
puts "After reset: #{timer.view}, timed_out: #{timer.timed_out?}"
puts

# ---- Paginator ----
puts "=== Paginator ==="
pag = Chamomile::Leaves::Paginator.new(total_pages: 4, per_page: 5)
puts "Initial view: #{pag.view}"
pag.next_page
puts "After next: #{pag.view} (page=#{pag.page})"
pag.next_page
puts "After next: #{pag.view} (page=#{pag.page})"
pag.prev_page
puts "After prev: #{pag.view} (page=#{pag.page})"
pag.type = Chamomile::Leaves::Paginator::TYPE_ARABIC
puts "Arabic view: #{pag.view}"
pag.update(key(:right))
puts "After right key: #{pag.view}"
puts "Slice bounds (13 items): #{pag.slice_bounds(13).inspect}"
puts "First page: #{pag.on_first_page?}, Last page: #{pag.on_last_page?}"
puts

# ---- Timer & Stopwatch Demo Model ----
require_relative "timer_stopwatch_demo"

ts_demo = TimerStopwatchDemo.new
ts_timer = ts_demo.instance_variable_get(:@timer)
ts_sw = ts_demo.instance_variable_get(:@stopwatch)

# Fake init without sleeping
ts_demo.init

puts "=== Timer & Stopwatch Demo ==="
puts "Initial view:"
puts ts_demo.view
puts "---"

# Simulate timer tick
timer_tick = Chamomile::Leaves::TimerTickMsg.new(
  id: ts_timer.id, tag: ts_timer.instance_variable_get(:@tag), time: Time.now
)
ts_demo.update(timer_tick)
puts "After timer tick:"
puts ts_demo.view
puts "---"

# Simulate stopwatch tick
sw_tick = Chamomile::Leaves::StopwatchTickMsg.new(
  id: ts_sw.id, tag: ts_sw.instance_variable_get(:@tag), time: Time.now
)
ts_demo.update(sw_tick)
puts "After stopwatch tick:"
puts ts_demo.view
puts "---"

# Reset
ts_demo.update(key("r"))
puts "After reset:"
puts ts_demo.view
puts

puts "All smoke tests passed!"
