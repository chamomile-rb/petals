# frozen_string_literal: true

require_relative "../lib/petals"

class SpinnerDemo
  include Chamomile::Model
  include Chamomile::Commands

  TYPES = %i[LINE DOT MINI_DOT JUMP PULSE POINTS GLOBE MOON MONKEY METER HAMBURGER ELLIPSIS].freeze

  def initialize
    @type_index = 0
    @spinner = Petals::Spinner.new(type: current_type)
  end

  def start
    @spinner.tick_cmd
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      case msg.key
      when "q" then return quit
      when :up, "k"
        @type_index = (@type_index - 1) % TYPES.size
        @spinner.spinner_type = current_type
        return @spinner.tick_cmd
      when :down, "j"
        @type_index = (@type_index + 1) % TYPES.size
        @spinner.spinner_type = current_type
        return @spinner.tick_cmd
      end
    end

    @spinner.update(msg)
  end

  def view
    name = TYPES[@type_index]
    <<~VIEW

      #{@spinner.view}  Spinner: #{name}

      up/k    previous type
      down/j  next type
      q       quit
    VIEW
  end

  private

  def current_type
    Petals::Spinners.const_get(TYPES[@type_index])
  end
end

Chamomile.run(SpinnerDemo.new) if __FILE__ == $PROGRAM_NAME
