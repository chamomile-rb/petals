require_relative "../lib/chamomile/leaves"

class CombinedDemo
  include Chamomile::Model
  include Chamomile::Commands

  def initialize
    @spinner = Chamomile::Leaves::Spinner.new(type: Chamomile::Leaves::Spinners::DOT)
    @input = Chamomile::Leaves::TextInput.new(
      prompt: "> ",
      placeholder: "What are you waiting for?"
    ).focus
    @messages = []
  end

  def init
    @spinner.tick_cmd
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      return [self, quit] if msg.key == :escape

      if msg.key == :enter && !@input.value.empty?
        @messages << @input.value
        @input.value = ""
        return [self, nil]
      end
    end

    _, spin_cmd = @spinner.update(msg)
    @input.update(msg)
    [self, spin_cmd]
  end

  def view
    history = @messages.last(5).map { |m| "  #{m}" }.join("\n")
    history = "  (no messages yet)" if history.empty?

    <<~VIEW

      #{@spinner.view}  Chamomile Leaves Demo

      Messages:
      #{history}

      #{@input.view}

      enter   send message
      escape  quit
    VIEW
  end
end

Chamomile.run(CombinedDemo.new, bracketed_paste: true)
