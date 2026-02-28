# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Petals::List::DEFAULT_KEY_MAP" do
  let(:key_map) { Petals::List::DEFAULT_KEY_MAP }

  it "is frozen" do
    expect(key_map).to be_frozen
  end

  it "defines cursor_up action" do
    expect(key_map).to have_key(:cursor_up)
  end

  it "defines cursor_down action" do
    expect(key_map).to have_key(:cursor_down)
  end

  it "defines next_page action" do
    expect(key_map).to have_key(:next_page)
  end

  it "defines prev_page action" do
    expect(key_map).to have_key(:prev_page)
  end

  it "defines filter action" do
    expect(key_map).to have_key(:filter)
  end

  it "defines clear_filter action" do
    expect(key_map).to have_key(:clear_filter)
  end

  it "defines accept_filter action" do
    expect(key_map).to have_key(:accept_filter)
  end

  it "defines show_full_help action" do
    expect(key_map).to have_key(:show_full_help)
  end

  it "maps j to cursor_down" do
    msg = Chamomile::KeyMsg.new(key: "j", mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :cursor_down)).to be true
  end

  it "maps / to filter" do
    msg = Chamomile::KeyMsg.new(key: "/", mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :filter)).to be true
  end

  it "maps escape to clear_filter" do
    msg = Chamomile::KeyMsg.new(key: :escape, mod: [])
    expect(Petals::KeyBinding.key_matches?(msg, key_map, :clear_filter)).to be true
  end
end
