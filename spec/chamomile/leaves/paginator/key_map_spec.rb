# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Paginator::DEFAULT_KEY_MAP" do
  let(:key_map) { Chamomile::Leaves::Paginator::DEFAULT_KEY_MAP }

  def key(k, mod: []) = Chamomile::KeyMsg.new(key: k, mod: mod)

  describe ":prev_page" do
    it "matches left arrow" do
      expect(Chamomile::Leaves::KeyBinding.key_matches?(key(:left), key_map, :prev_page)).to be true
    end

    it "matches h key" do
      expect(Chamomile::Leaves::KeyBinding.key_matches?(key("h"), key_map, :prev_page)).to be true
    end

    it "matches page_up" do
      expect(Chamomile::Leaves::KeyBinding.key_matches?(key(:page_up), key_map, :prev_page)).to be true
    end
  end

  describe ":next_page" do
    it "matches right arrow" do
      expect(Chamomile::Leaves::KeyBinding.key_matches?(key(:right), key_map, :next_page)).to be true
    end

    it "matches l key" do
      expect(Chamomile::Leaves::KeyBinding.key_matches?(key("l"), key_map, :next_page)).to be true
    end

    it "matches page_down" do
      expect(Chamomile::Leaves::KeyBinding.key_matches?(key(:page_down), key_map, :next_page)).to be true
    end
  end
end
