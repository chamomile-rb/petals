# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Petals::TextArea::DEFAULT_KEY_MAP" do
  let(:key_map) { Petals::TextArea::DEFAULT_KEY_MAP }

  it "is frozen" do
    expect(key_map).to be_frozen
  end

  it "defines line_up action" do
    expect(key_map).to have_key(:line_up)
  end

  it "defines line_down action" do
    expect(key_map).to have_key(:line_down)
  end

  it "defines new_line action" do
    expect(key_map).to have_key(:new_line)
  end

  it "defines character_forward action" do
    expect(key_map).to have_key(:character_forward)
  end

  it "defines character_backward action" do
    expect(key_map).to have_key(:character_backward)
  end

  it "defines delete_char_backward action" do
    expect(key_map).to have_key(:delete_char_backward)
  end

  it "maps enter to new_line" do
    msg = Chamomile::KeyMsg.new(key: :enter, mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :new_line)).to be true
  end

  it "maps up arrow to line_up" do
    msg = Chamomile::KeyMsg.new(key: :up, mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :line_up)).to be true
  end

  it "maps down arrow to line_down" do
    msg = Chamomile::KeyMsg.new(key: :down, mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :line_down)).to be true
  end
end
