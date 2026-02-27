# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chamomile::Leaves::TextInput do
  def key(k, mod: [])
    Chamomile::KeyMsg.new(key: k, mod: mod)
  end

  def paste(text)
    Chamomile::PasteMsg.new(content: text)
  end

  subject(:input) { described_class.new.focus }

  describe "initialization" do
    it "starts with empty value" do
      expect(input.value).to eq("")
    end

    it "starts at position 0" do
      expect(input.position).to eq(0)
    end

    it "is not focused by default" do
      fresh = described_class.new
      expect(fresh.focused?).to be false
    end

    it "has default attributes" do
      fresh = described_class.new
      expect(fresh.prompt).to eq("")
      expect(fresh.placeholder).to eq("")
      expect(fresh.char_limit).to eq(0)
      expect(fresh.width).to eq(0)
      expect(fresh.echo_mode).to eq(:normal)
      expect(fresh.echo_char).to eq("*")
      expect(fresh.err).to be_nil
    end

    it "accepts keyword arguments" do
      ti = described_class.new(prompt: "> ", placeholder: "type here", char_limit: 10)
      expect(ti.prompt).to eq("> ")
      expect(ti.placeholder).to eq("type here")
      expect(ti.char_limit).to eq(10)
    end
  end

  describe "focus" do
    it "#focus returns self" do
      fresh = described_class.new
      expect(fresh.focus).to equal(fresh)
    end

    it "#blur returns self" do
      expect(input.blur).to equal(input)
    end

    it "ignores key input when not focused" do
      unfocused = described_class.new
      unfocused.update(key("a"))
      expect(unfocused.value).to eq("")
    end

    it "processes key input when focused" do
      input.update(key("a"))
      expect(input.value).to eq("a")
    end
  end

  describe "character input" do
    it "inserts printable characters" do
      input.update(key("h"))
      input.update(key("i"))
      expect(input.value).to eq("hi")
      expect(input.position).to eq(2)
    end

    it "inserts at cursor position" do
      input.update(key("a"))
      input.update(key("c"))
      input.update(key(:left))
      input.update(key("b"))
      expect(input.value).to eq("abc")
    end

    it "allows shifted characters" do
      input.update(key("A", mod: [:shift]))
      expect(input.value).to eq("A")
    end

    it "does not insert for ctrl combos" do
      input.update(key("a", mod: [:ctrl]))
      expect(input.value).to eq("")
    end

    it "does not insert special keys" do
      input.update(key(:enter))
      input.update(key(:tab))
      input.update(key(:escape))
      expect(input.value).to eq("")
    end
  end

  describe "cursor movement" do
    before do
      input.value = "hello"
      input.position = 2
    end

    it "moves right with right arrow" do
      input.update(key(:right))
      expect(input.position).to eq(3)
    end

    it "moves left with left arrow" do
      input.update(key(:left))
      expect(input.position).to eq(1)
    end

    it "moves to start with home" do
      input.update(key(:home))
      expect(input.position).to eq(0)
    end

    it "moves to end with end" do
      input.update(key(:end_key))
      expect(input.position).to eq(5)
    end

    it "moves to start with ctrl+a" do
      input.update(key("a", mod: [:ctrl]))
      expect(input.position).to eq(0)
    end

    it "moves to end with ctrl+e" do
      input.update(key("e", mod: [:ctrl]))
      expect(input.position).to eq(5)
    end

    it "does not move left past 0" do
      input.position = 0
      input.update(key(:left))
      expect(input.position).to eq(0)
    end

    it "does not move right past end" do
      input.position = 5
      input.update(key(:right))
      expect(input.position).to eq(5)
    end
  end

  describe "word movement" do
    before do
      input.value = "hello world foo"
      input.position = 6 # at 'w'
    end

    it "moves to next word with alt+right" do
      input.update(key(:right, mod: [:alt]))
      expect(input.position).to eq(12) # past "world "
    end

    it "moves to previous word with alt+left" do
      input.update(key(:left, mod: [:alt]))
      expect(input.position).to eq(0) # back past "hello "
    end

    it "moves to end from last word" do
      input.position = 12
      input.update(key(:right, mod: [:alt]))
      expect(input.position).to eq(15)
    end

    it "moves to 0 from first word" do
      input.position = 3
      input.update(key(:left, mod: [:alt]))
      expect(input.position).to eq(0)
    end
  end

  describe "deletion" do
    it "deletes char backward with backspace" do
      input.value = "hello"
      input.position = 5
      input.update(key(:backspace))
      expect(input.value).to eq("hell")
      expect(input.position).to eq(4)
    end

    it "deletes char forward with delete" do
      input.value = "hello"
      input.position = 0
      input.update(key(:delete))
      expect(input.value).to eq("ello")
      expect(input.position).to eq(0)
    end

    it "does nothing on backspace at position 0" do
      input.value = "hello"
      input.position = 0
      input.update(key(:backspace))
      expect(input.value).to eq("hello")
    end

    it "does nothing on delete at end" do
      input.value = "hello"
      input.position = 5
      input.update(key(:delete))
      expect(input.value).to eq("hello")
    end

    it "deletes word backward with alt+backspace" do
      input.value = "hello world"
      input.position = 11
      input.update(key(:backspace, mod: [:alt]))
      expect(input.value).to eq("hello ")
      expect(input.position).to eq(6)
    end

    it "deletes word forward with alt+delete" do
      input.value = "hello world"
      input.position = 0
      input.update(key(:delete, mod: [:alt]))
      expect(input.value).to eq("world")
      expect(input.position).to eq(0)
    end

    it "deletes before cursor with ctrl+u" do
      input.value = "hello world"
      input.position = 6
      input.update(key("u", mod: [:ctrl]))
      expect(input.value).to eq("world")
      expect(input.position).to eq(0)
    end

    it "deletes after cursor with ctrl+k" do
      input.value = "hello world"
      input.position = 5
      input.update(key("k", mod: [:ctrl]))
      expect(input.value).to eq("hello")
      expect(input.position).to eq(5)
    end
  end

  describe "paste" do
    it "inserts pasted text at cursor" do
      input.value = "ac"
      input.position = 1
      input.update(paste("b"))
      expect(input.value).to eq("abc")
      expect(input.position).to eq(2)
    end

    it "filters non-printable characters from paste" do
      input.update(paste("hello\x00world"))
      expect(input.value).to eq("helloworld")
    end

    it "respects char_limit on paste" do
      input.char_limit = 5
      input.update(paste("hello world"))
      expect(input.value).to eq("hello")
    end

    it "ignores paste when not focused" do
      unfocused = described_class.new
      unfocused.update(paste("hello"))
      expect(unfocused.value).to eq("")
    end
  end

  describe "char_limit" do
    it "prevents input beyond limit" do
      input.char_limit = 3
      input.update(key("a"))
      input.update(key("b"))
      input.update(key("c"))
      input.update(key("d"))
      expect(input.value).to eq("abc")
    end

    it "truncates value= assignment" do
      input.char_limit = 3
      input.value = "hello"
      expect(input.value).to eq("hel")
    end

    it "0 means unlimited" do
      input.char_limit = 0
      20.times { input.update(key("x")) }
      expect(input.value.length).to eq(20)
    end

    it "does not crash on paste when char_limit lowered below value length" do
      input.value = "hello"
      input.char_limit = 3
      expect { input.update(paste("x")) }.not_to raise_error
      expect(input.value).to eq("hello") # paste rejected, existing value unchanged
    end

    it "does not crash on char input when char_limit lowered below value length" do
      input.value = "hello"
      input.char_limit = 3
      expect { input.update(key("x")) }.not_to raise_error
      expect(input.value).to eq("hello") # input rejected
    end
  end

  describe "echo modes" do
    it "shows password characters in password mode" do
      input.echo_mode = :password
      input.value = "secret"
      input.position = 6
      expect(input.view).to include("******")
    end

    it "uses custom echo_char" do
      input.echo_mode = :password
      input.echo_char = "#"
      input.value = "abc"
      input.position = 3
      expect(input.view).to include("###")
    end

    it "truncates multi-character echo_char to 1 character" do
      input.echo_char = "**"
      expect(input.echo_char).to eq("*")
    end

    it "falls back to * for empty echo_char" do
      input.echo_char = ""
      expect(input.echo_char).to eq("*")
    end

    it "shows nothing in none mode" do
      input.echo_mode = :none
      input.value = "secret"
      # View should only have prompt and cursor
      expect(input.view).not_to include("secret")
    end

    it "word ops jump to boundaries in password mode" do
      input.echo_mode = :password
      input.value = "hello world"
      input.position = 6
      input.update(key(:right, mod: [:alt]))
      expect(input.position).to eq(11) # jumps to end
    end

    it "word ops jump to boundaries in none mode" do
      input.echo_mode = :none
      input.value = "hello world"
      input.position = 6
      input.update(key(:left, mod: [:alt]))
      expect(input.position).to eq(0) # jumps to start
    end
  end

  describe "placeholder" do
    it "shows placeholder when empty and unfocused" do
      ti = described_class.new(prompt: "> ", placeholder: "type here")
      expect(ti.view).to eq("> type here")
    end

    it "does not show placeholder when focused" do
      ti = described_class.new(placeholder: "type here").focus
      expect(ti.view).not_to include("type here")
    end

    it "does not show placeholder when value is present" do
      ti = described_class.new(placeholder: "type here")
      ti.value = "hello"
      expect(ti.view).not_to include("type here")
    end
  end

  describe "validation" do
    it "runs validate on input and sets err" do
      validator = ->(v) { v.length > 3 ? "too long" : nil }
      ti = described_class.new(validate: validator).focus
      ti.update(key("a"))
      expect(ti.err).to be_nil
      ti.update(key("b"))
      ti.update(key("c"))
      ti.update(key("d"))
      expect(ti.err).to eq("too long")
    end

    it "clears err when valid again" do
      validator = ->(v) { v.length > 3 ? "too long" : nil }
      ti = described_class.new(validate: validator).focus
      4.times { ti.update(key("a")) }
      expect(ti.err).to eq("too long")
      ti.update(key(:backspace))
      expect(ti.err).to be_nil
    end

    it "runs validate on value= assignment" do
      validator = ->(v) { v.empty? ? "required" : nil }
      ti = described_class.new(validate: validator)
      ti.value = ""
      expect(ti.err).to eq("required")
      ti.value = "ok"
      expect(ti.err).to be_nil
    end
  end

  describe "value= and position=" do
    it "sets value and clamps position" do
      input.value = "hi"
      input.position = 10
      expect(input.position).to eq(2)
    end

    it "clamps position to 0" do
      input.value = "hi"
      input.position = -5
      expect(input.position).to eq(0)
    end
  end

  describe "horizontal scrolling" do
    it "scrolls when cursor exceeds width" do
      ti = described_class.new(prompt: "> ", width: 10).focus
      # content_width = 10 - 2 = 8
      "abcdefghij".each_char { |c| ti.update(key(c)) }
      view = ti.view
      # Should show the tail portion, not the beginning
      expect(view).not_to start_with("> abcde")
    end

    it "scrolls back when cursor moves left" do
      ti = described_class.new(prompt: "", width: 5).focus
      "abcdefgh".each_char { |c| ti.update(key(c)) }
      # Cursor is at 8, offset should be 4 (showing chars 4-8)
      8.times { ti.update(key(:left)) }
      # After going to position 0, offset should be 0
      expect(ti.view).to include("a")
    end
  end

  describe "#view" do
    it "shows reverse-video cursor when focused" do
      input.value = "hi"
      input.position = 1
      expect(input.view).to include("\e[7m")
      expect(input.view).to include("\e[0m")
    end

    it "shows cursor at end of text" do
      input.value = "hi"
      input.position = 2
      expect(input.view).to include("hi\e[7m \e[0m")
    end

    it "shows prompt" do
      ti = described_class.new(prompt: "> ").focus
      ti.value = "hi"
      ti.position = 2
      expect(ti.view).to start_with("> ")
    end

    it "shows no cursor when not focused" do
      ti = described_class.new
      ti.value = "hi"
      expect(ti.view).to eq("hi")
      expect(ti.view).not_to include("\e[7m")
    end
  end

  describe "#update return value" do
    it "returns [self, nil]" do
      result, cmd = input.update(key("a"))
      expect(result).to equal(input)
      expect(cmd).to be_nil
    end

    it "ignores unrelated message types" do
      result, cmd = input.update(Chamomile::WindowSizeMsg.new(width: 80, height: 24))
      expect(result).to equal(input)
      expect(cmd).to be_nil
      expect(input.value).to eq("")
    end
  end

  describe "edge cases" do
    it "handles deletion on empty value" do
      expect { input.update(key(:backspace)) }.not_to raise_error
      expect { input.update(key(:delete)) }.not_to raise_error
      expect { input.update(key(:backspace, mod: [:alt])) }.not_to raise_error
      expect { input.update(key(:delete, mod: [:alt])) }.not_to raise_error
      expect { input.update(key("u", mod: [:ctrl])) }.not_to raise_error
      expect { input.update(key("k", mod: [:ctrl])) }.not_to raise_error
      expect(input.value).to eq("")
    end

    it "handles paste of only non-printable characters" do
      input.update(paste("\x01\x02\x03"))
      expect(input.value).to eq("")
    end

    it "handles value= with nil" do
      input.value = nil
      expect(input.value).to eq("")
    end

    it "handles value= with integer" do
      input.value = 42
      expect(input.value).to eq("42")
    end

    it "shows cursor block on empty focused input with no placeholder" do
      expect(input.view).to eq("\e[7m \e[0m")
    end

    it "handles paste at middle of value near char_limit" do
      input.char_limit = 8
      input.value = "hello"
      input.position = 3
      input.update(paste("xxxxx"))
      expect(input.value.length).to be <= 8
      expect(input.value).to eq("helxxxlo")
    end

    it "handles word movement with consecutive spaces" do
      input.value = "a   b"
      input.position = 0
      input.update(key(:right, mod: [:alt]))
      expect(input.position).to eq(4) # past "a   "
    end

    it "handles word movement with leading spaces" do
      input.value = "  hello"
      input.position = 7
      input.update(key(:left, mod: [:alt]))
      expect(input.position).to eq(2) # before "hello"
    end
  end
end
