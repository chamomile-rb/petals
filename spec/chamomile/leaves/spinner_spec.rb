# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chamomile::Leaves::Spinner do
  describe "initialization" do
    it "defaults to LINE spinner type" do
      spinner = described_class.new
      expect(spinner.spinner_type).to eq(Chamomile::Leaves::Spinners::LINE)
    end

    it "accepts a custom type" do
      spinner = described_class.new(type: Chamomile::Leaves::Spinners::DOT)
      expect(spinner.spinner_type).to eq(Chamomile::Leaves::Spinners::DOT)
    end

    it "assigns unique IDs" do
      ids = 5.times.map { described_class.new.id }
      expect(ids.uniq.size).to eq(5)
    end

    it "starts at frame 0" do
      spinner = described_class.new
      expect(spinner.view).to eq("|")
    end
  end

  describe "#view" do
    it "returns the current frame" do
      spinner = described_class.new(type: Chamomile::Leaves::Spinners::ELLIPSIS)
      expect(spinner.view).to eq("")
    end
  end

  describe "#tick_cmd" do
    it "returns a callable" do
      spinner = described_class.new
      expect(spinner.tick_cmd).to respond_to(:call)
    end

    it "produces a SpinnerTickMsg with matching id" do
      spinner = described_class.new
      # Stub sleep to avoid waiting
      allow_any_instance_of(Object).to receive(:sleep)
      msg = spinner.tick_cmd.call
      expect(msg).to be_a(Chamomile::Leaves::SpinnerTickMsg)
      expect(msg.id).to eq(spinner.id)
    end
  end

  describe "#update" do
    it "advances frame on matching SpinnerTickMsg" do
      spinner = described_class.new
      # Capture tag before update
      allow_any_instance_of(Object).to receive(:sleep)
      msg = spinner.tick_cmd.call
      result, cmd = spinner.update(msg)
      expect(result).to equal(spinner)
      expect(spinner.view).to eq("/") # frame 1 of LINE
      expect(cmd).to respond_to(:call)
    end

    it "wraps around at last frame" do
      spinner = described_class.new # LINE has 4 frames
      allow_any_instance_of(Object).to receive(:sleep)

      4.times do
        msg = spinner.tick_cmd.call
        spinner.update(msg)
      end

      expect(spinner.view).to eq("|") # back to frame 0
    end

    it "ignores non-SpinnerTickMsg" do
      spinner = described_class.new
      _, cmd = spinner.update(Chamomile::KeyMsg.new(key: "a", mod: []))
      expect(cmd).to be_nil
      expect(spinner.view).to eq("|")
    end

    it "ignores SpinnerTickMsg with wrong id" do
      spinner = described_class.new
      msg = Chamomile::Leaves::SpinnerTickMsg.new(id: -999, tag: 0, time: Time.now)
      _, cmd = spinner.update(msg)
      expect(cmd).to be_nil
      expect(spinner.view).to eq("|")
    end

    it "ignores SpinnerTickMsg with stale tag" do
      spinner = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = spinner.tick_cmd.call
      spinner.reset # bumps tag, invalidating msg
      _, cmd = spinner.update(msg)
      expect(cmd).to be_nil
      expect(spinner.view).to eq("|")
    end
  end

  describe "#reset" do
    it "resets frame to 0" do
      spinner = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = spinner.tick_cmd.call
      spinner.update(msg)
      expect(spinner.view).to eq("/")
      spinner.reset
      expect(spinner.view).to eq("|")
    end

    it "returns self for chaining" do
      spinner = described_class.new
      expect(spinner.reset).to equal(spinner)
    end

    it "invalidates in-flight ticks" do
      spinner = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = spinner.tick_cmd.call
      spinner.reset
      _, cmd = spinner.update(msg)
      expect(cmd).to be_nil
    end
  end

  describe "#spinner_type=" do
    it "changes the spinner type" do
      spinner = described_class.new
      spinner.spinner_type = Chamomile::Leaves::Spinners::DOT
      expect(spinner.spinner_type).to eq(Chamomile::Leaves::Spinners::DOT)
      expect(spinner.view).to eq("⣾")
    end

    it "resets frame to 0" do
      spinner = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = spinner.tick_cmd.call
      spinner.update(msg)
      spinner.spinner_type = Chamomile::Leaves::Spinners::DOT
      expect(spinner.view).to eq("⣾")
    end

    it "invalidates in-flight ticks" do
      spinner = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)
      msg = spinner.tick_cmd.call
      spinner.spinner_type = Chamomile::Leaves::Spinners::DOT
      _, cmd = spinner.update(msg)
      expect(cmd).to be_nil
    end
  end

  describe "multiple spinners" do
    it "each only responds to its own ticks" do
      s1 = described_class.new
      s2 = described_class.new
      allow_any_instance_of(Object).to receive(:sleep)

      msg1 = s1.tick_cmd.call
      msg2 = s2.tick_cmd.call

      # s1 ignores s2's tick
      _, cmd = s1.update(msg2)
      expect(cmd).to be_nil
      expect(s1.view).to eq("|")

      # s1 responds to its own tick
      _, cmd = s1.update(msg1)
      expect(cmd).to respond_to(:call)
      expect(s1.view).to eq("/")
    end
  end
end
