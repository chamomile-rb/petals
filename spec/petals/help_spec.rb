# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::Help do
  subject(:help) { described_class.new }

  let(:bindings) do
    [
      { key: "q", desc: "quit" },
      { key: "?", desc: "help" },
      { key: "j/k", desc: "up/down" },
    ]
  end

  describe "initialization" do
    it "defaults width to 80" do
      expect(help.width).to eq(80)
    end

    it "defaults show_all to false" do
      expect(help.show_all).to be false
    end

    it "has a short separator" do
      expect(help.short_separator).to eq(" \u2022 ")
    end

    it "accepts custom width" do
      h = described_class.new(width: 40)
      expect(h.width).to eq(40)
    end
  end

  describe "#short_help_view" do
    it "renders bindings in a single line" do
      result = help.short_help_view(bindings)
      expect(result).to eq("q quit \u2022 ? help \u2022 j/k up/down")
    end

    it "returns empty string for empty bindings" do
      expect(help.short_help_view([])).to eq("")
    end

    it "filters disabled bindings" do
      disabled = [
        { key: "q", desc: "quit" },
        { key: "?", desc: "help", enabled: false },
      ]
      result = help.short_help_view(disabled)
      expect(result).to eq("q quit")
    end

    it "truncates with ellipsis when exceeding width" do
      help.width = 15
      result = help.short_help_view(bindings)
      expect(result).to include("\u2026")
      expect(result.length).to be <= 15
    end

    it "does not truncate when width is 0" do
      help.width = 0
      result = help.short_help_view(bindings)
      expect(result).not_to include("\u2026")
    end

    it "handles single binding" do
      result = help.short_help_view([{ key: "q", desc: "quit" }])
      expect(result).to eq("q quit")
    end

    it "handles all disabled bindings" do
      disabled = [
        { key: "q", desc: "quit", enabled: false },
        { key: "?", desc: "help", enabled: false },
      ]
      expect(help.short_help_view(disabled)).to eq("")
    end
  end

  describe "#full_help_view" do
    it "renders groups as columns" do
      groups = [
        [{ key: "q", desc: "quit" }, { key: "?", desc: "help" }],
        [{ key: "j", desc: "down" }, { key: "k", desc: "up" }],
      ]
      result = help.full_help_view(groups)
      lines = result.split("\n")
      expect(lines.length).to eq(2)
      expect(lines[0]).to include("q  quit")
      expect(lines[0]).to include("j  down")
      expect(lines[1]).to include("?  help")
      expect(lines[1]).to include("k  up")
    end

    it "handles groups of different lengths" do
      groups = [
        [{ key: "q", desc: "quit" }, { key: "?", desc: "help" }],
        [{ key: "j", desc: "down" }],
      ]
      result = help.full_help_view(groups)
      lines = result.split("\n")
      expect(lines.length).to eq(2)
      expect(lines[1]).to include("?  help")
    end

    it "returns empty string for empty groups" do
      expect(help.full_help_view([])).to eq("")
    end

    it "returns empty string when all groups are empty" do
      expect(help.full_help_view([[], []])).to eq("")
    end

    it "filters disabled bindings in groups" do
      groups = [
        [{ key: "q", desc: "quit" }, { key: "?", desc: "help", enabled: false }],
      ]
      result = help.full_help_view(groups)
      expect(result).to include("q  quit")
      expect(result).not_to include("?  help")
    end

    it "skips entirely disabled groups" do
      groups = [
        [{ key: "q", desc: "quit", enabled: false }],
        [{ key: "j", desc: "down" }],
      ]
      result = help.full_help_view(groups)
      lines = result.split("\n")
      expect(lines.length).to eq(1)
      expect(lines[0]).to eq("j  down")
    end
  end

  describe "#view" do
    it "dispatches to short_help_view when show_all is false" do
      result = help.view(bindings)
      expect(result).to eq(help.short_help_view(bindings))
    end

    it "dispatches to full_help_view when show_all is true" do
      help.show_all = true
      groups = [bindings]
      result = help.view(groups)
      expect(result).to eq(help.full_help_view(groups))
    end

    it "wraps flat bindings in array for full view" do
      help.show_all = true
      result = help.view(bindings)
      expect(result).to eq(help.full_help_view([bindings]))
    end

    it "flattens groups for short view" do
      groups = [
        [{ key: "q", desc: "quit" }],
        [{ key: "j", desc: "down" }],
      ]
      result = help.view(groups)
      expect(result).to include("q quit")
      expect(result).to include("j down")
    end
  end

  describe "#update" do
    it "returns nil for any message" do
      expect(help.update(Chamomile::KeyMsg.new(key: "a", mod: []))).to be_nil
    end

    it "returns nil for nil" do
      expect(help.update(nil)).to be_nil
    end
  end
end
