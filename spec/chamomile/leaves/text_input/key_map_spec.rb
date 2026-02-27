# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chamomile::Leaves::TextInput::DEFAULT_KEY_MAP do
  subject(:key_map) { described_class }

  it "is frozen" do
    expect(key_map).to be_frozen
  end

  it "defines 12 actions" do
    expect(key_map.size).to eq(12)
  end

  %i[
    character_forward character_backward
    word_forward word_backward
    delete_word_backward delete_word_forward
    delete_after_cursor delete_before_cursor
    delete_char_backward delete_char_forward
    line_start line_end
  ].each do |action|
    it "has bindings for #{action}" do
      expect(key_map[action]).to be_an(Array)
      expect(key_map[action]).not_to be_empty
    end
  end

  it "maps character_forward to right arrow and ctrl+f" do
    expect(key_map[:character_forward]).to include([:right, []])
    expect(key_map[:character_forward]).to include(["f", [:ctrl]])
  end

  it "maps character_backward to left arrow and ctrl+b" do
    expect(key_map[:character_backward]).to include([:left, []])
    expect(key_map[:character_backward]).to include(["b", [:ctrl]])
  end

  it "maps word_forward to alt+right, ctrl+right, and alt+f" do
    expect(key_map[:word_forward]).to include([:right, [:alt]])
    expect(key_map[:word_forward]).to include([:right, [:ctrl]])
    expect(key_map[:word_forward]).to include(["f", [:alt]])
  end

  it "maps word_backward to alt+left, ctrl+left, and alt+b" do
    expect(key_map[:word_backward]).to include([:left, [:alt]])
    expect(key_map[:word_backward]).to include([:left, [:ctrl]])
    expect(key_map[:word_backward]).to include(["b", [:alt]])
  end

  it "maps line_start to home and ctrl+a" do
    expect(key_map[:line_start]).to include([:home, []])
    expect(key_map[:line_start]).to include(["a", [:ctrl]])
  end

  it "maps line_end to end and ctrl+e" do
    expect(key_map[:line_end]).to include([:end_key, []])
    expect(key_map[:line_end]).to include(["e", [:ctrl]])
  end

  it "maps delete_char_backward to backspace and ctrl+h" do
    expect(key_map[:delete_char_backward]).to include([:backspace, []])
    expect(key_map[:delete_char_backward]).to include(["h", [:ctrl]])
  end

  it "maps delete_char_forward to delete and ctrl+d" do
    expect(key_map[:delete_char_forward]).to include([:delete, []])
    expect(key_map[:delete_char_forward]).to include(["d", [:ctrl]])
  end

  it "maps delete_word_backward to alt+backspace and ctrl+w" do
    expect(key_map[:delete_word_backward]).to include([:backspace, [:alt]])
    expect(key_map[:delete_word_backward]).to include(["w", [:ctrl]])
  end

  it "maps delete_word_forward to alt+delete and alt+d" do
    expect(key_map[:delete_word_forward]).to include([:delete, [:alt]])
    expect(key_map[:delete_word_forward]).to include(["d", [:alt]])
  end
end
