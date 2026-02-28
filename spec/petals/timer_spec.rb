# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::Timer do
  describe "initialization" do
    it "requires a timeout" do
      timer = described_class.new(timeout: 30)
      expect(timer.timeout).to eq(30.0)
      expect(timer.remaining).to eq(30.0)
    end

    it "defaults to 1.0 second interval" do
      timer = described_class.new(timeout: 10)
      expect(timer.interval).to eq(1.0)
    end

    it "accepts a custom interval" do
      timer = described_class.new(timeout: 10, interval: 0.5)
      expect(timer.interval).to eq(0.5)
    end

    it "starts not running" do
      timer = described_class.new(timeout: 10)
      expect(timer.running?).to be false
    end

    it "starts not timed out" do
      timer = described_class.new(timeout: 10)
      expect(timer.timed_out?).to be false
    end

    it "assigns unique IDs" do
      ids = 5.times.map { described_class.new(timeout: 10).id }
      expect(ids.uniq.size).to eq(5)
    end
  end

  describe "#start_cmd" do
    it "returns a callable" do
      timer = described_class.new(timeout: 10)
      expect(timer.start_cmd).to respond_to(:call)
    end

    it "sets running to true" do
      timer = described_class.new(timeout: 10)
      timer.start_cmd
      expect(timer.running?).to be true
    end

    it "produces a TimerTickMsg with matching id" do
      timer = described_class.new(timeout: 10)
      allow_any_instance_of(Object).to receive(:sleep)
      msg = timer.start_cmd.call
      expect(msg).to be_a(Petals::TimerTickMsg)
      expect(msg.id).to eq(timer.id)
    end

    it "returns nil if already timed out" do
      timer = described_class.new(timeout: 1, interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)
      # First tick preemptively times out (timeout == interval)
      msg = timer.start_cmd.call
      timer.update(msg)
      expect(timer.timed_out?).to be true
      expect(timer.start_cmd).to be_nil
    end

    it "returns nil if already running" do
      timer = described_class.new(timeout: 10)
      timer.start_cmd
      expect(timer.start_cmd).to be_nil
    end
  end

  describe "#update" do
    it "decrements remaining on matching TimerTickMsg" do
      timer = described_class.new(timeout: 10, interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)
      msg = timer.start_cmd.call
      cmd = timer.update(msg)
      expect(timer.remaining).to eq(9.0)
      expect(cmd).to respond_to(:call)
    end

    it "chains ticks while remaining > 0" do
      timer = described_class.new(timeout: 5, interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      msg = timer.start_cmd.call
      cmd = timer.update(msg)
      expect(timer.remaining).to eq(4.0)
      expect(cmd).to respond_to(:call)

      msg2 = cmd.call
      cmd2 = timer.update(msg2)
      expect(timer.remaining).to eq(3.0)
      expect(cmd2).to respond_to(:call)
    end

    it "stops at zero remaining and produces TimerTimeoutMsg" do
      timer = described_class.new(timeout: 2, interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      # Tick 1: 2 -> 1, still running
      msg = timer.start_cmd.call
      cmd = timer.update(msg)
      expect(timer.remaining).to eq(1.0)
      expect(timer.running?).to be true
      expect(cmd).to respond_to(:call)

      # Tick 2: 1 -> 0, timer stops and returns timeout_cmd
      msg2 = cmd.call
      cmd2 = timer.update(msg2)
      expect(timer.remaining).to eq(0.0)
      expect(timer.timed_out?).to be true
      expect(timer.running?).to be false
      expect(cmd2).to respond_to(:call)

      # The timeout_cmd produces TimerTimeoutMsg (no sleep)
      timeout_msg = cmd2.call
      expect(timeout_msg).to be_a(Petals::TimerTimeoutMsg)
      expect(timeout_msg.id).to eq(timer.id)
    end

    it "clamps remaining to zero when interval > remaining" do
      timer = described_class.new(timeout: 0.5, interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      # start_cmd always produces TimerTickMsg now
      msg = timer.start_cmd.call
      expect(msg).to be_a(Petals::TimerTickMsg)

      cmd = timer.update(msg)
      expect(timer.remaining).to eq(0.0)
      expect(timer.timed_out?).to be true
      expect(timer.running?).to be false
      # Returns timeout_cmd
      expect(cmd).to respond_to(:call)
      expect(cmd.call).to be_a(Petals::TimerTimeoutMsg)
    end

    it "ignores non-TimerTickMsg" do
      timer = described_class.new(timeout: 10)
      cmd = timer.update(Chamomile::KeyMsg.new(key: "a", mod: []))
      expect(cmd).to be_nil
      expect(timer.remaining).to eq(10.0)
    end

    it "ignores TimerTickMsg with wrong id" do
      timer = described_class.new(timeout: 10)
      timer.start_cmd
      msg = Petals::TimerTickMsg.new(id: "wrong", tag: 0, time: Time.now)
      cmd = timer.update(msg)
      expect(cmd).to be_nil
      expect(timer.remaining).to eq(10.0)
    end

    it "ignores TimerTickMsg with stale tag" do
      timer = described_class.new(timeout: 10)
      allow_any_instance_of(Object).to receive(:sleep)
      msg = timer.start_cmd.call
      timer.stop # bumps tag
      cmd = timer.update(msg)
      expect(cmd).to be_nil
      expect(timer.remaining).to eq(10.0)
    end

    it "ignores TimerTimeoutMsg (informational for parent)" do
      timer = described_class.new(timeout: 10)
      timer.start_cmd
      msg = Petals::TimerTimeoutMsg.new(id: timer.id, time: Time.now)
      cmd = timer.update(msg)
      expect(cmd).to be_nil
      expect(timer.remaining).to eq(10.0)
    end
  end

  describe "#stop" do
    it "sets running to false" do
      timer = described_class.new(timeout: 10)
      timer.start_cmd
      timer.stop
      expect(timer.running?).to be false
    end

    it "invalidates in-flight ticks" do
      timer = described_class.new(timeout: 10)
      allow_any_instance_of(Object).to receive(:sleep)
      msg = timer.start_cmd.call
      timer.stop
      cmd = timer.update(msg)
      expect(cmd).to be_nil
    end

    it "returns self for chaining" do
      timer = described_class.new(timeout: 10)
      expect(timer.stop).to equal(timer)
    end
  end

  describe "#toggle" do
    it "starts when stopped" do
      timer = described_class.new(timeout: 10)
      cmd = timer.toggle
      expect(timer.running?).to be true
      expect(cmd).to respond_to(:call)
    end

    it "stops when running" do
      timer = described_class.new(timeout: 10)
      timer.start_cmd
      cmd = timer.toggle
      expect(timer.running?).to be false
      expect(cmd).to be_nil
    end
  end

  describe "#reset" do
    it "restores remaining to timeout" do
      timer = described_class.new(timeout: 10)
      allow_any_instance_of(Object).to receive(:sleep)
      msg = timer.start_cmd.call
      timer.update(msg)
      expect(timer.remaining).to eq(9.0)
      timer.reset
      expect(timer.remaining).to eq(10.0)
    end

    it "stops the timer" do
      timer = described_class.new(timeout: 10)
      timer.start_cmd
      timer.reset
      expect(timer.running?).to be false
    end

    it "invalidates in-flight ticks" do
      timer = described_class.new(timeout: 10)
      allow_any_instance_of(Object).to receive(:sleep)
      msg = timer.start_cmd.call
      timer.reset
      cmd = timer.update(msg)
      expect(cmd).to be_nil
    end

    it "allows restart after timeout" do
      timer = described_class.new(timeout: 1, interval: 1.0)
      timer.instance_variable_set(:@remaining, 0.0)
      timer.instance_variable_set(:@running, false)
      expect(timer.timed_out?).to be true
      timer.reset
      expect(timer.timed_out?).to be false
      expect(timer.remaining).to eq(1.0)
      cmd = timer.start_cmd
      expect(cmd).to respond_to(:call)
    end

    it "returns self for chaining" do
      timer = described_class.new(timeout: 10)
      expect(timer.reset).to equal(timer)
    end
  end

  describe "#view" do
    it "shows full time at start" do
      timer = described_class.new(timeout: 90)
      expect(timer.view).to eq("01:30")
    end

    it "shows 00:00 when timed out" do
      timer = described_class.new(timeout: 10)
      timer.instance_variable_set(:@remaining, 0.0)
      expect(timer.view).to eq("00:00")
    end

    it "shows H:MM:SS for hours" do
      timer = described_class.new(timeout: 3661)
      expect(timer.view).to eq("1:01:01")
    end

    it "uses ceiling for fractional remaining" do
      timer = described_class.new(timeout: 10)
      timer.instance_variable_set(:@remaining, 59.3)
      expect(timer.view).to eq("01:00")
    end
  end

  describe "#timed_out?" do
    it "is false when remaining > 0" do
      timer = described_class.new(timeout: 10)
      expect(timer.timed_out?).to be false
    end

    it "is true when remaining is 0" do
      timer = described_class.new(timeout: 10)
      timer.instance_variable_set(:@remaining, 0.0)
      expect(timer.timed_out?).to be true
    end
  end

  describe "full countdown cycle" do
    it "counts down from 3 to timeout with correct state at each step" do
      timer = described_class.new(timeout: 3, interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      # Start: remaining=3
      msg = timer.start_cmd.call
      expect(msg).to be_a(Petals::TimerTickMsg)

      # Tick 1: 3 -> 2, still running
      cmd = timer.update(msg)
      expect(timer.remaining).to eq(2.0)
      expect(timer.running?).to be true
      expect(timer.timed_out?).to be false
      expect(cmd).to respond_to(:call)

      # Tick 2: 2 -> 1, still running
      msg2 = cmd.call
      expect(msg2).to be_a(Petals::TimerTickMsg)
      cmd2 = timer.update(msg2)
      expect(timer.remaining).to eq(1.0)
      expect(timer.running?).to be true
      expect(cmd2).to respond_to(:call)

      # Tick 3: 1 -> 0, timer stops, returns timeout_cmd
      msg3 = cmd2.call
      expect(msg3).to be_a(Petals::TimerTickMsg)
      cmd3 = timer.update(msg3)
      expect(timer.remaining).to eq(0.0)
      expect(timer.running?).to be false
      expect(timer.timed_out?).to be true
      expect(cmd3).to respond_to(:call)

      # timeout_cmd produces TimerTimeoutMsg (immediate, no sleep)
      timeout_msg = cmd3.call
      expect(timeout_msg).to be_a(Petals::TimerTimeoutMsg)
      expect(timeout_msg.id).to eq(timer.id)

      # TimerTimeoutMsg is ignored by update (informational for parent)
      cmd4 = timer.update(timeout_msg)
      expect(cmd4).to be_nil
    end
  end

  describe "edge cases" do
    it "handles timeout of 0" do
      timer = described_class.new(timeout: 0)
      expect(timer.timed_out?).to be true
      expect(timer.remaining).to eq(0.0)
      expect(timer.start_cmd).to be_nil
      expect(timer.view).to eq("00:00")
    end

    it "handles timeout smaller than interval" do
      timer = described_class.new(timeout: 0.5, interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      # start_cmd always produces TimerTickMsg
      msg = timer.start_cmd.call
      expect(msg).to be_a(Petals::TimerTickMsg)

      # update clamps remaining to 0 and returns timeout_cmd
      cmd = timer.update(msg)
      expect(timer.remaining).to eq(0.0)
      expect(timer.timed_out?).to be true
      expect(cmd.call).to be_a(Petals::TimerTimeoutMsg)
    end

    it "handles timeout equal to interval" do
      timer = described_class.new(timeout: 1, interval: 1.0)
      allow_any_instance_of(Object).to receive(:sleep)

      msg = timer.start_cmd.call
      cmd = timer.update(msg)
      expect(timer.remaining).to eq(0.0)
      expect(timer.timed_out?).to be true
      expect(timer.running?).to be false
      expect(cmd).to respond_to(:call)
      expect(cmd.call).to be_a(Petals::TimerTimeoutMsg)
    end

    it "toggle returns nil when timed out" do
      timer = described_class.new(timeout: 10)
      timer.instance_variable_set(:@remaining, 0.0)
      timer.instance_variable_set(:@running, false)
      expect(timer.toggle).to be_nil
    end

    it "ignores TimerTickMsg with future tag" do
      timer = described_class.new(timeout: 10)
      timer.start_cmd
      msg = Petals::TimerTickMsg.new(id: timer.id, tag: 999, time: Time.now)
      cmd = timer.update(msg)
      expect(cmd).to be_nil
    end
  end

  describe "multi-instance isolation" do
    it "each only responds to its own ticks" do
      t1 = described_class.new(timeout: 10)
      t2 = described_class.new(timeout: 10)
      allow_any_instance_of(Object).to receive(:sleep)

      msg1 = t1.start_cmd.call
      msg2 = t2.start_cmd.call

      cmd = t1.update(msg2)
      expect(cmd).to be_nil
      expect(t1.remaining).to eq(10.0)

      cmd = t1.update(msg1)
      expect(cmd).to respond_to(:call)
      expect(t1.remaining).to eq(9.0)
    end
  end
end
