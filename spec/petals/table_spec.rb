# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::Table do
  def key(k, mod: []) = Chamomile::KeyMsg.new(key: k, mod: mod)

  let(:columns) do
    [
      Petals::Table::Column.new(title: "Name", width: 10),
      Petals::Table::Column.new(title: "Age", width: 5),
    ]
  end

  let(:rows) do
    [
      %w[Alice 30],
      %w[Bob 25],
      %w[Charlie 35],
      %w[Diana 28],
      %w[Eve 22],
    ]
  end

  subject(:table) { described_class.new(columns: columns, rows: rows, height: 3).focus }

  describe "initialization" do
    it "defaults cursor to 0" do
      expect(table.cursor).to eq(0)
    end

    it "defaults height to 10" do
      t = described_class.new
      expect(t.height).to eq(10)
    end

    it "starts unfocused" do
      t = described_class.new
      expect(t.focused?).to be false
    end

    it "accepts columns and rows" do
      expect(table.columns).to eq(columns)
      expect(table.rows).to eq(rows)
    end
  end

  describe "Column" do
    it "is a Data.define with title and width" do
      col = Petals::Table::Column.new(title: "Name", width: 10)
      expect(col.title).to eq("Name")
      expect(col.width).to eq(10)
    end

    it "is immutable" do
      col = Petals::Table::Column.new(title: "Name", width: 10)
      expect(col).to be_frozen
    end
  end

  describe "#selected_row" do
    it "returns the row at cursor" do
      expect(table.selected_row).to eq(%w[Alice 30])
    end

    it "returns nil for empty rows" do
      t = described_class.new(columns: columns)
      expect(t.selected_row).to be_nil
    end

    it "updates after cursor movement" do
      table.move_down
      expect(table.selected_row).to eq(%w[Bob 25])
    end
  end

  describe "#move_up / #move_down" do
    it "moves cursor down" do
      table.move_down
      expect(table.cursor).to eq(1)
    end

    it "moves cursor up" do
      table.move_down(2)
      table.move_up
      expect(table.cursor).to eq(1)
    end

    it "clamps at top" do
      table.move_up
      expect(table.cursor).to eq(0)
    end

    it "clamps at bottom" do
      table.move_down(100)
      expect(table.cursor).to eq(4)
    end

    it "moves by n" do
      table.move_down(3)
      expect(table.cursor).to eq(3)
    end
  end

  describe "#goto_top / #goto_bottom" do
    it "goes to first row" do
      table.move_down(3)
      table.goto_top
      expect(table.cursor).to eq(0)
    end

    it "goes to last row" do
      table.goto_bottom
      expect(table.cursor).to eq(4)
    end
  end

  describe "#cursor=" do
    it "sets cursor position" do
      table.cursor = 3
      expect(table.cursor).to eq(3)
    end

    it "clamps to valid range" do
      table.cursor = 100
      expect(table.cursor).to eq(4)
    end

    it "clamps negative to 0" do
      table.cursor = -5
      expect(table.cursor).to eq(0)
    end
  end

  describe "focus" do
    it "#focus returns self" do
      t = described_class.new
      expect(t.focus).to equal(t)
    end

    it "#blur returns self" do
      expect(table.blur).to equal(table)
    end

    it "ignores keys when not focused" do
      t = described_class.new(columns: columns, rows: rows)
      t.update(key(:down))
      expect(t.cursor).to eq(0)
    end

    it "processes keys when focused" do
      table.update(key(:down))
      expect(table.cursor).to eq(1)
    end
  end

  describe "#update" do
    it "moves down on j" do
      table.update(key("j"))
      expect(table.cursor).to eq(1)
    end

    it "moves up on k" do
      table.cursor = 2
      table.update(key("k"))
      expect(table.cursor).to eq(1)
    end

    it "moves down on down arrow" do
      table.update(key(:down))
      expect(table.cursor).to eq(1)
    end

    it "moves up on up arrow" do
      table.cursor = 2
      table.update(key(:up))
      expect(table.cursor).to eq(1)
    end

    it "pages down on page_down" do
      table.update(key(:page_down))
      expect(table.cursor).to eq(3)
    end

    it "pages up on page_up" do
      table.cursor = 4
      table.update(key(:page_up))
      expect(table.cursor).to eq(1)
    end

    it "goes to top on g" do
      table.cursor = 3
      table.update(key("g"))
      expect(table.cursor).to eq(0)
    end

    it "goes to bottom on G" do
      table.update(key("G", mod: [:shift]))
      expect(table.cursor).to eq(4)
    end

    it "returns nil" do
      expect(table.update(key(:down))).to be_nil
    end

    it "ignores non-KeyMsg" do
      table.update(Chamomile::TickMsg.new(time: Time.now))
      expect(table.cursor).to eq(0)
    end
  end

  describe "#rows=" do
    it "clamps cursor when rows shrink" do
      table.cursor = 4
      table.rows = [%w[Only 1]]
      expect(table.cursor).to eq(0)
    end

    it "handles empty rows" do
      table.rows = []
      expect(table.cursor).to eq(0)
      expect(table.selected_row).to be_nil
    end
  end

  describe "#view" do
    it "renders header" do
      view = table.view
      first_line = view.split("\n").first
      expect(first_line).to include("Name")
      expect(first_line).to include("Age")
    end

    it "renders separator" do
      view = table.view
      lines = view.split("\n")
      expect(lines[1]).to include("\u2500")
    end

    it "renders visible rows" do
      view = table.view
      expect(view).to include("Alice")
      expect(view).to include("Bob")
      expect(view).to include("Charlie")
    end

    it "highlights selected row with reverse video" do
      view = table.view
      expect(view).to include("\e[7m")
    end

    it "truncates long cell values" do
      table.rows = [%w[VeryLongNameThatExceedsWidth 30]]
      view = table.view
      expect(view).to include("\u2026") # truncation indicator
    end

    it "pads short cell values" do
      view = table.view
      # "Alice" padded to width 10
      expect(view).to include("Alice     ")
    end

    it "scrolls viewport to keep cursor visible" do
      table.cursor = 4 # last row, viewport shows 3 rows
      view = table.view
      expect(view).to include("Eve")
      expect(view).not_to include("Alice")
    end

    it "shows selected row after scrolling" do
      table.cursor = 4
      view = table.view
      expect(view).to include("\e[7m")
      expect(view).to include("Eve")
    end

    it "handles empty columns" do
      t = described_class.new(rows: rows)
      view = t.view
      expect(view).not_to be_nil
    end

    it "handles empty rows" do
      t = described_class.new(columns: columns)
      view = t.view
      expect(view).to include("Name")
    end
  end

  describe "edge cases" do
    it "handles single row" do
      t = described_class.new(columns: columns, rows: [%w[Solo 1]], height: 3).focus
      expect(t.selected_row).to eq(%w[Solo 1])
      t.move_down
      expect(t.cursor).to eq(0)
    end

    it "handles cursor at boundaries during scrolling" do
      table.cursor = 2  # at bottom of visible window
      table.move_down   # should scroll
      expect(table.cursor).to eq(3)
      expect(table.view).to include("Diana")
    end
  end
end
