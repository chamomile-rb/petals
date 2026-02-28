# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::Progress do
  describe "initialization" do
    it "defaults to 0 percent" do
      bar = described_class.new
      expect(bar.percent).to eq(0.0)
    end

    it "defaults width to DEFAULT_WIDTH" do
      bar = described_class.new
      expect(bar.width).to eq(described_class::DEFAULT_WIDTH)
    end

    it "defaults to showing percentage" do
      bar = described_class.new
      expect(bar.show_percentage).to be true
    end

    it "assigns unique IDs" do
      ids = 5.times.map { described_class.new.id }
      expect(ids.uniq.size).to eq(5)
    end

    it "starts not animating" do
      bar = described_class.new
      expect(bar.animating?).to be false
    end

    it "accepts custom options" do
      bar = described_class.new(width: 20, full_char: "#", empty_char: "-", show_percentage: false)
      expect(bar.width).to eq(20)
      expect(bar.full_char).to eq("#")
      expect(bar.empty_char).to eq("-")
      expect(bar.show_percentage).to be false
    end

    it "defaults frequency and damping to constants" do
      bar = described_class.new
      expect(bar.frequency).to eq(described_class::FREQUENCY)
      expect(bar.damping).to eq(described_class::DAMPING)
    end

    it "accepts custom frequency and damping" do
      bar = described_class.new(frequency: 20.0, damping: 3.0)
      expect(bar.frequency).to eq(20.0)
      expect(bar.damping).to eq(3.0)
    end
  end

  describe "#set_percent" do
    it "returns a frame_cmd" do
      bar = described_class.new
      cmd = bar.set_percent(0.5)
      expect(cmd).to respond_to(:call)
    end

    it "sets animating to true" do
      bar = described_class.new
      bar.set_percent(0.5)
      expect(bar.animating?).to be true
    end

    it "clamps to 0-1 range" do
      bar = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      bar.set_percent(1.5)
      # Drive animation to completion
      20.times do
        msg = bar.send(:frame_cmd).call
        bar.instance_variable_set(:@tag, msg.tag)
        bar.update(msg) || break
      end
      expect(bar.percent).to be <= 1.0
    end

    it "clamps negative to 0" do
      bar = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      bar.set_percent(-0.5)
      20.times do
        msg = bar.send(:frame_cmd).call
        bar.instance_variable_set(:@tag, msg.tag)
        bar.update(msg) || break
      end
      expect(bar.percent).to be >= 0.0
    end
  end

  describe "#incr_percent" do
    it "increments target" do
      bar = described_class.new
      bar.set_percent(0.3)
      bar.incr_percent(0.2)
      expect(bar.instance_variable_get(:@target)).to be_within(0.001).of(0.5)
    end
  end

  describe "#decr_percent" do
    it "decrements target" do
      bar = described_class.new
      bar.set_percent(0.5)
      bar.decr_percent(0.2)
      expect(bar.instance_variable_get(:@target)).to be_within(0.001).of(0.3)
    end
  end

  describe "#update" do
    it "advances animation on matching ProgressFrameMsg" do
      bar = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = bar.set_percent(0.5)
      msg = cmd.call
      result = bar.update(msg)
      expect(bar.percent).to be > 0.0
      expect(result).to respond_to(:call)
    end

    it "converges to target" do
      bar = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = bar.set_percent(0.5)
      500.times do
        msg = cmd.call
        cmd = bar.update(msg)
        break unless cmd
      end
      expect(bar.percent).to be_within(0.01).of(0.5)
      expect(bar.animating?).to be false
    end

    it "ignores non-ProgressFrameMsg" do
      bar = described_class.new
      result = bar.update(Chamomile::KeyMsg.new(key: "a", mod: []))
      expect(result).to be_nil
    end

    it "ignores ProgressFrameMsg with wrong id" do
      bar = described_class.new
      msg = Petals::ProgressFrameMsg.new(id: "wrong", tag: 0)
      result = bar.update(msg)
      expect(result).to be_nil
    end

    it "ignores ProgressFrameMsg with stale tag" do
      bar = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = bar.set_percent(0.5)
      msg = cmd.call
      bar.set_percent(0.8) # bumps tag
      result = bar.update(msg)
      expect(result).to be_nil
    end
  end

  describe "#view" do
    it "renders empty bar at 0%" do
      bar = described_class.new(width: 10, show_percentage: false)
      expect(bar.view).to eq("\u2591" * 10)
    end

    it "renders full bar at 100%" do
      bar = described_class.new(width: 10, show_percentage: false)
      bar.instance_variable_set(:@percent, 1.0)
      expect(bar.view).to eq("\u2588" * 10)
    end

    it "renders half bar at 50%" do
      bar = described_class.new(width: 10, show_percentage: false)
      bar.instance_variable_set(:@percent, 0.5)
      expect(bar.view).to eq(("\u2588" * 5) + ("\u2591" * 5))
    end

    it "includes percentage text when show_percentage is true" do
      bar = described_class.new(width: 10)
      bar.instance_variable_set(:@percent, 0.5)
      expect(bar.view).to include(" 50%")
    end

    it "hides percentage when show_percentage is false" do
      bar = described_class.new(width: 10, show_percentage: false)
      bar.instance_variable_set(:@percent, 0.5)
      expect(bar.view).not_to include("%")
    end

    it "uses custom chars" do
      bar = described_class.new(width: 5, full_char: "#", empty_char: "-", show_percentage: false)
      bar.instance_variable_set(:@percent, 0.4)
      expect(bar.view).to eq("##---")
    end
  end

  describe "#view_as" do
    it "renders at the specified percent without affecting state" do
      bar = described_class.new(width: 10, show_percentage: false)
      result = bar.view_as(0.5)
      expect(result).to eq(("\u2588" * 5) + ("\u2591" * 5))
      expect(bar.percent).to eq(0.0)
    end

    it "clamps to 0-1 range" do
      bar = described_class.new(width: 10, show_percentage: false)
      result = bar.view_as(1.5)
      expect(result).to eq("\u2588" * 10)
    end

    it "handles negative" do
      bar = described_class.new(width: 10, show_percentage: false)
      result = bar.view_as(-0.5)
      expect(result).to eq("\u2591" * 10)
    end
  end

  describe "gradient" do
    it "renders with gradient colors" do
      bar = described_class.new(
        width: 4,
        show_percentage: false,
        gradient: [[255, 0, 0], [0, 0, 255]]
      )
      bar.instance_variable_set(:@percent, 1.0)
      result = bar.view
      expect(result).to include("\e[38;2;255;0;0m")
      expect(result).to include("\e[38;2;0;0;255m")
    end

    it "handles single-cell filled gradient" do
      bar = described_class.new(
        width: 4,
        show_percentage: false,
        gradient: [[255, 0, 0], [0, 0, 255]]
      )
      bar.instance_variable_set(:@percent, 0.25)
      result = bar.view
      expect(result).to include("\e[38;2;")
    end
  end

  describe "colored bar" do
    it "renders with full_color" do
      bar = described_class.new(
        width: 4,
        show_percentage: false,
        full_color: [0, 255, 0]
      )
      bar.instance_variable_set(:@percent, 0.5)
      result = bar.view
      expect(result).to include("\e[38;2;0;255;0m")
    end

    it "renders with empty_color" do
      bar = described_class.new(
        width: 4,
        show_percentage: false,
        empty_color: [100, 100, 100]
      )
      bar.instance_variable_set(:@percent, 0.5)
      result = bar.view
      expect(result).to include("\e[38;2;100;100;100m")
    end
  end

  describe "edge cases" do
    it "handles 0% view_as" do
      bar = described_class.new(width: 5, show_percentage: false)
      expect(bar.view_as(0.0)).to eq("\u2591" * 5)
    end

    it "handles 100% view_as" do
      bar = described_class.new(width: 5, show_percentage: false)
      expect(bar.view_as(1.0)).to eq("\u2588" * 5)
    end

    it "handles width of 1" do
      bar = described_class.new(width: 1, show_percentage: false)
      expect(bar.view_as(1.0)).to eq("\u2588")
      expect(bar.view_as(0.0)).to eq("\u2591")
    end

    it "percentage format is customizable" do
      bar = described_class.new(width: 10, percentage_format: " [%.1f%%]")
      bar.instance_variable_set(:@percent, 0.5)
      expect(bar.view).to include("[50.0%]")
    end
  end

  describe "#set_spring_options" do
    it "changes frequency and damping" do
      bar = described_class.new
      bar.set_spring_options(20.0, 3.0)
      expect(bar.frequency).to eq(20.0)
      expect(bar.damping).to eq(3.0)
    end

    it "affects animation behavior" do
      bar1 = described_class.new
      bar2 = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)

      bar2.set_spring_options(50.0, 1.0) # much stiffer spring

      cmd1 = bar1.set_percent(0.5)
      cmd2 = bar2.set_percent(0.5)

      msg1 = cmd1.call
      msg2 = cmd2.call

      bar1.update(msg1)
      bar2.update(msg2)

      # Stiffer spring should move faster in the first step
      expect(bar2.percent).to be > bar1.percent
    end

    it "converges with custom spring options" do
      bar = described_class.new(frequency: 20.0, damping: 3.0)
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = bar.set_percent(0.8)
      500.times do
        msg = cmd.call
        cmd = bar.update(msg)
        break unless cmd
      end
      expect(bar.percent).to be_within(0.01).of(0.8)
      expect(bar.animating?).to be false
    end

    it "converts to float" do
      bar = described_class.new
      bar.set_spring_options(20, 3)
      expect(bar.frequency).to eq(20.0)
      expect(bar.damping).to eq(3.0)
    end
  end

  describe "multiple progress bars" do
    it "each only responds to its own frames" do
      b1 = described_class.new
      b2 = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)

      cmd1 = b1.set_percent(0.5)
      b2.set_percent(0.8)

      msg1 = cmd1.call
      result = b2.update(msg1)
      expect(result).to be_nil

      result = b1.update(msg1)
      expect(result).to respond_to(:call)
    end
  end
end
