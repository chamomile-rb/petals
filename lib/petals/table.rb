# frozen_string_literal: true

module Petals
  # Tabular data display with selection, scrolling, and focus gating.
  class Table
    Column = Data.define(:title, :width)

    attr_accessor :columns, :key_map, :height
    attr_reader :cursor, :rows

    # Accepts columns as keyword arg or via block DSL.
    #
    #   # Keyword form (original)
    #   Table.new(columns: [Column.new(title: "Name", width: 20)], rows: rows)
    #
    #   # Block DSL form (new)
    #   Table.new(rows: rows) do |t|
    #     t.column "Name", width: 20
    #     t.column "Size", width: 10
    #   end
    #
    #   # Hash form (new)
    #   Table.new(columns: [{ title: "Name", width: 20 }], rows: rows)
    def initialize(columns: [], rows: [], height: 10, key_map: DEFAULT_KEY_MAP, &block)
      @columns = normalize_columns(columns)
      @rows = rows
      @height = height
      @key_map = key_map
      @cursor = 0
      @offset = 0
      @focused = false

      if block
        builder = ColumnBuilder.new
        block.call(builder)
        @columns = builder.columns unless builder.columns.empty?
      end
    end

    def rows=(rows)
      @rows = rows
      @cursor = @cursor.clamp(0, [row_count - 1, 0].max)
      clamp_offset
    end

    def selected_row
      return nil if @rows.empty?

      @rows[@cursor]
    end

    def move_up(n = 1)
      @cursor = (@cursor - n).clamp(0, [row_count - 1, 0].max)
      clamp_offset
    end

    def move_down(n = 1)
      @cursor = (@cursor + n).clamp(0, [row_count - 1, 0].max)
      clamp_offset
    end

    def goto_top
      @cursor = 0
      clamp_offset
    end

    def goto_bottom
      @cursor = [row_count - 1, 0].max
      clamp_offset
    end

    def cursor=(n)
      @cursor = n.clamp(0, [row_count - 1, 0].max)
      clamp_offset
    end

    def focus
      @focused = true
      self
    end

    def blur
      @focused = false
      self
    end

    def focused?
      @focused
    end

    # Handle an incoming event.
    def handle(msg)
      return unless @focused

      case msg
      when Chamomile::KeyEvent
        handle_key(msg)
      end

      nil
    end

    # Backward compat alias
    alias update handle

    def view
      header = render_header
      separator = render_separator
      body = render_body

      [header, separator, body].compact.join("\n")
    end

    # DSL builder for column definitions.
    class ColumnBuilder
      attr_reader :columns

      def initialize
        @columns = []
      end

      def column(title, width: 20)
        @columns << Column.new(title: title, width: width)
      end
    end

    private

    def normalize_columns(columns)
      columns.map do |col|
        case col
        when Column
          col
        when Hash
          Column.new(title: col[:title], width: col[:width] || 20)
        else
          col
        end
      end
    end

    def row_count
      @rows.length
    end

    def handle_key(msg)
      kb = KeyBinding
      if kb.key_matches?(msg, @key_map, :up)
        move_up
      elsif kb.key_matches?(msg, @key_map, :down)
        move_down
      elsif kb.key_matches?(msg, @key_map, :page_up)
        move_up(@height)
      elsif kb.key_matches?(msg, @key_map, :page_down)
        move_down(@height)
      elsif kb.key_matches?(msg, @key_map, :goto_top)
        goto_top
      elsif kb.key_matches?(msg, @key_map, :goto_bottom)
        goto_bottom
      end
    end

    def render_header
      return "" if @columns.empty?

      @columns.map { |col| truncate_pad(col.title, col.width) }.join(" ")
    end

    def render_separator
      return "" if @columns.empty?

      @columns.map { |col| "\u2500" * col.width }.join(" ")
    end

    def render_body
      return "" if @rows.empty?

      visible = @rows[@offset, @height] || []
      lines = visible.each_with_index.map do |row, i|
        idx = @offset + i
        line = render_row(row)
        if idx == @cursor
          "\e[7m#{line}\e[0m"
        else
          line
        end
      end
      lines.join("\n")
    end

    def render_row(row)
      @columns.each_with_index.map do |col, i|
        cell = row[i].to_s
        truncate_pad(cell, col.width)
      end.join(" ")
    end

    def truncate_pad(text, width)
      if text.length > width
        width > 1 ? "#{text[0, width - 1]}\u2026" : text[0, width]
      else
        text.ljust(width)
      end
    end

    def clamp_offset
      return if @rows.empty?

      @offset = @cursor if @cursor < @offset
      @offset = @cursor - @height + 1 if @cursor >= @offset + @height
      @offset = [0, @offset].max
    end
  end
end
