# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::SpinnerType do
  it "is a Data.define with frames and fps" do
    t = described_class.new(frames: %w[a b], fps: 5)
    expect(t.frames).to eq(%w[a b])
    expect(t.fps).to eq(5)
  end

  it "is immutable" do
    t = described_class.new(frames: %w[a b], fps: 5)
    expect(t).to be_frozen
  end
end

RSpec.describe Petals::Spinners do
  all_types = {
    LINE: { frame_count: 4, fps: 10 },
    DOT: { frame_count: 8, fps: 10 },
    MINI_DOT: { frame_count: 10, fps: 12 },
    JUMP: { frame_count: 7, fps: 10 },
    PULSE: { frame_count: 4, fps: 8 },
    POINTS: { frame_count: 4, fps: 7 },
    GLOBE: { frame_count: 3, fps: 4 },
    MOON: { frame_count: 8, fps: 8 },
    MONKEY: { frame_count: 3, fps: 3 },
    METER: { frame_count: 7, fps: 7 },
    HAMBURGER: { frame_count: 4, fps: 3 },
    ELLIPSIS: { frame_count: 4, fps: 3 },
  }.freeze

  all_types.each do |name, expected|
    describe name.to_s do
      let(:spinner_type) { described_class.const_get(name) }

      it "is a SpinnerType" do
        expect(spinner_type).to be_a(Petals::SpinnerType)
      end

      it "has #{expected[:frame_count]} frames" do
        expect(spinner_type.frames.size).to eq(expected[:frame_count])
      end

      it "has fps of #{expected[:fps]}" do
        expect(spinner_type.fps).to eq(expected[:fps])
      end
    end
  end

  it "defines exactly 12 spinner types" do
    types = described_class.constants.select { |c| described_class.const_get(c).is_a?(Petals::SpinnerType) }
    expect(types.size).to eq(12)
  end
end
