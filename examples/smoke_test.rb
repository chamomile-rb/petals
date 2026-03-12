#!/usr/bin/env ruby
# frozen_string_literal: true

# Headless smoke test — exercises each example's model without a terminal.

require_relative "../lib/petals"

def key(k, mod: []) = Chamomile::KeyEvent.new(key: k, mod: mod)
def paste(text) = Chamomile::PasteEvent.new(content: text)
def tick = Chamomile::TickEvent.new(time: Time.now)

def run_model(model, messages, label:)
  puts "=== #{label} ==="

  # start
  start_cmd = model.start
  puts "start cmd: #{start_cmd ? "present" : "nil"}"

  # If spinner tick_cmd, execute it (stub sleep)
  if start_cmd
    allow_sleep = Thread.new do
      start_cmd.call
    rescue StandardError
      nil
    end
    allow_sleep.kill
  end

  puts "Initial view:"
  puts model.view
  puts "---"

  messages.each_with_index do |(msg, desc), _i|
    cmd = model.update(msg)
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
tick_msg = Petals::SpinnerTickMsg.new(id: spinner.id, tag: 0, time: Time.now)

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
combined_tick = Petals::SpinnerTickMsg.new(
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
sw = Petals::Stopwatch.new(interval: 1.0)
puts "Initial view: #{sw.view}"
sw.start_cmd
puts "Running: #{sw.running?}"
# Simulate a tick
tick_msg = Petals::StopwatchTickMsg.new(id: sw.id, tag: sw.instance_variable_get(:@tag), time: Time.now)
sw.handle(tick_msg)
puts "After 1 tick: #{sw.view} (elapsed=#{sw.elapsed})"
sw.stop
puts "Stopped: #{!sw.running?}"
sw.reset
puts "After reset: #{sw.view}"
puts

# ---- Timer ----
puts "=== Timer ==="
timer = Petals::Timer.new(timeout: 5, interval: 1.0)
puts "Initial view: #{timer.view}"
timer.start_cmd
puts "Running: #{timer.running?}"
# Simulate ticks
4.times do
  tick_msg = Petals::TimerTickMsg.new(id: timer.id, tag: timer.instance_variable_get(:@tag), time: Time.now)
  timer.handle(tick_msg)
  puts "Tick: #{timer.view} (remaining=#{timer.remaining})"
end
# Final tick should produce timeout
tick_msg = Petals::TimerTickMsg.new(id: timer.id, tag: timer.instance_variable_get(:@tag), time: Time.now)
timer.handle(tick_msg)
puts "Timed out: #{timer.timed_out?}, view: #{timer.view}"
timer.reset
puts "After reset: #{timer.view}, timed_out: #{timer.timed_out?}"
puts

# ---- Paginator ----
puts "=== Paginator ==="
pag = Petals::Paginator.new(total_pages: 4, per_page: 5)
puts "Initial view: #{pag.view}"
pag.next_page
puts "After next: #{pag.view} (page=#{pag.page})"
pag.next_page
puts "After next: #{pag.view} (page=#{pag.page})"
pag.prev_page
puts "After prev: #{pag.view} (page=#{pag.page})"
pag.type = Petals::Paginator::TYPE_ARABIC
puts "Arabic view: #{pag.view}"
pag.handle(key(:right))
puts "After right key: #{pag.view}"
puts "Slice bounds (13 items): #{pag.slice_bounds(13).inspect}"
puts "First page: #{pag.on_first_page?}, Last page: #{pag.on_last_page?}"
puts

# ---- Timer & Stopwatch Demo Model ----
require_relative "timer_stopwatch_demo"

ts_demo = TimerStopwatchDemo.new
ts_timer = ts_demo.instance_variable_get(:@timer)
ts_sw = ts_demo.instance_variable_get(:@stopwatch)

# Fake start without sleeping
ts_demo.start

puts "=== Timer & Stopwatch Demo ==="
puts "Initial view:"
puts ts_demo.view
puts "---"

# Simulate timer tick
timer_tick = Petals::TimerTickMsg.new(
  id: ts_timer.id, tag: ts_timer.instance_variable_get(:@tag), time: Time.now
)
ts_demo.update(timer_tick)
puts "After timer tick:"
puts ts_demo.view
puts "---"

# Simulate stopwatch tick
sw_tick = Petals::StopwatchTickMsg.new(
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

# ---- Cursor ----
puts "=== Cursor ==="
cursor = Petals::Cursor.new
puts "Initial view: #{cursor.view.inspect}"
cmd = cursor.focus
puts "Focused, cmd: #{cmd ? "present" : "nil"}"
if cmd
  tag = cursor.instance_variable_get(:@tag)
  blink_msg = Petals::CursorBlinkMsg.new(id: cursor.id, tag: tag)
  cmd2 = cursor.handle(blink_msg)
  puts "After blink: blinked=#{cursor.blinked}, view=#{cursor.view.inspect}"
  puts "Chain cmd: #{cmd2 ? "present" : "nil"}"
end
cursor.mode = Petals::Cursor::MODE_STATIC
puts "Static mode view: #{cursor.view.inspect}"
cursor.mode = Petals::Cursor::MODE_HIDE
puts "Hide mode view: #{cursor.view.inspect}"
cursor.blur
puts "After blur: focused=#{cursor.focused?}"
puts

# ---- Help ----
puts "=== Help ==="
help = Petals::Help.new(width: 40)
bindings = [
  { key: "q", desc: "quit" },
  { key: "?", desc: "help" },
  { key: "j/k", desc: "up/down" },
]
puts "Short: #{help.short_help_view(bindings)}"
help.show_all = true
puts "Full:"
puts help.full_help_view([bindings])
puts

# ---- Progress ----
puts "=== Progress ==="
bar = Petals::Progress.new(width: 20, show_percentage: true)
puts "Initial: #{bar.view}"
bar.set_percent(0.5)
puts "After set_percent(0.5), animating: #{bar.animating?}"
puts "view_as(0.75): #{bar.view_as(0.75)}"
puts "view_as(0.0): #{bar.view_as(0.0)}"
puts "view_as(1.0): #{bar.view_as(1.0)}"
# New: spring options
bar2 = Petals::Progress.new(width: 20, frequency: 20.0, damping: 3.0)
puts "Custom spring: freq=#{bar2.frequency} damp=#{bar2.damping}"
bar2.set_spring_options(30.0, 2.0)
puts "After set_spring_options: freq=#{bar2.frequency} damp=#{bar2.damping}"
puts

# ---- Viewport ----
puts "=== Viewport ==="
vp = Petals::Viewport.new(width: 40, height: 5)
content = (0..19).map { |i| "Line #{i}: content here that is wide enough to scroll horizontally" }.join("\n")
vp.content = content
puts "Initial (at_top=#{vp.at_top?}):"
puts vp.view
puts "---"
vp.handle(key("j"))
vp.handle(key("j"))
puts "After 2x down:"
puts vp.view
puts "---"
vp.handle(key("G", mod: [:shift]))
puts "After goto_bottom (at_bottom=#{vp.at_bottom?}):"
puts vp.view
puts "---"
vp.handle(key("g"))
puts "After goto_top (at_top=#{vp.at_top?}):"
puts vp.view
# New: horizontal scroll
vp.scroll_right(5)
puts "After scroll_right(5), x_offset=#{vp.x_offset}:"
puts vp.view
vp.scroll_left(5)
# New: soft wrap
vp2 = Petals::Viewport.new(width: 20, height: 5)
vp2.soft_wrap = true
vp2.content = "This is a long line that should wrap at twenty characters."
puts "Soft wrap view:"
puts vp2.view
# New: ensure_visible
vp.ensure_visible(10)
puts "After ensure_visible(10), y_offset=#{vp.y_offset}"
# New: dimension setters
vp.width = 60
vp.height = 8
puts "After width=60/height=8: w=#{vp.width} h=#{vp.height}"
puts

# ---- Table ----
puts "=== Table ==="
cols = [
  Petals::Table::Column.new(title: "Name", width: 12),
  Petals::Table::Column.new(title: "Score", width: 6),
]
tbl_rows = [
  %w[Alice 95],
  %w[Bob 88],
  %w[Charlie 72],
  %w[Diana 91],
  %w[Eve 85],
]
tbl = Petals::Table.new(columns: cols, rows: tbl_rows, height: 3).focus
puts "Initial:"
puts tbl.view
puts "---"
tbl.handle(key("j"))
tbl.handle(key("j"))
puts "After 2x down (cursor=#{tbl.cursor}):"
puts tbl.view
puts "---"
puts "Selected: #{tbl.selected_row.inspect}"
puts

# ---- TextArea ----
puts "=== TextArea ==="
ta = Petals::TextArea.new(width: 30, height: 4, show_line_numbers: true).focus
ta.handle(key("H"))
ta.handle(key("e"))
ta.handle(key("l"))
ta.handle(key("l"))
ta.handle(key("o"))
ta.handle(key(:enter))
ta.handle(key("W"))
ta.handle(key("o"))
ta.handle(key("r"))
ta.handle(key("l"))
ta.handle(key("d"))
puts "After typing 'Hello\\nWorld':"
puts ta.view
puts "---"
puts "Value: #{ta.value.inspect}"
puts "Line count: #{ta.line_count}, row=#{ta.row}, col=#{ta.col}"
# New: move_to_begin / move_to_end
ta.move_to_begin
puts "After move_to_begin: row=#{ta.row} col=#{ta.col}"
ta.move_to_end
puts "After move_to_end: row=#{ta.row} col=#{ta.col}"
# New: word extraction
ta.value = "hello world foo"
ta.instance_variable_set(:@col, 7)
ta.instance_variable_set(:@last_char_offset, 7)
puts "Word at col 7: #{ta.word.inspect}"
# New: display_height
ta.max_height = 10
ta.value = (0..7).map { |i| "ln#{i}" }.join("\n")
puts "display_height (max_height=10, lines=8, height=4): #{ta.display_height}"
puts

# ---- List ----
puts "=== List ==="
list_items = %w[Apple Banana Cherry Date Elderberry Fig Grape]
lst = Petals::List.new(items: list_items, width: 30, height: 15)
lst.title = "Fruits"
puts "Initial:"
puts lst.view
puts "---"
lst.handle(key("j"))
lst.handle(key("j"))
puts "After 2x down (cursor=#{lst.cursor}):"
puts lst.view
puts "---"
lst.handle(key("/"))
lst.handle(key("a"))
puts "After filter 'a':"
puts lst.view
puts "---"
lst.handle(key(:enter))
puts "After accept filter:"
puts lst.view
puts "---"
lst.handle(key(:escape))
puts "After clear filter (items=#{lst.items.length}):"
puts lst.view
# New: infinite scroll
lst.infinite_scroll = true
lst.goto_end
lst.cursor_down
puts "After infinite_scroll wrap: cursor=#{lst.cursor}"
# New: set_filter_text
lst.set_filter_text("ban")
puts "After set_filter_text('ban'): state=#{lst.filter_state}, items=#{lst.items.length}"
lst.set_filter_text("")
# New: global_index
lst.cursor_down
puts "global_index at cursor #{lst.cursor}: #{lst.global_index}"
# New: visible_items
puts "visible_items count: #{lst.visible_items.length}"
# New: status message
lst.new_status_message("Loading...", lifetime: 0.01)
puts "Status: #{lst.status_message.inspect}"
puts "Status in view: #{lst.view.include?("Loading...")}"
# New: spinner control
lst.start_spinner
puts "Spinner visible: #{lst.spinner_visible?}"
lst.stop_spinner
puts "Spinner visible after stop: #{lst.spinner_visible?}"
puts

# ---- FilePicker ----
puts "=== FilePicker ==="
fp = Petals::FilePicker.new(directory: Dir.pwd, height: 5)
init_msg = fp.init_cmd.call
fp.handle(init_msg)
puts "Directory: #{fp.current_directory}"
puts "View:"
puts fp.view
puts "---"
fp.handle(key(:down))
puts "After down (highlighted: #{fp.highlighted_path})"
# New: page nav
fp.handle(key(:page_down))
puts "After page_down (highlighted: #{fp.highlighted_path})"
fp.handle(key("g"))
puts "After goto_top (highlighted: #{fp.highlighted_path})"
fp.handle(key("G", mod: [:shift]))
puts "After goto_bottom (highlighted: #{fp.highlighted_path})"
# New: disabled selection
fp2 = Petals::FilePicker.new(directory: Dir.pwd, height: 5, allowed_types: [".xyz_nonexistent"])
init_msg2 = fp2.init_cmd.call
fp2.handle(init_msg2)
# Navigate to a file (skip dirs)
10.times { fp2.handle(key(:down)) }
fp2.handle(key(:enter))
sel, path = fp2.did_select_disabled_file?(key(:enter))
puts "Disabled file selected: #{sel}, path: #{path&.split("/")&.last}"
puts

puts "All smoke tests passed!"
