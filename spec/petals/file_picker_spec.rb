# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::FilePicker do
  def key(k, mod: []) = Chamomile::KeyMsg.new(key: k, mod: mod)

  # Helper to create a FilePicker and feed it entries
  def picker_with_entries(entries, **opts)
    fp = described_class.new(**opts)
    msg = Petals::FilePickerReadDirMsg.new(id: fp.id, entries: entries)
    fp.update(msg)
    fp
  end

  let(:sample_entries) do
    [
      { name: "docs", directory: true, size: 0, permissions: "0755" },
      { name: "src", directory: true, size: 0, permissions: "0755" },
      { name: "README.md", directory: false, size: 1024, permissions: "0644" },
      { name: "main.rb", directory: false, size: 256, permissions: "0644" },
    ]
  end

  describe "initialization" do
    it "assigns unique IDs" do
      ids = 5.times.map { described_class.new.id }
      expect(ids.uniq.size).to eq(5)
    end

    it "defaults height to 10" do
      fp = described_class.new
      expect(fp.height).to eq(10)
    end

    it "defaults show_hidden to false" do
      fp = described_class.new
      expect(fp.show_hidden).to be false
    end

    it "defaults file_allowed to true" do
      fp = described_class.new
      expect(fp.file_allowed).to be true
    end

    it "defaults dir_allowed to false" do
      fp = described_class.new
      expect(fp.dir_allowed).to be false
    end

    it "defaults cursor_char to >" do
      fp = described_class.new
      expect(fp.cursor_char).to eq(">")
    end

    it "uses current directory by default" do
      fp = described_class.new
      expect(fp.current_directory).to eq(File.expand_path(Dir.pwd))
    end
  end

  describe "#init_cmd" do
    it "returns a callable" do
      fp = described_class.new(directory: Dir.pwd)
      expect(fp.init_cmd).to respond_to(:call)
    end

    it "produces a FilePickerReadDirMsg" do
      fp = described_class.new(directory: Dir.pwd)
      msg = fp.init_cmd.call
      expect(msg).to be_a(Petals::FilePickerReadDirMsg)
      expect(msg.id).to eq(fp.id)
    end

    it "returns entries sorted dirs first then alphabetically" do
      fp = described_class.new(directory: Dir.pwd)
      msg = fp.init_cmd.call
      dirs = msg.entries.select { |e| e[:directory] }
      files = msg.entries.reject { |e| e[:directory] }
      # Dirs come before files
      dir_indices = msg.entries.each_index.select { |i| msg.entries[i][:directory] }
      file_indices = msg.entries.each_index.reject { |i| msg.entries[i][:directory] }
      expect(dir_indices.max).to be < file_indices.min unless dir_indices.empty? || file_indices.empty?
      # Each group is sorted
      expect(dirs.map { |d| d[:name].downcase }).to eq(dirs.map { |d| d[:name].downcase }.sort)
      expect(files.map { |f| f[:name].downcase }).to eq(files.map { |f| f[:name].downcase }.sort)
    end
  end

  describe "navigation" do
    it "moves cursor down" do
      fp = picker_with_entries(sample_entries)
      fp.update(key(:down))
      expect(fp.highlighted_path).to include("src")
    end

    it "moves cursor up" do
      fp = picker_with_entries(sample_entries)
      fp.update(key(:down))
      fp.update(key(:down))
      fp.update(key(:up))
      expect(fp.highlighted_path).to include("src")
    end

    it "clamps cursor at top" do
      fp = picker_with_entries(sample_entries)
      fp.update(key(:up))
      expect(fp.highlighted_path).to include("docs")
    end

    it "clamps cursor at bottom" do
      fp = picker_with_entries(sample_entries)
      10.times { fp.update(key(:down)) }
      expect(fp.highlighted_path).to include("main.rb")
    end

    it "uses j/k for navigation" do
      fp = picker_with_entries(sample_entries)
      fp.update(key("j"))
      expect(fp.highlighted_path).to include("src")
      fp.update(key("k"))
      expect(fp.highlighted_path).to include("docs")
    end
  end

  describe "directory entry/exit" do
    it "enters a directory on enter" do
      fp = picker_with_entries(sample_entries)
      # First entry is "docs" directory
      cmd = fp.update(key(:enter))
      expect(cmd).to respond_to(:call)
      expect(fp.current_directory).to include("docs")
    end

    it "goes back on backspace" do
      fp = picker_with_entries(sample_entries)
      original_dir = fp.current_directory
      fp.update(key(:enter)) # enter docs
      cmd = fp.update(key(:backspace)) # go back
      expect(cmd).to respond_to(:call)
      expect(fp.current_directory).to eq(original_dir)
    end

    it "preserves cursor position on back" do
      fp = picker_with_entries(sample_entries)
      fp.update(key(:down)) # move to "src"
      fp.update(key(:enter)) # enter "src"
      fp.update(key(:backspace)) # go back
      # Should restore cursor to where it was
      expect(fp.highlighted_path).to include("src")
    end

    it "uses left arrow for back" do
      fp = picker_with_entries(sample_entries)
      fp.update(key(:enter))
      cmd = fp.update(key(:left))
      expect(cmd).to respond_to(:call)
    end
  end

  describe "file selection" do
    it "selects a file on enter" do
      fp = picker_with_entries(sample_entries)
      # Move to README.md (index 2)
      fp.update(key(:down))
      fp.update(key(:down))
      fp.update(key(:enter))
      selected, path = fp.did_select_file?(key(:enter))
      expect(selected).to be true
      expect(path).to include("README.md")
    end

    it "does not select a directory when dir_allowed is false" do
      fp = picker_with_entries(sample_entries)
      # First entry is a directory
      fp.update(key(:enter)) # enters directory instead of selecting
      selected, = fp.did_select_file?(key(:enter))
      expect(selected).to be false
    end

    it "clears selected_path after did_select_file?" do
      fp = picker_with_entries(sample_entries)
      fp.update(key(:down))
      fp.update(key(:down))
      fp.update(key(:enter))
      fp.did_select_file?(key(:enter))
      selected, = fp.did_select_file?(key(:enter))
      expect(selected).to be false
    end
  end

  describe "extension filtering" do
    it "allows all files when allowed_types is empty" do
      fp = picker_with_entries(sample_entries)
      fp.update(key(:down))
      fp.update(key(:down)) # README.md
      fp.update(key(:enter))
      selected, = fp.did_select_file?(key(:enter))
      expect(selected).to be true
    end

    it "rejects files not matching allowed_types" do
      fp = picker_with_entries(sample_entries, allowed_types: [".rb"])
      fp.update(key(:down))
      fp.update(key(:down)) # README.md
      fp.update(key(:enter)) # should not select
      selected, = fp.did_select_file?(key(:enter))
      expect(selected).to be false
    end

    it "accepts files matching allowed_types" do
      fp = picker_with_entries(sample_entries, allowed_types: [".rb"])
      fp.update(key(:down))
      fp.update(key(:down))
      fp.update(key(:down)) # main.rb
      fp.update(key(:enter))
      selected, path = fp.did_select_file?(key(:enter))
      expect(selected).to be true
      expect(path).to include("main.rb")
    end

    it "handles allowed_types without leading dot" do
      fp = picker_with_entries(sample_entries, allowed_types: ["rb"])
      fp.update(key(:down))
      fp.update(key(:down))
      fp.update(key(:down)) # main.rb
      fp.update(key(:enter))
      selected, = fp.did_select_file?(key(:enter))
      expect(selected).to be true
    end
  end

  describe "#view" do
    it "shows entries with cursor" do
      fp = picker_with_entries(sample_entries)
      view = fp.view
      expect(view).to include(">")
      expect(view).to include("docs/")
    end

    it "shows directories with trailing slash" do
      fp = picker_with_entries(sample_entries)
      expect(fp.view).to include("docs/")
      expect(fp.view).to include("src/")
    end

    it "shows (empty) for empty directory" do
      fp = picker_with_entries([])
      expect(fp.view).to eq("  (empty)")
    end

    it "shows file sizes when show_size is true" do
      fp = picker_with_entries(sample_entries, show_size: true)
      # Move to a file entry
      fp.update(key(:down))
      fp.update(key(:down))
      expect(fp.view).to include("1.0KB")
    end

    it "shows permissions when show_permissions is true" do
      fp = picker_with_entries(sample_entries, show_permissions: true)
      expect(fp.view).to include("0755")
    end

    it "highlights selected entry with reverse video" do
      fp = picker_with_entries(sample_entries)
      expect(fp.view).to include("\e[7m")
      expect(fp.view).to include("\e[0m")
    end
  end

  describe "#highlighted_path" do
    it "returns full path of highlighted entry" do
      fp = picker_with_entries(sample_entries)
      expect(fp.highlighted_path).to end_with("docs")
    end

    it "returns nil for empty entries" do
      fp = picker_with_entries([])
      expect(fp.highlighted_path).to be_nil
    end
  end

  describe "page navigation" do
    let(:many_entries) do
      20.times.map { |i| { name: "file#{i.to_s.rjust(2, "0")}.rb", directory: false, size: 100, permissions: "0644" } }
    end

    it "page_down moves cursor by height" do
      fp = picker_with_entries(many_entries, height: 5)
      fp.update(key(:page_down))
      expect(fp.highlighted_path).to include("file05.rb")
    end

    it "page_up moves cursor up by height" do
      fp = picker_with_entries(many_entries, height: 5)
      3.times { fp.update(key(:page_down)) }
      fp.update(key(:page_up))
      expect(fp.highlighted_path).to include("file10.rb")
    end

    it "ctrl+f pages down" do
      fp = picker_with_entries(many_entries, height: 5)
      fp.update(key("f", mod: [:ctrl]))
      expect(fp.highlighted_path).to include("file05.rb")
    end

    it "ctrl+b pages up" do
      fp = picker_with_entries(many_entries, height: 5)
      2.times { fp.update(key(:page_down)) }
      fp.update(key("b", mod: [:ctrl]))
      expect(fp.highlighted_path).to include("file05.rb")
    end

    it "goto_top with g" do
      fp = picker_with_entries(many_entries, height: 5)
      fp.update(key(:page_down))
      fp.update(key("g"))
      expect(fp.highlighted_path).to include("file00.rb")
    end

    it "goto_bottom with G" do
      fp = picker_with_entries(many_entries, height: 5)
      fp.update(key("G", mod: [:shift]))
      expect(fp.highlighted_path).to include("file19.rb")
    end

    it "goto_top with home" do
      fp = picker_with_entries(many_entries, height: 5)
      fp.update(key(:page_down))
      fp.update(key(:home))
      expect(fp.highlighted_path).to include("file00.rb")
    end

    it "goto_bottom with end" do
      fp = picker_with_entries(many_entries, height: 5)
      fp.update(key(:end_key))
      expect(fp.highlighted_path).to include("file19.rb")
    end

    it "page_down clamps at bottom" do
      fp = picker_with_entries(many_entries, height: 5)
      10.times { fp.update(key(:page_down)) }
      expect(fp.highlighted_path).to include("file19.rb")
    end
  end

  describe "disabled file selection" do
    it "sets disabled_selected_path when file does not match type filter" do
      fp = picker_with_entries(sample_entries, allowed_types: [".rb"])
      fp.update(key(:down))
      fp.update(key(:down)) # README.md — not .rb
      fp.update(key(:enter))
      selected, path = fp.did_select_disabled_file?(key(:enter))
      expect(selected).to be true
      expect(path).to include("README.md")
    end

    it "clears disabled_selected_path after read" do
      fp = picker_with_entries(sample_entries, allowed_types: [".rb"])
      fp.update(key(:down))
      fp.update(key(:down))
      fp.update(key(:enter))
      fp.did_select_disabled_file?(key(:enter))
      selected, = fp.did_select_disabled_file?(key(:enter))
      expect(selected).to be false
    end

    it "does not set disabled when no type filter" do
      fp = picker_with_entries(sample_entries)
      fp.update(key(:down))
      fp.update(key(:down))
      fp.update(key(:enter))
      selected, = fp.did_select_disabled_file?(key(:enter))
      expect(selected).to be false
    end
  end

  describe "hidden files" do
    it "toggle_hidden toggles show_hidden" do
      fp = picker_with_entries(sample_entries)
      expect(fp.show_hidden).to be false
      fp.update(key("."))
      expect(fp.show_hidden).to be true
    end
  end

  describe "edge cases" do
    it "handles ReadDirMsg with wrong id" do
      fp = described_class.new
      msg = Petals::FilePickerReadDirMsg.new(id: "wrong", entries: sample_entries)
      fp.update(msg)
      expect(fp.highlighted_path).to be_nil
    end

    it "handles navigation on empty entries" do
      fp = picker_with_entries([])
      expect { fp.update(key(:down)) }.not_to raise_error
      expect { fp.update(key(:up)) }.not_to raise_error
      expect { fp.update(key(:enter)) }.not_to raise_error
    end

    it "handles back at root-like level with no stack" do
      fp = picker_with_entries(sample_entries)
      cmd = fp.update(key(:backspace))
      # Should try to go to parent
      expect(cmd).to respond_to(:call) unless fp.current_directory == "/"
    end
  end

  describe "multiple file pickers" do
    it "each only responds to its own messages" do
      fp1 = described_class.new
      fp2 = described_class.new

      msg1 = Petals::FilePickerReadDirMsg.new(id: fp1.id, entries: sample_entries)
      fp2.update(msg1)
      expect(fp2.highlighted_path).to be_nil

      fp1.update(msg1)
      expect(fp1.highlighted_path).not_to be_nil
    end
  end
end
