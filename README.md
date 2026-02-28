# Chamomile Leaves

Reusable TUI components for the [Chamomile](https://github.com/chamomile) framework. Ported from Go's [Bubbles](https://github.com/charmbracelet/bubbles).

## Components

| Component | Description |
|-----------|-------------|
| **Spinner** | 12 animation types (dots, lines, moon, etc.) with configurable FPS |
| **TextInput** | Single-line input with cursor movement, word editing, echo modes, paste support |
| **Stopwatch** | Count-up timer with start/stop/toggle/reset |
| **Timer** | Countdown timer with timeout notification |
| **Paginator** | Page navigation with dot or arabic display and key bindings |
| **KeyBinding** | Modifier-order-insensitive key matching for composable key maps |

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
  include Chamomile::Model
  include Chamomile::Commands

  def initialize
    @spinner = Petals::Spinner.new(type: Petals::Spinners::DOT)
  end

  def init
    @spinner.tick_cmd
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      return [self, quit] if msg.key == "q"
    when Petals::SpinnerTickMsg
      _, cmd = @spinner.update(msg)
      return [self, cmd]
    end
    [self, nil]
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
_, cmd = @input.update(msg)

# In view:
@input.view  # "> Hello world" with reverse-video cursor
```

### Timer & Stopwatch

```ruby
# Countdown from 30 seconds
@timer = Petals::Timer.new(timeout: 30, interval: 1.0)
cmd = @timer.start_cmd

# In update — receives TimerTickMsg, returns TimerTimeoutMsg when done
_, cmd = @timer.update(msg)
@timer.timed_out?  # true when countdown reaches 0

# Count-up stopwatch
@stopwatch = Petals::Stopwatch.new(interval: 1.0)
cmd = @stopwatch.start_cmd

# Both render as "MM:SS"
@timer.view      # "00:25"
@stopwatch.view  # "01:03"
```

### Paginator

```ruby
@pager = Petals::Paginator.new(total_pages: 5)

# Navigate
@pager.next_page
@pager.prev_page
@pager.update(key_msg)  # responds to arrows, h/l, page up/down

# Display
@pager.view  # "○ ● ○ ○ ○" (dot mode)

@pager.type = Petals::Paginator::TYPE_ARABIC
@pager.view  # "2/5"

# Slice arrays by page
start, length = @pager.slice_bounds(items.length)
page_items = items[start, length]
```

## Component Protocol

All components follow the Elm Architecture pattern:

```ruby
# Initialize
component = Component.new(options...)

# Update — returns [self, cmd]
_, cmd = component.update(msg)

# Render — returns a String
component.view
```

Components are mutable classes — `update` modifies internal state and returns `self`, so no model reassignment is needed.

## Key Binding

Components use `KeyBinding` for configurable key maps:

```ruby
# Default TextInput key map includes:
# :character_forward  → right arrow, Ctrl+F
# :character_backward → left arrow, Ctrl+B
# :delete_char_backward → backspace
# :line_start → Home, Ctrl+A
# :line_end → End, Ctrl+E
# ... and more

# Customize by passing your own key_map to any component
```

## Examples

```sh
ruby examples/spinner_demo.rb          # animated spinner types
ruby examples/text_input_demo.rb       # interactive text input
ruby examples/combined_demo.rb         # spinner + text input together
ruby examples/timer_stopwatch_demo.rb  # countdown + count-up side by side
ruby examples/smoke_test.rb            # headless test of all components
```

## Development

```sh
bundle install
bundle exec rspec        # run tests (304 specs)
bundle exec rubocop      # lint
```

## License

[MIT](LICENSE)
