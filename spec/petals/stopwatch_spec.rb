# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::Stopwatch do
  describe "initialization" do
    it "defaults to 1.0 second interval" do
      sw = described_class.new
      expect(sw.interval).to eq(1.0)
    end

    it "accepts a custom interval" do
      sw = described_class.new(interval: 0.5)
      expect(sw.interval).to eq(0.5)
    end

    it "starts with zero elapsed" do
      sw = described_class.new
      expect(sw.elapsed).to eq(0.0)
    end

    it "starts not running" do
      sw = described_class.new
      expect(sw.running?).to be false
    end

    it "assigns unique IDs" do
      ids = 5.times.map { described_class.new.id }
      expect(ids.uniq.size).to eq(5)
    end
  end

  describe "#start_cmd" do
    it "returns a callable" do
      sw = described_class.new
      expect(sw.start_cmd).to respond_to(:call)
    end

    it "sets running to true" do
      sw = described_class.new
      sw.start_cmd
      expect(sw.running?).to be true
    end

    it "produces a StopwatchTickMsg with matching id" do
      sw = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = sw.start_cmd.call
      expect(msg).to be_a(Petals::StopwatchTickMsg)
      expect(msg.id).to eq(sw.id)
    end
  end

  describe "#update" do
    it "advances elapsed on matching StopwatchTickMsg" do
      sw = described_class.new(interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)
      msg = sw.start_cmd.call
      result, cmd = sw.update(msg)
      expect(result).to equal(sw)
      expect(sw.elapsed).to eq(1.0)
      expect(cmd).to respond_to(:call)
    end

    it "chains ticks continuously" do
      sw = described_class.new(interval: 0.5)
      allow_any_instance_of(Object).to receive(:sleep)

      msg = sw.start_cmd.call
      _, cmd = sw.update(msg)
      expect(cmd).to respond_to(:call)

      msg2 = cmd.call
      _, cmd2 = sw.update(msg2)
      expect(sw.elapsed).to eq(1.0)
      expect(cmd2).to respond_to(:call)
    end

    it "ignores non-StopwatchTickMsg" do
      sw = described_class.new
      _, cmd = sw.update(Chamomile::KeyMsg.new(key: "a", mod: []))
      expect(cmd).to be_nil
      expect(sw.elapsed).to eq(0.0)
    end

    it "ignores StopwatchTickMsg with wrong id" do
      sw = described_class.new
      msg = Petals::StopwatchTickMsg.new(id: "wrong", tag: 0, time: Time.now)
      _, cmd = sw.update(msg)
      expect(cmd).to be_nil
      expect(sw.elapsed).to eq(0.0)
    end

    it "ignores StopwatchTickMsg with stale tag" do
      sw = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = sw.start_cmd.call
      sw.stop # bumps tag
      _, cmd = sw.update(msg)
      expect(cmd).to be_nil
      expect(sw.elapsed).to eq(0.0)
    end
  end

  describe "#stop" do
    it "sets running to false" do
      sw = described_class.new
      sw.start_cmd
      sw.stop
      expect(sw.running?).to be false
    end

    it "invalidates in-flight ticks" do
      sw = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = sw.start_cmd.call
      sw.stop
      _, cmd = sw.update(msg)
      expect(cmd).to be_nil
    end

    it "returns self for chaining" do
      sw = described_class.new
      expect(sw.stop).to equal(sw)
    end
  end

  describe "#toggle" do
    it "starts when stopped" do
      sw = described_class.new
      cmd = sw.toggle
      expect(sw.running?).to be true
      expect(cmd).to respond_to(:call)
    end

    it "stops when running" do
      sw = described_class.new
      sw.start_cmd
      cmd = sw.toggle
      expect(sw.running?).to be false
      expect(cmd).to be_nil
    end
  end

  describe "#reset" do
    it "zeroes elapsed" do
      sw = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = sw.start_cmd.call
      sw.update(msg)
      sw.reset
      expect(sw.elapsed).to eq(0.0)
    end

    it "stops the stopwatch" do
      sw = described_class.new
      sw.start_cmd
      sw.reset
      expect(sw.running?).to be false
    end

    it "invalidates in-flight ticks" do
      sw = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = sw.start_cmd.call
      sw.reset
      _, cmd = sw.update(msg)
      expect(cmd).to be_nil
    end

    it "returns self for chaining" do
      sw = described_class.new
      expect(sw.reset).to equal(sw)
    end
  end

  describe "#view" do
    it "shows 00:00 at start" do
      sw = described_class.new
      expect(sw.view).to eq("00:00")
    end

    it "shows MM:SS for seconds" do
      sw = described_class.new
      sw.instance_variable_set(:@elapsed, 61.0)
      expect(sw.view).to eq("01:01")
    end

    it "shows H:MM:SS for hours" do
      sw = described_class.new
      sw.instance_variable_set(:@elapsed, 3661.0)
      expect(sw.view).to eq("1:01:01")
    end

    it "handles fractional elapsed by ceiling" do
      sw = described_class.new
      sw.instance_variable_set(:@elapsed, 59.3)
      expect(sw.view).to eq("01:00")
    end
  end

  describe "edge cases" do
    it "start_cmd returns nil if already running" do
      sw = described_class.new
      sw.start_cmd
      expect(sw.start_cmd).to be_nil
    end

    it "resumes from current elapsed after stop and start" do
      sw = described_class.new(interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      msg = sw.start_cmd.call
      sw.update(msg)
      expect(sw.elapsed).to eq(1.0)

      sw.stop
      msg2 = sw.start_cmd.call
      sw.update(msg2)
      expect(sw.elapsed).to eq(2.0)
    end

    it "can restart after reset" do
      sw = described_class.new(interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      msg = sw.start_cmd.call
      sw.update(msg)
      sw.reset
      expect(sw.elapsed).to eq(0.0)

      msg2 = sw.start_cmd.call
      sw.update(msg2)
      expect(sw.elapsed).to eq(1.0)
    end

    it "full toggle round-trip preserves elapsed" do
      sw = described_class.new(interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      cmd = sw.toggle # start
      msg = cmd.call
      sw.update(msg)
      expect(sw.elapsed).to eq(1.0)

      sw.toggle # stop
      expect(sw.running?).to be false

      cmd = sw.toggle # start again
      msg = cmd.call
      _, next_cmd = sw.update(msg)
      expect(sw.elapsed).to eq(2.0)
      expect(next_cmd).to respond_to(:call)
    end

    it "ignores StopwatchTickMsg with future tag" do
      sw = described_class.new
      msg = Petals::StopwatchTickMsg.new(id: sw.id, tag: 999, time: Time.now)
      _, cmd = sw.update(msg)
      expect(cmd).to be_nil
    end

    it "advances by custom interval amount" do
      sw = described_class.new(interval: 0.25)
      allow_any_instance_of(Object).to receive(:sleep)
      msg = sw.start_cmd.call
      sw.update(msg)
      expect(sw.elapsed).to eq(0.25)
    end

    it "reset on fresh stopwatch is harmless" do
      sw = described_class.new
      sw.reset
      expect(sw.elapsed).to eq(0.0)
      expect(sw.running?).to be false
    end
  end

  describe "multi-instance isolation" do
    it "each only responds to its own ticks" do
      sw1 = described_class.new
      sw2 = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)

      msg1 = sw1.start_cmd.call
      msg2 = sw2.start_cmd.call

      _, cmd = sw1.update(msg2)
      expect(cmd).to be_nil
      expect(sw1.elapsed).to eq(0.0)

      _, cmd = sw1.update(msg1)
      expect(cmd).to respond_to(:call)
      expect(sw1.elapsed).to eq(1.0)
    end
  end
end
