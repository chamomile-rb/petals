# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Petals::FilePicker::DEFAULT_KEY_MAP" do
  let(:key_map) { Petals::FilePicker::DEFAULT_KEY_MAP }

  it "is frozen" do
    expect(key_map).to be_frozen
  end

  it "defines up action" do
    expect(key_map).to have_key(:up)
  end

  it "defines down action" do
    expect(key_map).to have_key(:down)
  end

  it "defines open action" do
    expect(key_map).to have_key(:open)
  end

  it "defines back action" do
    expect(key_map).to have_key(:back)
  end

  it "defines toggle_hidden action" do
    expect(key_map).to have_key(:toggle_hidden)
  end

  it "maps enter to open" do
    msg = Chamomile::KeyMsg.new(key: :enter, mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :open)).to be true
  end

  it "maps backspace to back" do
    msg = Chamomile::KeyMsg.new(key: :backspace, mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :back)).to be true
  end

  it "maps . to toggle_hidden" do
    msg = Chamomile::KeyMsg.new(key: ".", mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :toggle_hidden)).to be true
  end
end
