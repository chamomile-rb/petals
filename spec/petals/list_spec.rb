# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::List do
  def key(k, mod: []) = Chamomile::KeyMsg.new(key: k, mod: mod)

  # Simple item struct for testing
  unless defined?(TestItem)
    TestItem = Data.define(:title, :description) do
      def filter_value = title
    end
  end

  let(:items) do
    [
      TestItem.new(title: "Alice", description: "First person"),
      TestItem.new(title: "Bob", description: "Second person"),
      TestItem.new(title: "Charlie", description: "Third person"),
      TestItem.new(title: "Diana", description: "Fourth person"),
      TestItem.new(title: "Eve", description: "Fifth person"),
    ]
  end

  subject(:list) { described_class.new(items: items, width: 40, height: 20) }

  describe "initialization" do
    it "starts at cursor 0" do
      expect(list.cursor).to eq(0)
    end

    it "stores items" do
      expect(list.items.length).to eq(5)
    end

    it "defaults to unfiltered state" do
      expect(list.filter_state).to eq(described_class::FILTER_UNFILTERED)
    end

    it "accepts custom options" do
      l = described_class.new(items: items, width: 60, height: 30)
      expect(l.width).to eq(60)
      expect(l.height).to eq(30)
    end

    it "defaults show flags to true" do
      expect(list.show_title).to be true
      expect(list.show_filter).to be true
      expect(list.show_status_bar).to be true
      expect(list.show_pagination).to be true
      expect(list.show_help).to be true
    end

    it "defaults filtering_enabled to true" do
      expect(list.filtering_enabled).to be true
    end
  end

  describe "#selected_item" do
    it "returns the item at cursor" do
      expect(list.selected_item).to eq(items[0])
    end

    it "returns nil for empty list" do
      l = described_class.new(items: [], width: 40, height: 20)
      expect(l.selected_item).to be_nil
    end

    it "tracks cursor movement" do
      list.cursor_down
      expect(list.selected_item).to eq(items[1])
    end
  end

  describe "#cursor_up / #cursor_down" do
    it "moves cursor down" do
      list.cursor_down
      expect(list.cursor).to eq(1)
    end

    it "moves cursor up" do
      list.cursor_down
      list.cursor_down
      list.cursor_up
      expect(list.cursor).to eq(1)
    end

    it "clamps at top" do
      list.cursor_up
      expect(list.cursor).to eq(0)
    end

    it "clamps at bottom" do
      10.times { list.cursor_down }
      expect(list.cursor).to eq(4)
    end
  end

  describe "#goto_start / #goto_end" do
    it "goes to first item" do
      list.cursor_down
      list.cursor_down
      list.goto_start
      expect(list.cursor).to eq(0)
    end

    it "goes to last item" do
      list.goto_end
      expect(list.cursor).to eq(4)
    end
  end

  describe "#items=" do
    it "replaces items" do
      new_items = [TestItem.new(title: "New", description: "item")]
      list.items = new_items
      expect(list.items.length).to eq(1)
    end

    it "clamps cursor" do
      list.goto_end
      list.items = [items[0]]
      expect(list.cursor).to eq(0)
    end
  end

  describe "#set_item" do
    it "replaces item at index" do
      replacement = TestItem.new(title: "Replaced", description: "new")
      list.set_item(0, replacement)
      expect(list.items[0].title).to eq("Replaced")
    end

    it "ignores invalid index" do
      list.set_item(99, items[0])
      expect(list.items.length).to eq(5)
    end
  end

  describe "#insert_item" do
    it "inserts at index" do
      new_item = TestItem.new(title: "New", description: "inserted")
      list.insert_item(2, new_item)
      expect(list.items.length).to eq(6)
      expect(list.items[2].title).to eq("New")
    end
  end

  describe "#remove_item" do
    it "removes and returns item at index" do
      removed = list.remove_item(0)
      expect(removed.title).to eq("Alice")
      expect(list.items.length).to eq(4)
    end

    it "returns nil for invalid index" do
      expect(list.remove_item(99)).to be_nil
    end
  end

  describe "#update with KeyMsg" do
    it "moves down on j" do
      list.update(key("j"))
      expect(list.cursor).to eq(1)
    end

    it "moves up on k" do
      list.cursor_down
      list.update(key("k"))
      expect(list.cursor).to eq(0)
    end

    it "moves down on down arrow" do
      list.update(key(:down))
      expect(list.cursor).to eq(1)
    end

    it "moves up on up arrow" do
      list.cursor_down
      list.update(key(:up))
      expect(list.cursor).to eq(0)
    end

    it "goes to start on g" do
      list.cursor_down
      list.cursor_down
      list.update(key("g"))
      expect(list.cursor).to eq(0)
    end

    it "goes to end on G" do
      list.update(key("G", mod: [:shift]))
      expect(list.cursor).to eq(4)
    end

    it "returns nil" do
      expect(list.update(key(:down))).to be_nil
    end
  end

  describe "filter flow" do
    it "enters filter mode on /" do
      list.update(key("/"))
      expect(list.filter_state).to eq(described_class::FILTER_FILTERING)
    end

    it "accepts typing in filter mode" do
      list.update(key("/"))
      list.update(key("a"))
      expect(list.filter_value).to eq("a")
    end

    it "filters items by typed query" do
      list.update(key("/"))
      list.update(key("a"))
      list.update(key("l"))
      # "al" should fuzzy match "Alice"
      expect(list.items.length).to be >= 1
      expect(list.items.any? { |i| i.title == "Alice" }).to be true
    end

    it "accepts filter on enter" do
      list.update(key("/"))
      list.update(key("a"))
      list.update(key(:enter))
      expect(list.filter_state).to eq(described_class::FILTER_APPLIED)
    end

    it "clears filter on escape in filtering mode" do
      list.update(key("/"))
      list.update(key("a"))
      list.update(key(:escape))
      expect(list.filter_state).to eq(described_class::FILTER_UNFILTERED)
      expect(list.items.length).to eq(5)
    end

    it "clears applied filter on escape" do
      list.update(key("/"))
      list.update(key("a"))
      list.update(key(:enter))
      expect(list.filter_state).to eq(described_class::FILTER_APPLIED)
      list.update(key(:escape))
      expect(list.filter_state).to eq(described_class::FILTER_UNFILTERED)
    end

    it "does not enter filter mode when filtering disabled" do
      list.filtering_enabled = false
      list.update(key("/"))
      expect(list.filter_state).to eq(described_class::FILTER_UNFILTERED)
    end

    it "resets filter on empty accept" do
      list.update(key("/"))
      list.update(key(:enter))
      expect(list.filter_state).to eq(described_class::FILTER_UNFILTERED)
    end
  end

  describe "fuzzy matching" do
    it "matches substring characters" do
      list.update(key("/"))
      list.update(key("c"))
      list.update(key("h"))
      # "ch" fuzzy matches "Charlie"
      expect(list.items.any? { |i| i.title == "Charlie" }).to be true
    end

    it "matches case-insensitively" do
      list.update(key("/"))
      list.update(key("b"))
      expect(list.items.any? { |i| i.title == "Bob" }).to be true
    end

    it "returns no matches for non-matching query" do
      list.update(key("/"))
      list.update(key("z"))
      list.update(key("z"))
      list.update(key("z"))
      expect(list.items).to be_empty
    end
  end

  describe "string items" do
    it "works with plain string items" do
      l = described_class.new(items: %w[apple banana cherry], width: 40, height: 20)
      expect(l.items.length).to eq(3)
      expect(l.selected_item).to eq("apple")
    end

    it "filters string items" do
      l = described_class.new(items: %w[apple banana cherry], width: 40, height: 20)
      l.update(key("/"))
      l.update(key("a"))
      l.update(key("n"))
      expect(l.items).to include("banana")
    end

    it "renders string items" do
      l = described_class.new(items: %w[apple banana cherry], width: 40, height: 20)
      view = l.view
      expect(view).to include("apple")
      expect(view).to include("banana")
    end
  end

  describe "delegate rendering" do
    it "uses delegate.render when provided" do
      delegate = double("delegate")
      allow(delegate).to receive(:render) { |_list, _idx, item| "[#{item.title}]" }
      l = described_class.new(items: items, width: 40, height: 20, delegate: delegate)
      view = l.view
      expect(view).to include("[Alice]")
    end

    it "uses default rendering when no delegate" do
      view = list.view
      expect(view).to include("Alice - First person")
    end
  end

  describe "#view" do
    it "renders items" do
      view = list.view
      expect(view).to include("Alice")
    end

    it "renders status bar" do
      view = list.view
      expect(view).to include("5 items")
    end

    it "renders title when set" do
      list.title = "People"
      view = list.view
      expect(view).to include("People")
    end

    it "renders filtered status" do
      list.update(key("/"))
      list.update(key("a"))
      list.update(key(:enter))
      view = list.view
      expect(view).to include("filtered")
    end

    it "highlights selected item" do
      view = list.view
      expect(view).to include("\e[7m")
    end

    it "indents selected item consistently with unselected items" do
      view = list.view
      # Selected item should have same "  " indent inside reverse video
      expect(view).to include("\e[7m  ")
    end

    it "shows (no items) for empty filtered list" do
      list.update(key("/"))
      list.update(key("z"))
      list.update(key("z"))
      list.update(key("z"))
      view = list.view
      expect(view).to include("(no items)")
    end

    it "renders help" do
      view = list.view
      expect(view).to include("filter")
    end

    it "renders filter input in filtering mode" do
      list.update(key("/"))
      view = list.view
      expect(view).to include("/ ")
    end
  end

  describe "#reset_filter" do
    it "resets filter and restores all items" do
      list.update(key("/"))
      list.update(key("a"))
      list.update(key(:enter))
      list.reset_filter
      expect(list.filter_state).to eq(described_class::FILTER_UNFILTERED)
      expect(list.items.length).to eq(5)
      expect(list.cursor).to eq(0)
    end
  end

  describe "help toggle" do
    it "toggles full help on ?" do
      list.update(key("?"))
      # help.show_all toggled
      help = list.instance_variable_get(:@help)
      expect(help.show_all).to be true
    end

    it "renders full help when toggled" do
      list.update(key("?"))
      full_view = list.view
      # Full help renders differently from short help (multi-line)
      expect(full_view).to include("filter")
      expect(full_view).to include("quit")
    end
  end

  describe "infinite scroll" do
    it "wraps cursor down to top" do
      list.infinite_scroll = true
      list.goto_end
      list.cursor_down
      expect(list.cursor).to eq(0)
    end

    it "wraps cursor up to bottom" do
      list.infinite_scroll = true
      list.cursor_up
      expect(list.cursor).to eq(4)
    end

    it "does not wrap when disabled" do
      list.infinite_scroll = false
      list.goto_end
      list.cursor_down
      expect(list.cursor).to eq(4)
    end
  end

  describe "status messages" do
    it "sets status message" do
      allow_any_instance_of(Object).to receive(:sleep)
      list.new_status_message("Loading...")
      expect(list.status_message).to eq("Loading...")
    end

    it "returns a cmd that produces ListStatusTimeoutMsg" do
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = list.new_status_message("Loading...", lifetime: 0.01)
      msg = cmd.call
      expect(msg).to be_a(Petals::ListStatusTimeoutMsg)
      expect(msg.id).to eq(list.id)
    end

    it "clears status on timeout" do
      allow_any_instance_of(Object).to receive(:sleep)
      cmd = list.new_status_message("Loading...")
      msg = cmd.call
      list.update(msg)
      expect(list.status_message).to be_nil
    end

    it "shows status message in status bar" do
      allow_any_instance_of(Object).to receive(:sleep)
      list.new_status_message("Processing...")
      expect(list.view).to include("Processing...")
    end

    it "ignores timeout from wrong id" do
      allow_any_instance_of(Object).to receive(:sleep)
      list.new_status_message("Loading...")
      msg = Petals::ListStatusTimeoutMsg.new(id: "wrong")
      list.update(msg)
      expect(list.status_message).to eq("Loading...")
    end
  end

  describe "#visible_items" do
    it "returns items for the current page" do
      visible = list.visible_items
      expect(visible).to include(items[0])
      expect(visible.length).to be <= list.items.length
    end

    it "returns empty for empty list" do
      l = described_class.new(items: [], width: 40, height: 20)
      expect(l.visible_items).to eq([])
    end
  end

  describe "spinner control" do
    it "starts spinner" do
      cmd = list.start_spinner
      expect(list.spinner_visible?).to be true
      expect(cmd).to respond_to(:call)
    end

    it "stops spinner" do
      list.start_spinner
      list.stop_spinner
      expect(list.spinner_visible?).to be false
    end

    it "shows spinner in status bar when visible" do
      list.start_spinner
      spinner = list.instance_variable_get(:@spinner)
      # Advance spinner to have visible content
      expect(list.view).to include(spinner.view)
    end
  end

  describe "#set_filter_text" do
    it "programmatically sets filter" do
      list.set_filter_text("ali")
      expect(list.filter_state).to eq(described_class::FILTER_APPLIED)
      expect(list.items.any? { |i| i.title == "Alice" }).to be true
    end

    it "resets when given empty string" do
      list.set_filter_text("ali")
      list.set_filter_text("")
      expect(list.filter_state).to eq(described_class::FILTER_UNFILTERED)
      expect(list.items.length).to eq(5)
    end

    it "resets when given nil" do
      list.set_filter_text("ali")
      list.set_filter_text(nil)
      expect(list.filter_state).to eq(described_class::FILTER_UNFILTERED)
    end
  end

  describe "#global_index" do
    it "returns index in all_items" do
      list.cursor_down
      expect(list.global_index).to eq(1)
    end

    it "returns correct index when filtered" do
      list.set_filter_text("charlie")
      expect(list.global_index).to eq(2) # Charlie is at index 2 in all_items
    end

    it "returns nil for empty list" do
      l = described_class.new(items: [], width: 40, height: 20)
      expect(l.global_index).to be_nil
    end
  end

  describe "edge cases" do
    it "handles empty items" do
      l = described_class.new(items: [], width: 40, height: 20)
      expect(l.selected_item).to be_nil
      expect(l.view).to include("(no items)")
    end

    it "handles single item" do
      l = described_class.new(items: [items[0]], width: 40, height: 20)
      expect(l.selected_item).to eq(items[0])
      l.cursor_down
      expect(l.cursor).to eq(0)
    end

    it "handles SpinnerTickMsg" do
      spinner = list.instance_variable_get(:@spinner)
      msg = Petals::SpinnerTickMsg.new(id: spinner.id, tag: 0, time: Time.now)
      expect { list.update(msg) }.not_to raise_error
    end

    it "handles FilterMatchesMsg" do
      matches = [items[0], items[2]]
      msg = Petals::FilterMatchesMsg.new(matches: matches)
      list.update(msg)
      expect(list.items.length).to eq(2)
    end

    it "ignores unrelated message types" do
      list.update(Chamomile::WindowSizeMsg.new(width: 80, height: 24))
      expect(list.cursor).to eq(0)
    end
  end
end
