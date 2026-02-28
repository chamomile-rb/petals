# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::Cursor do
  describe "initialization" do
    it "defaults to blink mode" do
      cursor = described_class.new
      expect(cursor.mode).to eq(described_class::MODE_BLINK)
    end

    it "defaults to BLINK_SPEED" do
      cursor = described_class.new
      expect(cursor.blink_speed).to eq(described_class::BLINK_SPEED)
    end

    it "defaults char to space" do
      cursor = described_class.new
      expect(cursor.char).to eq(" ")
    end

    it "starts not focused" do
      cursor = described_class.new
      expect(cursor.focused?).to be false
    end

    it "starts not blinked" do
      cursor = described_class.new
      expect(cursor.blinked).to be false
    end

    it "assigns unique IDs" do
      ids = 5.times.map { described_class.new.id }
      expect(ids.uniq.size).to eq(5)
    end

    it "accepts custom mode and blink_speed" do
      cursor = described_class.new(mode: described_class::MODE_STATIC, blink_speed: 1.0)
      expect(cursor.mode).to eq(described_class::MODE_STATIC)
      expect(cursor.blink_speed).to eq(1.0)
    end
  end

  describe "#focus" do
    it "sets focused to true" do
      cursor = described_class.new
      cursor.focus
      expect(cursor.focused?).to be true
    end

    it "sets blinked to false" do
      cursor = described_class.new
      cursor.blinked = true
      cursor.focus
      expect(cursor.blinked).to be false
    end

    it "returns blink_cmd in blink mode" do
      cursor = described_class.new(mode: described_class::MODE_BLINK)
      cmd = cursor.focus
      expect(cmd).to respond_to(:call)
    end

    it "returns nil in static mode" do
      cursor = described_class.new(mode: described_class::MODE_STATIC)
      cmd = cursor.focus
      expect(cmd).to be_nil
    end

    it "returns nil in hide mode" do
      cursor = described_class.new(mode: described_class::MODE_HIDE)
      cmd = cursor.focus
      expect(cmd).to be_nil
    end
  end

  describe "#blur" do
    it "sets focused to false" do
      cursor = described_class.new
      cursor.focus
      cursor.blur
      expect(cursor.focused?).to be false
    end

    it "sets blinked to true" do
      cursor = described_class.new
      cursor.focus
      cursor.blur
      expect(cursor.blinked).to be true
    end

    it "returns nil" do
      cursor = described_class.new
      cursor.focus
      expect(cursor.blur).to be_nil
    end

    it "invalidates in-flight blinks" do
      cursor = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = cursor.focus
      cursor.blur
      msg = cmd.call
      result = cursor.update(msg)
      expect(result).to be_nil
    end
  end

  describe "#blink_cmd" do
    it "returns a callable" do
      cursor = described_class.new
      expect(cursor.blink_cmd).to respond_to(:call)
    end

    it "produces a CursorBlinkMsg with matching id" do
      cursor = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = cursor.blink_cmd.call
      expect(msg).to be_a(Petals::CursorBlinkMsg)
      expect(msg.id).to eq(cursor.id)
    end

    it "sleeps for blink_speed" do
      cursor = described_class.new(blink_speed: 0.5)
      expect_any_instance_of(Object).to receive(:sleep).with(0.5)
      cursor.blink_cmd.call
    end
  end

  describe "#update" do
    it "toggles blinked on matching CursorBlinkMsg" do
      cursor = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = cursor.focus
      msg = cmd.call
      expect(cursor.blinked).to be false
      cursor.update(msg)
      expect(cursor.blinked).to be true
    end

    it "returns blink_cmd on matching message" do
      cursor = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = cursor.focus
      msg = cmd.call
      result = cursor.update(msg)
      expect(result).to respond_to(:call)
    end

    it "toggles back on second blink" do
      cursor = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = cursor.focus
      msg = cmd.call
      cmd2 = cursor.update(msg)
      msg2 = cmd2.call
      cursor.update(msg2)
      expect(cursor.blinked).to be false
    end

    it "ignores non-CursorBlinkMsg" do
      cursor = described_class.new
      cursor.focus
      result = cursor.update(Chamomile::KeyMsg.new(key: "a", mod: []))
      expect(result).to be_nil
    end

    it "ignores CursorBlinkMsg with wrong id" do
      cursor = described_class.new
      cursor.focus
      msg = Petals::CursorBlinkMsg.new(id: "wrong", tag: 0)
      result = cursor.update(msg)
      expect(result).to be_nil
    end

    it "ignores CursorBlinkMsg with stale tag" do
      cursor = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = cursor.focus
      msg = cmd.call
      cursor.blur
      cursor.focus
      result = cursor.update(msg)
      expect(result).to be_nil
    end
  end

  describe "#mode=" do
    it "changes the mode" do
      cursor = described_class.new
      cursor.mode = described_class::MODE_STATIC
      expect(cursor.mode).to eq(described_class::MODE_STATIC)
    end

    it "invalidates in-flight blinks" do
      cursor = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = cursor.focus
      msg = cmd.call
      cursor.mode = described_class::MODE_STATIC
      result = cursor.update(msg)
      expect(result).to be_nil
    end

    it "returns blink_cmd when switching to blink mode while focused" do
      cursor = described_class.new(mode: described_class::MODE_STATIC)
      cursor.focus
      cmd = cursor.send(:mode=, described_class::MODE_BLINK)
      expect(cmd).to respond_to(:call)
    end

    it "returns nil when switching to static mode" do
      cursor = described_class.new
      cursor.focus
      cmd = cursor.send(:mode=, described_class::MODE_STATIC)
      expect(cmd).to be_nil
    end

    it "returns nil when not focused" do
      cursor = described_class.new(mode: described_class::MODE_STATIC)
      cmd = cursor.send(:mode=, described_class::MODE_BLINK)
      expect(cmd).to be_nil
    end
  end

  describe "#view" do
    it "shows reverse-video char when visible" do
      cursor = described_class.new
      cursor.char = "X"
      cursor.blinked = false
      expect(cursor.view).to eq("\e[7mX\e[0m")
    end

    it "shows plain char when blinked" do
      cursor = described_class.new
      cursor.char = "X"
      cursor.blinked = true
      expect(cursor.view).to eq("X")
    end

    it "shows plain char in hide mode" do
      cursor = described_class.new(mode: described_class::MODE_HIDE)
      cursor.char = "X"
      cursor.blinked = false
      expect(cursor.view).to eq("X")
    end

    it "uses default space char" do
      cursor = described_class.new
      cursor.blinked = false
      expect(cursor.view).to eq("\e[7m \e[0m")
    end

    it "shows char in static mode when not blinked" do
      cursor = described_class.new(mode: described_class::MODE_STATIC)
      cursor.char = "A"
      cursor.blinked = false
      expect(cursor.view).to eq("\e[7mA\e[0m")
    end

    it "shows reverse-video in static mode after mode= while focused" do
      cursor = described_class.new
      cursor.focus
      cursor.mode = described_class::MODE_STATIC
      cursor.char = "X"
      expect(cursor.view).to eq("\e[7mX\e[0m")
    end

    it "shows plain char after mode= to static while unfocused" do
      cursor = described_class.new
      cursor.mode = described_class::MODE_STATIC
      cursor.char = "X"
      expect(cursor.view).to eq("X")
    end
  end

  describe "multiple cursors" do
    it "each only responds to its own blinks" do
      c1 = described_class.new
      c2 = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)

      cmd1 = c1.focus
      c2.focus

      msg1 = cmd1.call

      # c2 ignores c1's message
      result = c2.update(msg1)
      expect(result).to be_nil

      # c1 responds to its own message
      result = c1.update(msg1)
      expect(result).to respond_to(:call)
    end
  end
end
