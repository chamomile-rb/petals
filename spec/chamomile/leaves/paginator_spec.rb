# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chamomile::Leaves::Paginator do
  def key(k, mod: []) = Chamomile::KeyMsg.new(key: k, mod: mod)

  describe "initialization" do
    it "defaults to 1 total page" do
      p = described_class.new
      expect(p.total_pages).to eq(1)
    end

    it "defaults to page 0" do
      p = described_class.new
      expect(p.page).to eq(0)
    end

    it "defaults to dot type" do
      p = described_class.new
      expect(p.type).to eq(described_class::TYPE_DOT)
    end

    it "defaults to 0 per_page" do
      p = described_class.new
      expect(p.per_page).to eq(0)
    end

    it "accepts custom options" do
      p = described_class.new(total_pages: 5, per_page: 10, type: described_class::TYPE_ARABIC)
      expect(p.total_pages).to eq(5)
      expect(p.per_page).to eq(10)
      expect(p.type).to eq(described_class::TYPE_ARABIC)
    end

    it "clamps total_pages to minimum of 1" do
      p = described_class.new(total_pages: 0)
      expect(p.total_pages).to eq(1)
    end
  end

  describe "#page=" do
    it "sets the page" do
      p = described_class.new(total_pages: 5)
      p.page = 3
      expect(p.page).to eq(3)
    end

    it "clamps to 0 when negative" do
      p = described_class.new(total_pages: 5)
      p.page = -1
      expect(p.page).to eq(0)
    end

    it "clamps to last page when too high" do
      p = described_class.new(total_pages: 5)
      p.page = 10
      expect(p.page).to eq(4)
    end
  end

  describe "#total_pages=" do
    it "updates total pages" do
      p = described_class.new(total_pages: 5)
      p.total_pages = 10
      expect(p.total_pages).to eq(10)
    end

    it "clamps page if now out of bounds" do
      p = described_class.new(total_pages: 5)
      p.page = 4
      p.total_pages = 3
      expect(p.page).to eq(2)
    end

    it "clamps total_pages to minimum of 1" do
      p = described_class.new(total_pages: 5)
      p.total_pages = 0
      expect(p.total_pages).to eq(1)
    end
  end

  describe "#prev_page / #next_page" do
    it "navigates forward" do
      p = described_class.new(total_pages: 3)
      p.next_page
      expect(p.page).to eq(1)
    end

    it "navigates backward" do
      p = described_class.new(total_pages: 3)
      p.page = 2
      p.prev_page
      expect(p.page).to eq(1)
    end

    it "does not go below 0" do
      p = described_class.new(total_pages: 3)
      p.prev_page
      expect(p.page).to eq(0)
    end

    it "does not exceed last page" do
      p = described_class.new(total_pages: 3)
      p.page = 2
      p.next_page
      expect(p.page).to eq(2)
    end

    it "returns self for chaining" do
      p = described_class.new(total_pages: 3)
      expect(p.next_page).to equal(p)
      expect(p.prev_page).to equal(p)
    end
  end

  describe "#on_first_page? / #on_last_page?" do
    it "is on first page at start" do
      p = described_class.new(total_pages: 3)
      expect(p.on_first_page?).to be true
      expect(p.on_last_page?).to be false
    end

    it "is on last page at end" do
      p = described_class.new(total_pages: 3)
      p.page = 2
      expect(p.on_first_page?).to be false
      expect(p.on_last_page?).to be true
    end

    it "is both on single page" do
      p = described_class.new(total_pages: 1)
      expect(p.on_first_page?).to be true
      expect(p.on_last_page?).to be true
    end
  end

  describe "#slice_bounds" do
    it "returns correct bounds for first page" do
      p = described_class.new(total_pages: 3, per_page: 5)
      expect(p.slice_bounds(13)).to eq([0, 5])
    end

    it "returns correct bounds for middle page" do
      p = described_class.new(total_pages: 3, per_page: 5)
      p.page = 1
      expect(p.slice_bounds(13)).to eq([5, 5])
    end

    it "returns partial length for last page" do
      p = described_class.new(total_pages: 3, per_page: 5)
      p.page = 2
      expect(p.slice_bounds(13)).to eq([10, 3])
    end

    it "returns [0, 0] when per_page is 0" do
      p = described_class.new(total_pages: 3, per_page: 0)
      expect(p.slice_bounds(13)).to eq([0, 0])
    end

    it "returns [0, 0] when total_items is 0" do
      p = described_class.new(total_pages: 3, per_page: 5)
      expect(p.slice_bounds(0)).to eq([0, 0])
    end

    it "handles page beyond items" do
      p = described_class.new(total_pages: 5, per_page: 5)
      p.page = 4
      expect(p.slice_bounds(13)).to eq([13, 0])
    end
  end

  describe "#total_pages_from_items" do
    it "calculates from item count and per_page" do
      p = described_class.new(per_page: 5)
      p.total_pages_from_items(13)
      expect(p.total_pages).to eq(3)
    end

    it "uses ceiling division" do
      p = described_class.new(per_page: 5)
      p.total_pages_from_items(10)
      expect(p.total_pages).to eq(2)
    end

    it "clamps page if now out of bounds" do
      p = described_class.new(total_pages: 10, per_page: 5)
      p.page = 9
      p.total_pages_from_items(13)
      expect(p.page).to eq(2)
    end

    it "does nothing when per_page is 0" do
      p = described_class.new(total_pages: 5)
      p.total_pages_from_items(13)
      expect(p.total_pages).to eq(5)
    end

    it "ensures minimum of 1 total page" do
      p = described_class.new(per_page: 5)
      p.total_pages_from_items(0)
      expect(p.total_pages).to eq(1)
    end
  end

  describe "#update" do
    it "navigates to next page on right arrow" do
      p = described_class.new(total_pages: 3)
      p.update(key(:right))
      expect(p.page).to eq(1)
    end

    it "navigates to prev page on left arrow" do
      p = described_class.new(total_pages: 3)
      p.page = 2
      p.update(key(:left))
      expect(p.page).to eq(1)
    end

    it "navigates on h/l keys" do
      p = described_class.new(total_pages: 3)
      p.update(key("l"))
      expect(p.page).to eq(1)
      p.update(key("h"))
      expect(p.page).to eq(0)
    end

    it "navigates on page_up/page_down" do
      p = described_class.new(total_pages: 3)
      p.update(key(:page_down))
      expect(p.page).to eq(1)
      p.update(key(:page_up))
      expect(p.page).to eq(0)
    end

    it "returns [self, nil]" do
      p = described_class.new(total_pages: 3)
      result, cmd = p.update(key(:right))
      expect(result).to equal(p)
      expect(cmd).to be_nil
    end

    it "ignores non-KeyMsg" do
      p = described_class.new(total_pages: 3)
      p.update(Chamomile::TickMsg.new(time: Time.now))
      expect(p.page).to eq(0)
    end
  end

  describe "#per_page=" do
    it "sets per_page" do
      p = described_class.new
      p.per_page = 10
      expect(p.per_page).to eq(10)
    end

    it "clamps negative to 0" do
      p = described_class.new
      p.per_page = -5
      expect(p.per_page).to eq(0)
    end
  end

  describe "edge cases" do
    it "page= clamps to 0 with single page" do
      p = described_class.new(total_pages: 1)
      p.page = 5
      expect(p.page).to eq(0)
    end

    it "total_pages= clamps negative to 1" do
      p = described_class.new(total_pages: 5)
      p.total_pages = -3
      expect(p.total_pages).to eq(1)
    end

    it "initializes with negative total_pages clamped to 1" do
      p = described_class.new(total_pages: -5)
      expect(p.total_pages).to eq(1)
    end

    it "update ignores unknown key" do
      p = described_class.new(total_pages: 3)
      p.update(key("z"))
      expect(p.page).to eq(0)
    end

    it "slice_bounds with per_page larger than total_items" do
      p = described_class.new(total_pages: 1, per_page: 100)
      expect(p.slice_bounds(5)).to eq([0, 5])
    end

    it "slice_bounds with single item" do
      p = described_class.new(total_pages: 1, per_page: 5)
      expect(p.slice_bounds(1)).to eq([0, 1])
    end
  end

  describe "#view" do
    it "shows dots for dot type" do
      p = described_class.new(total_pages: 4)
      expect(p.view).to eq("● ○ ○ ○")
    end

    it "shows active dot on current page" do
      p = described_class.new(total_pages: 4)
      p.page = 2
      expect(p.view).to eq("○ ○ ● ○")
    end

    it "shows arabic for arabic type" do
      p = described_class.new(total_pages: 4, type: described_class::TYPE_ARABIC)
      expect(p.view).to eq("1/4")
    end

    it "shows correct arabic after navigation" do
      p = described_class.new(total_pages: 4, type: described_class::TYPE_ARABIC)
      p.page = 2
      expect(p.view).to eq("3/4")
    end

    it "respects custom dots" do
      p = described_class.new(total_pages: 3)
      p.active_dot = "X"
      p.inactive_dot = "."
      expect(p.view).to eq("X . .")
    end

    it "shows single dot for single page" do
      p = described_class.new(total_pages: 1)
      expect(p.view).to eq("●")
    end
  end
end
