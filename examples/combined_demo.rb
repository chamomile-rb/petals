# frozen_string_literal: true

require_relative "../lib/petals"

class CombinedDemo
  include Chamomile::Application

  def initialize
    @spinner = Petals::Spinner.new(type: Petals::Spinners::DOT)
    @input = Petals::TextInput.new(
      prompt: "> ",
      placeholder: "What are you waiting for?"
    ).focus
    @messages = []
  end

  def start
    @spinner.tick_cmd
  end

  def update(msg)
    case msg
    when Chamomile::KeyEvent
      return quit if msg.key == :escape

      if msg.key == :enter && !@input.value.empty?
        @messages << @input.value
        @input.value = ""
        return nil
      end
    end

    spin_cmd = @spinner.handle(msg)
    @input.handle(msg)
    spin_cmd
  end

  def view
    history = @messages.last(5).map { |m| "  #{m}" }.join("\n")
    history = "  (no messages yet)" if history.empty?

    <<~VIEW

      #{@spinner.view}  Petals Demo

      Messages:
      #{history}

      #{@input.view}

      enter   send message
      escape  quit
    VIEW
  end
end

Chamomile.run(CombinedDemo.new, bracketed_paste: true) if __FILE__ == $PROGRAM_NAME
