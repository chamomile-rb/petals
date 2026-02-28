# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::TextArea do
  def key(k, mod: []) = Chamomile::KeyMsg.new(key: k, mod: mod)
  def paste(text) = Chamomile::PasteMsg.new(content: text)

  subject(:ta) { described_class.new.focus }

  describe "initialization" do
    it "starts with empty value" do
      expect(ta.value).to eq("")
    end

    it "starts at row 0, col 0" do
      expect(ta.row).to eq(0)
      expect(ta.col).to eq(0)
    end

    it "is not focused by default" do
      fresh = described_class.new
      expect(fresh.focused?).to be false
    end

    it "has default attributes" do
      fresh = described_class.new
      expect(fresh.width).to eq(40)
      expect(fresh.height).to eq(6)
      expect(fresh.prompt).to eq("")
      expect(fresh.placeholder).to eq("")
      expect(fresh.char_limit).to eq(0)
      expect(fresh.show_line_numbers).to be false
      expect(fresh.end_of_buffer_char).to eq("~")
    end

    it "accepts keyword arguments" do
      t = described_class.new(width: 80, height: 10, prompt: "> ")
      expect(t.width).to eq(80)
      expect(t.height).to eq(10)
      expect(t.prompt).to eq("> ")
    end
  end

  describe "focus" do
    it "#focus returns self" do
      fresh = described_class.new
      expect(fresh.focus).to equal(fresh)
    end

    it "#blur returns self" do
      expect(ta.blur).to equal(ta)
    end

    it "ignores input when not focused" do
      unfocused = described_class.new
      unfocused.update(key("a"))
      expect(unfocused.value).to eq("")
    end
  end

  describe "character input" do
    it "inserts printable characters" do
      ta.update(key("h"))
      ta.update(key("i"))
      expect(ta.value).to eq("hi")
      expect(ta.col).to eq(2)
    end

    it "inserts at cursor position" do
      ta.update(key("a"))
      ta.update(key("c"))
      ta.update(key(:left))
      ta.update(key("b"))
      expect(ta.value).to eq("abc")
    end

    it "allows shifted characters" do
      ta.update(key("A", mod: [:shift]))
      expect(ta.value).to eq("A")
    end

    it "does not insert for ctrl combos" do
      ta.update(key("a", mod: [:ctrl]))
      expect(ta.value).to eq("")
    end

    it "does not insert special keys" do
      ta.update(key(:tab))
      ta.update(key(:escape))
      expect(ta.value).to eq("")
    end
  end

  describe "multi-line: Enter and Backspace" do
    it "Enter splits the line" do
      ta.update(key("a"))
      ta.update(key("b"))
      ta.update(key(:enter))
      ta.update(key("c"))
      expect(ta.value).to eq("ab\nc")
      expect(ta.row).to eq(1)
      expect(ta.col).to eq(1)
    end

    it "Enter in middle splits at cursor" do
      ta.value = "hello"
      ta.instance_variable_set(:@col, 2)
      ta.update(key(:enter))
      expect(ta.value).to eq("he\nllo")
      expect(ta.row).to eq(1)
      expect(ta.col).to eq(0)
    end

    it "Backspace at col 0 merges with previous line" do
      ta.value = "ab\ncd"
      ta.instance_variable_set(:@row, 1)
      ta.instance_variable_set(:@col, 0)
      ta.update(key(:backspace))
      expect(ta.value).to eq("abcd")
      expect(ta.row).to eq(0)
      expect(ta.col).to eq(2)
    end

    it "Backspace at row 0 col 0 does nothing" do
      ta.value = "hello"
      ta.instance_variable_set(:@row, 0)
      ta.instance_variable_set(:@col, 0)
      ta.update(key(:backspace))
      expect(ta.value).to eq("hello")
    end

    it "Delete at end of line merges with next line" do
      ta.value = "ab\ncd"
      ta.instance_variable_set(:@row, 0)
      ta.instance_variable_set(:@col, 2)
      ta.update(key(:delete))
      expect(ta.value).to eq("abcd")
      expect(ta.row).to eq(0)
    end

    it "line_count reflects number of lines" do
      ta.value = "a\nb\nc"
      expect(ta.line_count).to eq(3)
    end
  end

  describe "cursor movement" do
    before do
      ta.value = "hello\nworld\nfoo"
      ta.instance_variable_set(:@row, 1)
      ta.instance_variable_set(:@col, 3)
      ta.instance_variable_set(:@last_char_offset, 3)
    end

    it "moves up" do
      ta.update(key(:up))
      expect(ta.row).to eq(0)
      expect(ta.col).to eq(3)
    end

    it "moves down" do
      ta.update(key(:down))
      expect(ta.row).to eq(2)
      expect(ta.col).to eq(3)
    end

    it "clamps col when moving to shorter line" do
      ta.instance_variable_set(:@col, 5)
      ta.instance_variable_set(:@last_char_offset, 5)
      ta.update(key(:down))
      expect(ta.row).to eq(2)
      expect(ta.col).to eq(3) # "foo" has length 3
    end

    it "does not move up past row 0" do
      ta.instance_variable_set(:@row, 0)
      ta.update(key(:up))
      expect(ta.row).to eq(0)
    end

    it "does not move down past last row" do
      ta.instance_variable_set(:@row, 2)
      ta.update(key(:down))
      expect(ta.row).to eq(2)
    end

    it "moves right" do
      ta.update(key(:right))
      expect(ta.col).to eq(4)
    end

    it "moves left" do
      ta.update(key(:left))
      expect(ta.col).to eq(2)
    end

    it "wraps right to next line" do
      ta.instance_variable_set(:@col, 5) # end of "world"
      ta.update(key(:right))
      expect(ta.row).to eq(2)
      expect(ta.col).to eq(0)
    end

    it "wraps left to previous line" do
      ta.instance_variable_set(:@col, 0)
      ta.update(key(:left))
      expect(ta.row).to eq(0)
      expect(ta.col).to eq(5)
    end

    it "moves to line start with home" do
      ta.update(key(:home))
      expect(ta.col).to eq(0)
    end

    it "moves to line end with end" do
      ta.update(key(:end_key))
      expect(ta.col).to eq(5) # "world"
    end

    it "moves to line start with ctrl+a" do
      ta.update(key("a", mod: [:ctrl]))
      expect(ta.col).to eq(0)
    end

    it "moves to line end with ctrl+e" do
      ta.update(key("e", mod: [:ctrl]))
      expect(ta.col).to eq(5)
    end
  end

  describe "word movement" do
    before do
      ta.value = "hello world foo"
      ta.instance_variable_set(:@col, 6) # at 'w'
    end

    it "moves to next word with alt+right" do
      ta.update(key(:right, mod: [:alt]))
      expect(ta.col).to eq(12) # past "world "
    end

    it "moves to previous word with alt+left" do
      ta.update(key(:left, mod: [:alt]))
      expect(ta.col).to eq(0)
    end
  end

  describe "deletion" do
    it "deletes char backward" do
      ta.value = "hello"
      ta.instance_variable_set(:@col, 5)
      ta.update(key(:backspace))
      expect(ta.value).to eq("hell")
      expect(ta.col).to eq(4)
    end

    it "deletes char forward" do
      ta.value = "hello"
      ta.instance_variable_set(:@col, 0)
      ta.update(key(:delete))
      expect(ta.value).to eq("ello")
    end

    it "deletes word backward" do
      ta.value = "hello world"
      ta.instance_variable_set(:@col, 11)
      ta.update(key(:backspace, mod: [:alt]))
      expect(ta.value).to eq("hello ")
      expect(ta.col).to eq(6)
    end

    it "deletes word forward" do
      ta.value = "hello world"
      ta.instance_variable_set(:@col, 0)
      ta.update(key(:delete, mod: [:alt]))
      expect(ta.value).to eq("world")
    end

    it "deletes before cursor" do
      ta.value = "hello world"
      ta.instance_variable_set(:@col, 6)
      ta.update(key("u", mod: [:ctrl]))
      expect(ta.value).to eq("world")
      expect(ta.col).to eq(0)
    end

    it "deletes after cursor" do
      ta.value = "hello world"
      ta.instance_variable_set(:@col, 5)
      ta.update(key("k", mod: [:ctrl]))
      expect(ta.value).to eq("hello")
    end
  end

  describe "vertical scrolling" do
    it "scrolls down when cursor moves below viewport" do
      ta.instance_variable_set(:@height, 3)
      ta.value = (0..9).map { |i| "line #{i}" }.join("\n")
      ta.instance_variable_set(:@row, 0)
      ta.instance_variable_set(:@col, 0)
      ta.instance_variable_set(:@offset, 0)
      5.times { ta.update(key(:down)) }
      expect(ta.row).to eq(5)
      # View contains the cursor row — strip ANSI to verify content
      view = ta.view.gsub(/\e\[[0-9;]*m/, "")
      expect(view).to include("line 5")
    end

    it "scrolls up when cursor moves above viewport" do
      ta.instance_variable_set(:@height, 3)
      ta.value = (0..9).map { |i| "line #{i}" }.join("\n")
      ta.instance_variable_set(:@row, 5)
      ta.instance_variable_set(:@col, 0)
      ta.instance_variable_set(:@offset, 3)
      3.times { ta.update(key(:up)) }
      expect(ta.row).to eq(2)
      view = ta.view.gsub(/\e\[[0-9;]*m/, "")
      expect(view).to include("line 2")
    end
  end

  describe "line numbers" do
    it "shows line numbers when enabled" do
      ta.show_line_numbers = true
      ta.value = "first\nsecond\nthird"
      view = ta.view
      expect(view).to include("1 ")
      expect(view).to include("2 ")
      expect(view).to include("3 ")
    end

    it "hides line numbers when disabled" do
      ta.show_line_numbers = false
      ta.value = "hello"
      view = ta.view
      expect(view).not_to match(/^\d+ /)
    end
  end

  describe "paste" do
    it "inserts single-line paste" do
      ta.update(paste("hello"))
      expect(ta.value).to eq("hello")
    end

    it "inserts multi-line paste" do
      ta.update(paste("hello\nworld"))
      expect(ta.value).to eq("hello\nworld")
      expect(ta.row).to eq(1)
    end

    it "respects char_limit" do
      ta.char_limit = 5
      ta.update(paste("hello world"))
      expect(ta.length).to be <= 5
    end

    it "filters non-printable characters" do
      ta.update(paste("hello\x00world"))
      expect(ta.value).to eq("helloworld")
    end
  end

  describe "char_limit" do
    it "prevents input beyond limit" do
      ta.char_limit = 3
      ta.update(key("a"))
      ta.update(key("b"))
      ta.update(key("c"))
      ta.update(key("d"))
      expect(ta.value).to eq("abc")
    end

    it "truncates value= assignment" do
      ta.char_limit = 3
      ta.value = "hello"
      expect(ta.value).to eq("hel")
    end

    it "0 means unlimited" do
      ta.char_limit = 0
      20.times { ta.update(key("x")) }
      expect(ta.value.length).to eq(20)
    end

    it "counts newlines toward limit" do
      ta.char_limit = 5
      ta.update(key("a"))
      ta.update(key("b"))
      ta.update(key(:enter))
      ta.update(key("c"))
      ta.update(key("d"))
      # "ab\ncd" = 5 chars including \n
      ta.update(key("e"))
      expect(ta.length).to be <= 5
    end
  end

  describe "placeholder" do
    it "shows placeholder when empty and unfocused" do
      t = described_class.new(placeholder: "type here")
      expect(t.view).to include("type here")
    end

    it "does not show placeholder when focused" do
      t = described_class.new(placeholder: "type here").focus
      expect(t.view).not_to include("type here")
    end

    it "does not show placeholder when value is present" do
      t = described_class.new(placeholder: "type here")
      t.value = "hello"
      expect(t.view).not_to include("type here")
    end
  end

  describe "#view" do
    it "shows reverse-video cursor when focused" do
      ta.value = "hi"
      ta.instance_variable_set(:@col, 1)
      expect(ta.view).to include("\e[7m")
    end

    it "shows cursor at end of line" do
      ta.value = "hi"
      ta.instance_variable_set(:@col, 2)
      expect(ta.view).to include("hi\e[7m \e[0m")
    end

    it "shows end-of-buffer char for empty lines beyond content" do
      ta.value = "line1"
      view = ta.view
      expect(view).to include("~")
    end

    it "shows prompt" do
      ta.prompt = "> "
      ta.value = "hello"
      view = ta.view
      expect(view).to include("> ")
    end

    it "does not show cursor when not focused" do
      t = described_class.new
      t.value = "hello"
      expect(t.view).not_to include("\e[7m")
    end
  end

  describe "#value= and cursor clamping" do
    it "clamps row when value shrinks" do
      ta.value = "a\nb\nc"
      ta.instance_variable_set(:@row, 2)
      ta.value = "only"
      expect(ta.row).to eq(0)
    end

    it "clamps col when line shrinks" do
      ta.value = "hello"
      ta.instance_variable_set(:@col, 5)
      ta.value = "hi"
      expect(ta.col).to eq(2)
    end

    it "handles nil" do
      ta.value = nil
      expect(ta.value).to eq("")
    end

    it "handles integer" do
      ta.value = 42
      expect(ta.value).to eq("42")
    end
  end

  describe "#reset" do
    it "clears all content" do
      ta.value = "hello\nworld"
      ta.reset
      expect(ta.value).to eq("")
      expect(ta.row).to eq(0)
      expect(ta.col).to eq(0)
    end
  end

  describe "#move_to_begin / #move_to_end" do
    before do
      ta.value = "hello\nworld\nfoo"
      ta.instance_variable_set(:@row, 1)
      ta.instance_variable_set(:@col, 3)
    end

    it "moves to beginning of input" do
      ta.move_to_begin
      expect(ta.row).to eq(0)
      expect(ta.col).to eq(0)
    end

    it "moves to end of input" do
      ta.move_to_end
      expect(ta.row).to eq(2)
      expect(ta.col).to eq(3) # "foo".length
    end

    it "responds to ctrl+home" do
      ta.update(key(:home, mod: [:ctrl]))
      expect(ta.row).to eq(0)
      expect(ta.col).to eq(0)
    end

    it "responds to ctrl+end" do
      ta.update(key(:end_key, mod: [:ctrl]))
      expect(ta.row).to eq(2)
      expect(ta.col).to eq(3)
    end
  end

  describe "#page_up / #page_down" do
    before do
      ta.instance_variable_set(:@height, 3)
      ta.value = (0..19).map { |i| "line #{i}" }.join("\n")
      ta.instance_variable_set(:@row, 10)
      ta.instance_variable_set(:@col, 0)
      ta.instance_variable_set(:@offset, 8)
    end

    it "page_up moves cursor up by display_height rows" do
      ta.update(key(:page_up))
      expect(ta.row).to eq(7) # 10 - 3
    end

    it "page_down moves cursor down by display_height rows" do
      ta.instance_variable_set(:@row, 5)
      ta.update(key(:page_down))
      expect(ta.row).to eq(8) # 5 + 3
    end

    it "page_up clamps at top" do
      ta.instance_variable_set(:@row, 1)
      ta.page_up
      expect(ta.row).to eq(0)
    end

    it "page_down clamps at bottom" do
      ta.instance_variable_set(:@row, 19)
      ta.page_down
      expect(ta.row).to eq(19)
    end
  end

  describe "column persistence (last_char_offset)" do
    before do
      ta.value = "hello\nhi\nworld"
      ta.instance_variable_set(:@row, 0)
      ta.instance_variable_set(:@col, 5) # end of "hello"
      ta.instance_variable_set(:@last_char_offset, 5)
    end

    it "preserves column after moving through short line" do
      ta.cursor_down # to "hi", col clamps to 2
      expect(ta.col).to eq(2)
      ta.cursor_down # to "world", col restores to 5
      expect(ta.col).to eq(5)
    end

    it "updates last_char_offset on horizontal movement" do
      ta.update(key(:left))
      expect(ta.instance_variable_get(:@last_char_offset)).to eq(4)
    end

    it "updates last_char_offset on character insert" do
      ta.update(key("x"))
      expect(ta.instance_variable_get(:@last_char_offset)).to eq(6)
    end
  end

  describe "#display_height" do
    it "returns height when max_height is 0" do
      ta.height = 6
      ta.max_height = 0
      expect(ta.display_height).to eq(6)
    end

    it "grows to content length up to max_height" do
      ta.height = 3
      ta.max_height = 10
      ta.value = (0..6).map { |i| "line#{i}" }.join("\n") # 7 lines
      expect(ta.display_height).to eq(7) # max(7, 3) = 7, min(7, 10) = 7
    end

    it "caps at max_height" do
      ta.height = 3
      ta.max_height = 5
      ta.value = (0..9).map { |i| "line#{i}" }.join("\n") # 10 lines
      expect(ta.display_height).to eq(5) # max(10, 3) = 10, min(10, 5) = 5
    end

    it "uses display_height in view" do
      ta.height = 3
      ta.max_height = 5
      ta.value = "a\nb\nc\nd"
      lines = ta.view.split("\n")
      expect(lines.length).to eq(4) # 4 lines of content, display_height = max(4,3) = 4, min(4,5) = 4
    end
  end

  describe "#word" do
    it "extracts word under cursor" do
      ta.value = "hello world foo"
      ta.instance_variable_set(:@col, 7) # in "world"
      expect(ta.word).to eq("world")
    end

    it "returns empty for whitespace position" do
      ta.value = "hello world"
      ta.instance_variable_set(:@col, 5) # at space
      expect(ta.word).to eq("")
    end

    it "returns empty for empty line" do
      ta.value = ""
      expect(ta.word).to eq("")
    end

    it "returns word at start of line" do
      ta.value = "hello world"
      ta.instance_variable_set(:@col, 0)
      expect(ta.word).to eq("hello")
    end

    it "returns empty when col is beyond line" do
      ta.value = "hi"
      ta.instance_variable_set(:@col, 2)
      expect(ta.word).to eq("")
    end
  end

  describe "#update return value" do
    it "returns nil" do
      expect(ta.update(key("a"))).to be_nil
    end

    it "ignores unrelated message types" do
      ta.update(Chamomile::WindowSizeMsg.new(width: 80, height: 24))
      expect(ta.value).to eq("")
    end
  end

  describe "edge cases" do
    it "handles deletion on empty value" do
      expect { ta.update(key(:backspace)) }.not_to raise_error
      expect { ta.update(key(:delete)) }.not_to raise_error
    end

    it "handles word deletion at boundaries" do
      ta.value = "hello"
      ta.instance_variable_set(:@col, 0)
      expect { ta.update(key(:backspace, mod: [:alt])) }.not_to raise_error
      ta.instance_variable_set(:@col, 5)
      expect { ta.update(key(:delete, mod: [:alt])) }.not_to raise_error
    end

    it "handles cursor_up and cursor_down methods" do
      ta.value = "a\nb\nc"
      ta.cursor_down
      expect(ta.row).to eq(1)
      ta.cursor_up
      expect(ta.row).to eq(0)
    end

    it "handles cursor_start and cursor_end methods" do
      ta.value = "hello"
      ta.instance_variable_set(:@col, 3)
      ta.cursor_start
      expect(ta.col).to eq(0)
      ta.cursor_end
      expect(ta.col).to eq(5)
    end

    it "handles insert_string" do
      ta.insert_string("abc")
      expect(ta.value).to eq("abc")
      expect(ta.col).to eq(3)
    end

    it "handles insert_string with newlines" do
      ta.insert_string("hello\nworld")
      expect(ta.value).to eq("hello\nworld")
      expect(ta.row).to eq(1)
      expect(ta.col).to eq(5)
    end
  end
end
