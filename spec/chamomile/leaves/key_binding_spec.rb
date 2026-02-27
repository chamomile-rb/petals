# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chamomile::Leaves::KeyBinding do
  let(:key_map) do
    {
      move_left: [[:left, []], ["h", []], ["b", [:ctrl]]],
      move_right: [[:right, []], ["l", []], ["f", [:ctrl]]],
      delete: [[:backspace, %i[ctrl shift]]],
      quit: [["q", []]],
    }
  end

  describe ".normalize" do
    it "sorts and freezes mod arrays" do
      raw = { action: [[:key, %i[shift ctrl]]] }
      normalized = described_class.normalize(raw)
      expect(normalized[:action][0][1]).to eq(%i[ctrl shift])
      expect(normalized[:action][0][1]).to be_frozen
    end

    it "freezes the bindings and the map" do
      normalized = described_class.normalize({ a: [["x", []]] })
      expect(normalized).to be_frozen
      expect(normalized[:a]).to be_frozen
    end

    it "handles nil mods" do
      normalized = described_class.normalize({ a: [["x"]] })
      expect(normalized[:a][0][1]).to eq([])
    end
  end

  describe ".key_matches?" do
    it "matches a symbol key with no modifiers" do
      msg = Chamomile::KeyMsg.new(key: :left, mod: [])
      expect(described_class.key_matches?(msg, key_map, :move_left)).to be true
    end

    it "matches a string key with no modifiers" do
      msg = Chamomile::KeyMsg.new(key: "h", mod: [])
      expect(described_class.key_matches?(msg, key_map, :move_left)).to be true
    end

    it "matches a key with a modifier" do
      msg = Chamomile::KeyMsg.new(key: "b", mod: [:ctrl])
      expect(described_class.key_matches?(msg, key_map, :move_left)).to be true
    end

    it "matches modifiers regardless of order" do
      msg = Chamomile::KeyMsg.new(key: :backspace, mod: %i[shift ctrl])
      expect(described_class.key_matches?(msg, key_map, :delete)).to be true
    end

    it "does not match wrong key" do
      msg = Chamomile::KeyMsg.new(key: "x", mod: [])
      expect(described_class.key_matches?(msg, key_map, :move_left)).to be false
    end

    it "does not match wrong modifiers" do
      msg = Chamomile::KeyMsg.new(key: "b", mod: [])
      expect(described_class.key_matches?(msg, key_map, :move_left)).to be false
    end

    it "does not match wrong action" do
      msg = Chamomile::KeyMsg.new(key: :left, mod: [])
      expect(described_class.key_matches?(msg, key_map, :move_right)).to be false
    end

    it "returns false for unknown action" do
      msg = Chamomile::KeyMsg.new(key: :left, mod: [])
      expect(described_class.key_matches?(msg, key_map, :nonexistent)).to be false
    end

    it "returns false for non-KeyMsg" do
      expect(described_class.key_matches?(Chamomile::QuitMsg.new, key_map, :quit)).to be false
    end

    it "returns false for nil message" do
      expect(described_class.key_matches?(nil, key_map, :quit)).to be false
    end

    it "works with normalized key maps" do
      normalized = described_class.normalize(key_map)
      msg = Chamomile::KeyMsg.new(key: :backspace, mod: %i[shift ctrl])
      expect(described_class.key_matches?(msg, normalized, :delete)).to be true
    end

    it "handles multiple bindings for the same action" do
      msg1 = Chamomile::KeyMsg.new(key: :right, mod: [])
      msg2 = Chamomile::KeyMsg.new(key: "l", mod: [])
      msg3 = Chamomile::KeyMsg.new(key: "f", mod: [:ctrl])
      expect(described_class.key_matches?(msg1, key_map, :move_right)).to be true
      expect(described_class.key_matches?(msg2, key_map, :move_right)).to be true
      expect(described_class.key_matches?(msg3, key_map, :move_right)).to be true
    end
  end
end
