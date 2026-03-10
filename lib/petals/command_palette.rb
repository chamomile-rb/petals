# frozen_string_literal: true

module Petals
  # A fuzzy-search command palette overlay.
  # Renders as a centered modal over existing content.
  #
  # Usage:
  #   @palette = Petals::CommandPalette.new(
  #     items: [
  #       { label: "Run migrations", action: :run_migrate, key: "db:migrate" },
  #       { label: "Start server", action: :server_start, key: "server" },
  #     ]
  #   )
  #   # In update:
  #   when KeyMsg
  #     if @palette.visible?
  #       result = @palette.handle_key(msg)
  #       return result[:action] if result
  #     end
  class CommandPalette
    Item = Data.define(:label, :action, :key)

    attr_reader :query, :cursor

    def initialize(items:, placeholder: "Type to filter...")
      @all_items   = items.map { |i| Item.new(**i) }
      @placeholder = placeholder
      @query       = ""
      @cursor      = 0
      @visible     = false
    end

    def show
      @visible = true
      @query   = ""
      @cursor  = 0
    end

    def hide
      @visible = false
    end

    def visible? = @visible

    def handle_key(msg)
      return nil unless @visible

      case msg.key
      when :escape
        hide
        nil
      when :enter
        selected = filtered_items[@cursor]
        hide
        selected
      when :up, "k"
        @cursor = [@cursor - 1, 0].max
        nil
      when :down, "j"
        max = filtered_items.size - 1
        @cursor = (@cursor + 1).clamp(0, [max, 0].max)
        nil
      when :backspace
        @query = @query[0..-2] || ""
        @cursor = 0
        nil
      else
        if msg.key.is_a?(String) && msg.key.length == 1
          @query += msg.key
          @cursor = 0
        end
        nil
      end
    end

    def render(width:, height:)
      return "" unless @visible

      items = filtered_items
      modal_width  = [width - 8, 60].min
      modal_height = [items.size + 4, height - 4, 16].min

      lines = []
      query_display = @query.empty? ? "\e[38;5;240m#{@placeholder}\e[0m" : @query
      lines << "  > #{query_display}"
      lines << ("\u2500" * (modal_width - 2))

      visible_items = items.first(modal_height - 4)
      visible_items.each_with_index do |item, i|
        prefix = i == @cursor ? "\u25b6 " : "  "
        line   = "#{prefix}#{item.label}"
        lines << (i == @cursor ? "\e[7m#{line}\e[0m" : line)
      end

      lines << ("\u2500" * (modal_width - 2))
      lines << "\e[38;5;240m  \u2191\u2193 navigate  Enter select  Esc cancel\e[0m"

      box_lines = lines.map { |l| "\u2502 #{l.ljust(modal_width - 4)} \u2502" }
      top    = "┌#{"\u2500" * (modal_width - 2)}┐"
      bottom = "└#{"\u2500" * (modal_width - 2)}┘"

      ([top] + box_lines + [bottom]).join("\n")
    end

    def filtered_items
      return @all_items if @query.empty?

      q = @query.downcase
      @all_items.select do |item|
        item.label.downcase.include?(q) || item.key.to_s.downcase.include?(q)
      end
    end
  end
end
