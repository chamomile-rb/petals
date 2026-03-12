# Petals

Reusable TUI components for the [Chamomile](https://github.com/chamomile-rb/chamomile) framework.

## Components

| Component | Description |
|-----------|-------------|
| **Spinner** | 12 animation types (dots, lines, moon, etc.) with configurable FPS |
| **TextInput** | Single-line input with cursor movement, word editing, echo modes, paste support |
| **TextArea** | Multi-line editor with 2D cursor, line numbers, word ops, page navigation |
| **Stopwatch** | Count-up timer with start/stop/toggle/reset |
| **Timer** | Countdown timer with timeout notification |
| **Paginator** | Page navigation with dot or arabic display and key bindings |
| **Cursor** | Blink/static/hide modes with focus/blur support |
| **Help** | Short/full help view renderer from key binding definitions |
| **Progress** | Spring-animated progress bar with gradient/color support |
| **Viewport** | Scrollable content pane with keyboard and mouse navigation |
| **FilePicker** | Async directory browser with extension filtering and stack history |
| **Table** | Scrollable, focus-gated data table with column definitions |
| **List** | Composable filterable list with fuzzy search, delegates, and status messages |

## Installation

```ruby
# Gemfile
gem "petals"
```

## Quick Start

### Spinner

```ruby
require "petals"

class MyApp
  include Chamomile::Application

  def initialize
    @spinner = Petals::Spinner.new(type: Petals::Spinners::DOT)
  end

  def on_start
    @spinner.tick_cmd
  end

  on_key("q") { quit }

  def update(msg)
    case msg
    when Petals::SpinnerTickMsg
      return @spinner.handle(msg)
    end
    nil
  end

  def view
    "#{@spinner.view} Loading..."
  end
end
```

### TextInput

```ruby
@input = Petals::TextInput.new(
  prompt: "> ",
  placeholder: "Type something...",
  char_limit: 100,
)
@input.focus

# In update:
@input.handle(msg)

# In view:
@input.view  # "> Hello world" with reverse-video cursor
```

### Timer & Stopwatch

```ruby
# Countdown from 30 seconds
@timer = Petals::Timer.new(timeout: 30, interval: 1.0)
cmd = @timer.start_cmd

# In update — receives TimerTickMsg, returns TimerTimeoutMsg when done
cmd = @timer.handle(msg)
@timer.timed_out?  # true when countdown reaches 0

# Count-up stopwatch
@stopwatch = Petals::Stopwatch.new(interval: 1.0)
cmd = @stopwatch.start_cmd

# Both render as "MM:SS"
@timer.view      # "00:25"
@stopwatch.view  # "01:03"
```

### Viewport

```ruby
@viewport = Petals::Viewport.new(width: 80, height: 20)
@viewport.content = long_text

# In update — responds to j/k, pgup/pgdn, g/G, mouse wheel
cmd = @viewport.handle(msg)

# Resize
@viewport.width  = 100
@viewport.height = 30

# In view:
@viewport.view  # visible portion of content
```

### Table

```ruby
# Block DSL form (recommended)
@table = Petals::Table.new(rows: rows) do |t|
  t.column "Name", width: 20
  t.column "Size", width: 10
end
@table.focus

# In update — responds to up/down/g/G
cmd = @table.handle(msg)

# In view:
@table.view  # formatted table with highlighted cursor row

# Keyword form also works
columns = [
  Petals::Table::Column.new(title: "Name", width: 20),
  Petals::Table::Column.new(title: "Size", width: 10),
]
@table = Petals::Table.new(columns: columns, rows: rows)
```

### List

```ruby
items = ["Apple", "Banana", "Cherry", "Date", "Fig"]
delegates = items.map { |i| Petals::List::DefaultItem.new(title: i) }

@list = Petals::List.new(items: delegates, width: 30, height: 15)
@list.title = "Fruits"

# In update — responds to arrows, /, filter input
cmd = @list.handle(msg)

# In view — rendered list with filter bar, pagination, help
@list.view
```

### Paginator

```ruby
@pager = Petals::Paginator.new(total_pages: 5)

# Navigate
@pager.next_page
@pager.prev_page
@pager.handle(key_msg)  # responds to arrows, h/l, page up/down

# Display
@pager.view  # "○ ● ○ ○ ○" (dot mode)

@pager.type = Petals::Paginator::TYPE_ARABIC
@pager.view  # "2/5"

# Slice arrays by page
start, length = @pager.slice_bounds(items.length)
page_items = items[start, length]
```

## Component Protocol

All components follow the event-driven pattern:

```ruby
# Initialize
component = Component.new(options...)

# Handle events — returns a command or nil
cmd = component.handle(msg)

# Render — returns a String
component.view
```

Components are mutable classes — `handle` modifies internal state and returns a command (or nil), so no model reassignment is needed.

## Key Binding

Components use `KeyBinding` for configurable key maps:

```ruby
# Check if a key message matches an action
Petals::KeyBinding.key_matches?(msg, @key_map, :line_start)

# Customize by passing your own key_map to any component
```

## Examples

```sh
ruby examples/spinner_demo.rb          # animated spinner types
ruby examples/text_input_demo.rb       # interactive text input
ruby examples/combined_demo.rb         # spinner + text input together
ruby examples/timer_stopwatch_demo.rb  # countdown + count-up side by side
ruby examples/kitchen_sink.rb          # all components in one demo
ruby examples/smoke_test.rb            # headless test of all components
```

## Ecosystem

| Gem | Description |
|-----|-------------|
| **[chamomile](https://github.com/chamomile-rb/chamomile)** | Core TUI framework (event-driven event loop) |
| **petals** | Reusable components (this gem) |
| **[flourish](https://github.com/chamomile-rb/flourish)** | Terminal styling — colors, borders, padding, layout composition |

## Development

```sh
bundle install
bundle exec rspec        # run tests
bundle exec rubocop      # lint
```

## License

[MIT](LICENSE)
