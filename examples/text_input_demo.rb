# frozen_string_literal: true

require_relative "../lib/petals"

class TextInputDemo
  include Chamomile::Model
  include Chamomile::Commands

  def initialize
    @input = Petals::TextInput.new(
      prompt: "> ",
      placeholder: "Type something...",
      char_limit: 50,
      validate: ->(v) { v.length > 40 ? "Getting long!" : nil }
    ).focus
    @submitted = nil
  end

  def init = nil

  def update(msg)
    if @submitted
      case msg
      when Chamomile::KeyMsg
        return [self, quit] if msg.key == "q"

        if msg.key == :enter
          @submitted = nil
          @input.value = ""
          @input.focus
        end
      end
      return [self, nil]
    end

    case msg
    when Chamomile::KeyMsg
      return [self, quit] if msg.key == :escape

      if msg.key == :enter
        @submitted = @input.value
        @input.blur
        return [self, nil]
      end
    end

    @input.update(msg)
    [self, nil]
  end

  def view
    err_line = @input.err ? "\n  #{@input.err}" : ""

    if @submitted
      <<~VIEW

        You entered: #{@submitted}

        enter  new input
        q      quit
      VIEW
    else
      <<~VIEW

        Text Input Demo (#{@input.value.length}/50)
        #{@input.view}#{err_line}

        enter   submit
        escape  quit
      VIEW
    end
  end
end

Chamomile.run(TextInputDemo.new, bracketed_paste: true) if __FILE__ == $PROGRAM_NAME
