require_relative "../lib/chamomile/leaves"

class SpinnerDemo
  include Chamomile::Model
  include Chamomile::Commands

  TYPES = %i[LINE DOT MINI_DOT JUMP PULSE POINTS GLOBE MOON MONKEY METER HAMBURGER ELLIPSIS].freeze

  def initialize
    @type_index = 0
    @spinner = Chamomile::Leaves::Spinner.new(type: current_type)
  end

  def init
    @spinner.tick_cmd
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      case msg.key
      when "q"     then return [self, quit]
      when :up, "k"
        @type_index = (@type_index - 1) % TYPES.size
        @spinner.spinner_type = current_type
        return [self, @spinner.tick_cmd]
      when :down, "j"
        @type_index = (@type_index + 1) % TYPES.size
        @spinner.spinner_type = current_type
        return [self, @spinner.tick_cmd]
      end
    end

    _, cmd = @spinner.update(msg)
    [self, cmd]
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
    Chamomile::Leaves::Spinners.const_get(TYPES[@type_index])
  end
end

Chamomile.run(SpinnerDemo.new)
