# frozen_string_literal: true

module Petals
  FilePickerReadDirMsg = Data.define(:id, :entries)

  # Filesystem browser with async directory reading, navigation, and filtering.
  class FilePicker
    @next_id = 0
    @id_mutex = Mutex.new
    @id_pid = Process.pid

    def self.next_id
      @id_mutex.synchronize do
        if Process.pid != @id_pid
          @id_pid = Process.pid
          @next_id = 0
          @id_mutex = Mutex.new
        end
        @next_id += 1
        "#{@id_pid}-fp-#{@next_id}"
      end
    end

    attr_reader :id, :current_directory, :selected_path
    attr_accessor :key_map, :allowed_types, :show_permissions, :show_size,
                  :show_hidden, :dir_allowed, :file_allowed, :height, :cursor_char

    def initialize(directory: Dir.pwd, key_map: DEFAULT_KEY_MAP, height: 10,
                   allowed_types: [], show_permissions: false, show_size: false,
                   show_hidden: false, dir_allowed: false, file_allowed: true,
                   cursor_char: ">")
      @id = self.class.next_id
      @current_directory = File.expand_path(directory)
      @key_map = key_map
      @height = height
      @allowed_types = allowed_types
      @show_permissions = show_permissions
      @show_size = show_size
      @show_hidden = show_hidden
      @dir_allowed = dir_allowed
      @file_allowed = file_allowed
      @cursor_char = cursor_char
      @cursor = 0
      @entries = []
      @offset = 0
      @selected_path = nil
      @disabled_selected_path = nil
      @dir_stack = []
    end

    def init_cmd
      read_dir_cmd(@current_directory)
    end

    def handle(msg)
      case msg
      when FilePickerReadDirMsg
        return unless msg.id == @id

        @entries = msg.entries
        @cursor = @cursor.clamp(0, [entries_size - 1, 0].max)
        clamp_offset
        nil
      when Chamomile::KeyEvent
        handle_key(msg)
      end
    end

    alias update handle

    def view
      return "  (empty)" if @entries.empty?

      visible = visible_entries
      lines = visible.each_with_index.map do |entry, i|
        idx = @offset + i
        prefix = idx == @cursor ? "#{@cursor_char} " : "  "
        line = prefix + format_entry(entry)
        if idx == @cursor
          "\e[7m#{line}\e[0m"
        else
          line
        end
      end
      lines.join("\n")
    end

    def highlighted_path
      return nil if @entries.empty?

      entry = @entries[@cursor]
      return nil unless entry

      File.join(@current_directory, entry[:name])
    end

    def did_select_file?(msg)
      return [false, nil] unless msg.is_a?(Chamomile::KeyEvent)

      if @selected_path
        path = @selected_path
        @selected_path = nil
        [true, path]
      else
        [false, nil]
      end
    end

    def did_select_disabled_file?(msg)
      return [false, nil] unless msg.is_a?(Chamomile::KeyEvent)

      if @disabled_selected_path
        path = @disabled_selected_path
        @disabled_selected_path = nil
        [true, path]
      else
        [false, nil]
      end
    end

    private

    def handle_key(msg)
      kb = KeyBinding

      if kb.key_matches?(msg, @key_map, :up)
        move_cursor(-1)
      elsif kb.key_matches?(msg, @key_map, :down)
        move_cursor(1)
      elsif kb.key_matches?(msg, @key_map, :page_up)
        move_cursor(-@height)
      elsif kb.key_matches?(msg, @key_map, :page_down)
        move_cursor(@height)
      elsif kb.key_matches?(msg, @key_map, :goto_top)
        move_cursor(-entries_size)
      elsif kb.key_matches?(msg, @key_map, :goto_bottom)
        move_cursor(entries_size)
      elsif kb.key_matches?(msg, @key_map, :open)
        open_entry
      elsif kb.key_matches?(msg, @key_map, :back)
        go_back
      elsif kb.key_matches?(msg, @key_map, :toggle_hidden)
        @show_hidden = !@show_hidden
        read_dir_cmd(@current_directory)
      end
    end

    def move_cursor(delta)
      return if @entries.empty?

      @cursor = (@cursor + delta).clamp(0, entries_size - 1)
      clamp_offset
      nil
    end

    def open_entry
      return nil if @entries.empty?

      entry = @entries[@cursor]
      return nil unless entry

      path = File.join(@current_directory, entry[:name])

      if selectable?(entry)
        @selected_path = path
      elsif !entry[:directory] && @allowed_types.any?
        @disabled_selected_path = path
      end

      if entry[:directory]
        @dir_stack.push({ directory: @current_directory, cursor: @cursor, offset: @offset })
        @current_directory = path
        @cursor = 0
        @offset = 0
        return read_dir_cmd(path)
      end

      nil
    end

    def go_back
      parent = File.dirname(@current_directory)
      return nil if parent == @current_directory

      if @dir_stack.any?
        prev = @dir_stack.pop
        @current_directory = prev[:directory]
        @cursor = prev[:cursor]
        @offset = prev[:offset]
      else
        @current_directory = parent
        @cursor = 0
        @offset = 0
      end

      read_dir_cmd(@current_directory)
    end

    def read_dir_cmd(dir)
      captured_id = @id
      show_hidden = @show_hidden
      -> {
        entries = begin
          Dir.entries(dir)
             .reject { |e| [".", ".."].include?(e) }
             .reject { |e| !show_hidden && e.start_with?(".") }
             .map { |e| build_entry(dir, e) }
             .sort_by { |e| [e[:directory] ? 0 : 1, e[:name].downcase] }
        rescue SystemCallError
          []
        end
        FilePickerReadDirMsg.new(id: captured_id, entries: entries)
      }
    end

    def build_entry(dir, name)
      path = File.join(dir, name)
      stat = begin
        File.stat(path)
      rescue SystemCallError
        nil
      end

      {
        name: name,
        directory: stat&.directory? || false,
        size: stat&.size || 0,
        permissions: stat ? format("%o", stat.mode & 0o7777) : "0000",
      }
    end

    def selectable?(entry)
      if entry[:directory]
        @dir_allowed
      else
        return false unless @file_allowed
        return true if @allowed_types.empty?

        ext = File.extname(entry[:name]).downcase
        @allowed_types.any? { |t| t.downcase == ext || ".#{t.downcase}" == ext }
      end
    end

    def format_entry(entry)
      parts = []
      parts << (entry[:directory] ? "#{entry[:name]}/" : entry[:name])
      parts << human_size(entry[:size]) if @show_size && !entry[:directory]
      parts << entry[:permissions] if @show_permissions
      parts.join("  ")
    end

    def human_size(bytes)
      return "0B" if bytes.zero?

      units = %w[B KB MB GB TB]
      exp = (Math.log(bytes) / Math.log(1024)).floor
      exp = [exp, units.length - 1].min
      size = bytes.to_f / (1024**exp)
      exp.zero? ? "#{bytes}B" : format("%.1f%s", size, units[exp])
    end

    def entries_size
      @entries.length
    end

    def visible_entries
      @entries[@offset, @height] || []
    end

    def clamp_offset
      return if @entries.empty?

      @offset = @cursor if @cursor < @offset
      @offset = @cursor - @height + 1 if @cursor >= @offset + @height
      @offset = [0, @offset].max
    end
  end
end
