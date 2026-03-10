# frozen_string_literal: true

RSpec.describe Petals::LogView do
  subject(:log) { described_class.new(max_lines: 100) }

  describe "#push" do
    it "adds lines" do
      log.push("line 1")
      log.push("line 2")
      expect(log.line_count).to eq(2)
    end

    it "enforces max_lines" do
      small_log = described_class.new(max_lines: 3)
      5.times { |i| small_log.push("line #{i}") }
      expect(small_log.line_count).to eq(5)
      output = small_log.render(width: 80, height: 10)
      expect(output).not_to include("line 0")
      expect(output).not_to include("line 1")
      expect(output).to include("line 4")
    end

    it "does not add lines when paused" do
      log.pause!
      log.push("should not appear")
      expect(log.line_count).to eq(0)
    end

    it "strips trailing newlines from pushed lines" do
      log.push("hello\n")
      output = log.render(width: 80, height: 1)
      expect(output).to eq("hello")
    end
  end

  describe "highlighting" do
    it "highlights SQL queries in blue" do
      log.push("SELECT * FROM users")
      output = log.render(width: 80, height: 5)
      expect(output).to include("\e[38;5;33m")
    end

    it "highlights errors in red" do
      log.push("NoMethodError: undefined method")
      output = log.render(width: 80, height: 5)
      expect(output).to include("\e[38;5;196m")
    end

    it "highlights HTTP requests in green" do
      log.push("GET /users 200 5ms")
      output = log.render(width: 80, height: 5)
      expect(output).to include("\e[38;5;34m")
    end
  end

  describe "scrolling" do
    before do
      20.times { |i| log.push("line #{i}") }
    end

    it "shows most recent lines by default (at bottom)" do
      output = log.render(width: 80, height: 5)
      expect(output).to include("line 19")
      expect(log).to be_at_bottom
    end

    it "scrolls up" do
      log.scroll_up(5)
      expect(log).not_to be_at_bottom
      output = log.render(width: 80, height: 5)
      expect(output).not_to include("line 19")
    end

    it "scrolls back to bottom" do
      log.scroll_up(10)
      log.scroll_to_bottom
      expect(log).to be_at_bottom
      output = log.render(width: 80, height: 5)
      expect(output).to include("line 19")
    end

    it "shows scroll indicator when not at bottom" do
      log.scroll_up(5)
      output = log.render(width: 80, height: 5)
      expect(output).to include("newer lines below")
    end

    it "does not show scroll indicator when viewport fits all content" do
      small_log = described_class.new(max_lines: 100)
      small_log.push("line 1")
      small_log.push("line 2")
      small_log.scroll_up(999)
      output = small_log.render(width: 80, height: 10)
      expect(output).not_to include("newer lines below")
    end
  end

  describe "#clear" do
    it "clears all lines" do
      log.push("hello")
      log.clear
      expect(log.line_count).to eq(0)
    end
  end

  describe "pause/resume" do
    it "can pause and resume" do
      log.pause!
      expect(log.paused).to be true
      log.resume!
      expect(log.paused).to be false
    end
  end
end
