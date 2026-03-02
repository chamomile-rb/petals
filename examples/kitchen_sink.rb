#!/usr/bin/env ruby
# frozen_string_literal: true

# Kitchen Sink Demo — exercises ALL 14 Petals components in a tabbed TUI.
# Keys: 1-7 to switch tabs, Ctrl+Q to quit.
#
# Components per tab:
#   1. Viewport          5. Progress
#   2. TextArea          6. Table
#   3. List (+ Paginator, TextInput, Spinner, Help, KeyBinding internally)
#   4. FilePicker        7. Timer + Stopwatch + Cursor

require_relative "../lib/petals"

class KitchenSink
  include Chamomile::Model
  include Chamomile::Commands

  TABS = %w[Viewport TextArea List FilePicker Progress Table Timers].freeze

  def initialize
    @tab = 0
    @width = 80
    @height = 24

    setup_viewport
    setup_textarea
    setup_list
    setup_file_picker
    setup_progress
    setup_table
    setup_timers
  end

  def start
    batch(
      @file_picker.init_cmd,
      @list.start_spinner,
      @stopwatch.start_cmd,
      @timer.start_cmd,
      @cursor.focus
    )
  end

  def update(msg)
    case msg
    when Chamomile::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      return nil
    when Chamomile::KeyMsg
      return quit if msg.key == "q" && msg.mod.include?(:ctrl)

      if msg.mod.empty? && msg.key.is_a?(String) && ("1".."7").include?(msg.key)
        @tab = msg.key.to_i - 1
        return nil
      end
    end

    dispatch_to_tab(msg)
  end

  def view
    tab_bar = TABS.each_with_index.map do |name, i|
      i == @tab ? "\e[7m #{i + 1}:#{name} \e[0m" : " #{i + 1}:#{name} "
    end.join("|")

    content = render_tab
    help = tab_help

    [tab_bar, "", content, "", help].join("\n")
  end

  private

  # ── Setup ──────────────────────────────────────────────

  def setup_viewport
    @viewport = Petals::Viewport.new(width: 76, height: 16)
    @viewport.soft_wrap = true
    lorem = (1..100).map do |i|
      "#{i}. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod."
    end
    @viewport.set_content(lorem.join("\n"))
  end

  def setup_textarea
    @textarea = Petals::TextArea.new(
      width: 76, height: 16,
      show_line_numbers: true, prompt: ""
    ).focus
    @textarea.max_height = 16
    @textarea.value = [
      "# Welcome to the TextArea", "",
      "Try typing, word navigation (Alt+arrows),",
      "page up/down, Ctrl+Home/End.", "",
      "Word under cursor: use the `word` method.",
    ].join("\n")
  end

  def setup_list
    list_items = (1..50).map do |i|
      "Item #{i} — #{%w[Alpha Beta Gamma Delta Epsilon].sample}"
    end
    @list = Petals::List.new(items: list_items, width: 76, height: 16)
    @list.title = "Item Browser"
    @list.infinite_scroll = true
  end

  def setup_file_picker
    @file_picker = Petals::FilePicker.new(
      directory: Dir.pwd, height: 14,
      show_size: true, show_permissions: true
    )
  end

  def setup_progress
    @bar1 = Petals::Progress.new(
      width: 50,
      gradient: [[66, 135, 245], [138, 43, 226], [220, 38, 38]]
    )
    @bar2 = Petals::Progress.new(width: 50, full_color: [0, 200, 83])
    @bar2.set_spring_options(20.0, 1.5)
  end

  def setup_table
    @table = Petals::Table.new(
      columns: [
        Petals::Table::Column.new(title: "Name", width: 16),
        Petals::Table::Column.new(title: "Language", width: 12),
        Petals::Table::Column.new(title: "Stars", width: 8),
        Petals::Table::Column.new(title: "Status", width: 10),
      ],
      rows: [
        %w[chamomile Ruby 42 active],
        %w[petals Ruby 18 active],
        %w[bubbletea Go 28000 active],
        %w[bubbles Go 5600 active],
        %w[lipgloss Go 8200 active],
        %w[wish Go 3100 active],
        %w[glamour Go 2200 active],
        %w[tview Go 10400 stable],
        %w[termbox-go Go 4600 archived],
        %w[cursive Rust 410 active],
        %w[ratatui Rust 11000 active],
        %w[tui-rs Rust 2000 archived],
      ],
      height: 14
    ).focus
  end

  def setup_timers
    @stopwatch = Petals::Stopwatch.new(interval: 0.1)
    @timer = Petals::Timer.new(timeout: 60, interval: 0.1)
    @cursor = Petals::Cursor.new(mode: Petals::Cursor::MODE_BLINK)
    @timer_status = "running"
  end

  # ── Dispatch ───────────────────────────────────────────

  def dispatch_to_tab(msg)
    case @tab
    when 0 then @viewport.update(msg)
    when 1 then @textarea.update(msg)
    when 2 then dispatch_list(msg)
    when 3 then @file_picker.update(msg)
    when 4 then dispatch_progress(msg)
    when 5 then @table.update(msg)
    when 6 then dispatch_timers(msg)
    end
  end

  def dispatch_list(msg)
    cmds = []
    cmds << @list.update(msg)
    spinner = @list.instance_variable_get(:@spinner)
    cmds << spinner.tick_cmd if msg.is_a?(Petals::SpinnerTickMsg) && msg.id == spinner.id
    batch_cmds(cmds)
  end

  def dispatch_progress(msg)
    cmds = []
    if msg.is_a?(Chamomile::KeyMsg)
      cmds << @bar1.incr_percent(0.1) if msg.key == "a"
      cmds << @bar2.incr_percent(0.1) if msg.key == "b"
    end
    cmds << @bar1.update(msg)
    cmds << @bar2.update(msg)
    batch_cmds(cmds)
  end

  def dispatch_timers(msg)
    cmds = []

    if msg.is_a?(Chamomile::KeyMsg)
      case msg.key
      when "s" then cmds << (@stopwatch.running? ? @stopwatch.stop && nil : @stopwatch.start_cmd)
      when "t" then cmds << (@timer.running? ? @timer.stop && nil : @timer.start_cmd)
      when "r"
        @stopwatch.reset
        @timer.reset
        @timer_status = "reset"
        cmds << @stopwatch.start_cmd
        cmds << @timer.start_cmd
      end
    end

    cmds << @stopwatch.update(msg)
    cmds << @timer.update(msg)
    cmds << @cursor.update(msg)

    @timer_status = "DONE!" if msg.is_a?(Petals::TimerTimeoutMsg) && msg.id == @timer.id

    batch_cmds(cmds)
  end

  def batch_cmds(cmds)
    valid = cmds.compact
    valid.empty? ? nil : batch(*valid)
  end

  # ── Views ──────────────────────────────────────────────

  def render_tab
    case @tab
    when 0 then @viewport.view
    when 1 then @textarea.view
    when 2 then @list.view
    when 3 then @file_picker.view
    when 4 then progress_view
    when 5 then @table.view
    when 6 then timers_view
    else ""
    end
  end

  def tab_help
    base = "  1-7: tabs | Ctrl+Q: quit"
    extra = case @tab
            when 0 then " | j/k: scroll | g/G: top/bottom | left/right: horiz"
            when 1 then " | type to edit | Ctrl+Home/End: begin/end"
            when 2 then " | j/k: navigate | /: filter | esc: clear"
            when 3 then " | j/k: navigate | enter: open | backspace: back"
            when 4 then " | a: bar1 | b: bar2"
            when 5 then " | j/k: navigate | g/G: top/bottom"
            when 6 then " | s: stopwatch | t: timer | r: reset"
            else ""
            end
    base + extra
  end

  def progress_view
    [
      "  Gradient bar (press 'a' to advance):",
      "  #{@bar1.view}",
      "",
      "  Solid bar (press 'b' to advance):",
      "  #{@bar2.view}",
      "",
      "  Bar 1 spring: freq=#{@bar1.frequency} damp=#{@bar1.damping}",
      "  Bar 2 spring: freq=#{@bar2.frequency} damp=#{@bar2.damping}",
    ].join("\n")
  end

  def timers_view
    sw_status = @stopwatch.running? ? "running" : "stopped"
    tm_status = if @timer.timed_out?
                  "DONE!"
                elsif @timer.running?
                  "running"
                else
                  "paused"
                end
    @timer_status = tm_status

    [
      "  Stopwatch  #{@cursor.view}",
      "",
      "    #{@stopwatch.view}  (#{sw_status})",
      "",
      "  Timer (60s countdown)",
      "",
      "    #{@timer.view}  (#{@timer_status})",
      "",
      "  Cursor mode: #{@cursor.mode} | blinked: #{@cursor.blinked}",
    ].join("\n")
  end
end

Chamomile.run(KitchenSink.new, alt_screen: true, mouse: :all_motion) if __FILE__ == $PROGRAM_NAME
