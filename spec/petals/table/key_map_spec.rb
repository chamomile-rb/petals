# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Petals::Table::DEFAULT_KEY_MAP" do
  let(:key_map) { Petals::Table::DEFAULT_KEY_MAP }

  it "is frozen" do
    expect(key_map).to be_frozen
  end

  it "defines up action" do
    expect(key_map).to have_key(:up)
  end

  it "defines down action" do
    expect(key_map).to have_key(:down)
  end

  it "defines page_up action" do
    expect(key_map).to have_key(:page_up)
  end

  it "defines page_down action" do
    expect(key_map).to have_key(:page_down)
  end

  it "defines goto_top action" do
    expect(key_map).to have_key(:goto_top)
  end

  it "defines goto_bottom action" do
    expect(key_map).to have_key(:goto_bottom)
  end

  it "maps j to down" do
    msg = Chamomile::KeyMsg.new(key: "j", mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :down)).to be true
  end

  it "maps k to up" do
    msg = Chamomile::KeyMsg.new(key: "k", mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :up)).to be true
  end
end
