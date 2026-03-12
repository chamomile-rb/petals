# frozen_string_literal: true

module Petals
  FilterMatchesMsg = Data.define(:matches)
  ListStatusTimeoutMsg = Data.define(:id)

  # Batteries-included item browser composing Paginator, TextInput, Spinner, Help.
  class List
    FILTER_UNFILTERED = :unfiltered
    FILTER_FILTERING  = :filtering
    FILTER_APPLIED    = :applied

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
        "#{@id_pid}-lst-#{@next_id}"
      end
    end

    attr_reader :id, :cursor, :filter_state, :status_message
    attr_accessor :key_map, :title, :width, :height,
                  :show_title, :show_filter, :show_status_bar,
                  :show_pagination, :show_help, :filtering_enabled,
                  :delegate, :infinite_scroll

    def initialize(items:, width: 80, height: 24, delegate: nil, key_map: DEFAULT_KEY_MAP)
      @id = self.class.next_id
      @all_items = items.dup
      @filtered_items = @all_items.dup
      @width = width
      @height = height
      @delegate = delegate
      @key_map = key_map
      @title = ""
      @cursor = 0
      @show_title = true
      @show_filter = true
      @show_status_bar = true
      @show_pagination = true
      @show_help = true
      @filtering_enabled = true
      @filter_state = FILTER_UNFILTERED
      @infinite_scroll = false
      @spinner_visible = false
      @status_message = nil

      @paginator = Paginator.new(per_page: items_per_page)
      @filter_input = TextInput.new(prompt: "/ ")
      @spinner = Spinner.new
      @help = Help.new(width: width)
      @help_bindings = [
        { key: "/", desc: "filter" },
        { key: "esc", desc: "clear" },
        { key: "q", desc: "quit" },
        { key: "?", desc: "more" },
      ]

      recalculate
    end

    def items
      @filtered_items
    end

    def items=(new_items)
      @all_items = new_items.dup
      apply_filter
      recalculate
    end

    def set_item(index, item)
      return if index.negative? || index >= @all_items.length

      @all_items[index] = item
      apply_filter
      recalculate
    end

    def insert_item(index, item)
      index = index.clamp(0, @all_items.length)
      @all_items.insert(index, item)
      apply_filter
      recalculate
    end

    def remove_item(index)
      return nil if index.negative? || index >= @all_items.length

      removed = @all_items.delete_at(index)
      apply_filter
      recalculate
      removed
    end

    def selected_item
      return nil if @filtered_items.empty?

      @filtered_items[@cursor]
    end

    def index
      @cursor
    end

    def global_index
      return nil if @filtered_items.empty?

      item = selected_item
      @all_items.index(item)
    end

    def cursor_up
      @cursor = if @infinite_scroll && @cursor.zero? && filtered_count.positive?
                  filtered_count - 1
                else
                  (@cursor - 1).clamp(0, [filtered_count - 1, 0].max)
                end
      update_paginator_page
    end

    def cursor_down
      @cursor = if @infinite_scroll && @cursor >= filtered_count - 1 && filtered_count.positive?
                  0
                else
                  (@cursor + 1).clamp(0, [filtered_count - 1, 0].max)
                end
      update_paginator_page
    end

    def goto_start
      @cursor = 0
      update_paginator_page
    end

    def goto_end
      @cursor = [filtered_count - 1, 0].max
      update_paginator_page
    end

    def prev_page
      @paginator.prev_page
      @cursor = @paginator.page * items_per_page
      @cursor = @cursor.clamp(0, [filtered_count - 1, 0].max)
    end

    def next_page
      @paginator.next_page
      @cursor = @paginator.page * items_per_page
      @cursor = @cursor.clamp(0, [filtered_count - 1, 0].max)
    end

    def filter_value
      @filter_input.value
    end

    def reset_filter
      @filter_input.value = ""
      @filter_state = FILTER_UNFILTERED
      @filter_input.blur
      @filtered_items = @all_items.dup
      @cursor = 0
      recalculate
    end

    def set_filter_text(text)
      if text.nil? || text.empty?
        reset_filter
        return
      end

      @filter_input.value = text
      @filter_state = FILTER_APPLIED
      @filter_input.blur
      apply_filter
      recalculate
    end

    def visible_items
      start, length = @paginator.slice_bounds(filtered_count)
      @filtered_items[start, length] || []
    end

    def new_status_message(text, lifetime: 1.0)
      @status_message = text
      captured_id = @id
      -> {
        sleep(lifetime)
        ListStatusTimeoutMsg.new(id: captured_id)
      }
    end

    def start_spinner
      @spinner_visible = true
      @spinner.tick_cmd
    end

    def stop_spinner
      @spinner_visible = false
      nil
    end

    def spinner_visible?
      @spinner_visible
    end

    def handle(msg)
      case msg
      when Chamomile::KeyEvent
        handle_key(msg)
      when SpinnerTickMsg
        @spinner.update(msg)
        nil
      when FilterMatchesMsg
        @filtered_items = msg.matches
        @cursor = @cursor.clamp(0, [filtered_count - 1, 0].max)
        recalculate
        nil
      when ListStatusTimeoutMsg
        @status_message = nil if msg.id == @id
        nil
      end
    end

    alias update handle

    def view
      sections = []

      sections << render_title if @show_title && !@title.empty?
      sections << render_filter if @show_filter && @filter_state != FILTER_UNFILTERED
      sections << render_status_bar if @show_status_bar
      sections << render_items
      sections << @paginator.view if @show_pagination && @paginator.total_pages > 1
      sections << render_help if @show_help

      sections.compact.reject(&:empty?).join("\n")
    end

    private

    def filtered_count
      @filtered_items.length
    end

    def items_per_page
      # Reserve lines for chrome (title, status, pagination, help, filter)
      available = @height
      available -= 1 if @show_title && !@title.empty?
      available -= 1 if @show_status_bar
      available -= 1 if @show_pagination
      available -= 1 if @show_help
      available -= 1 if @show_filter && @filter_state != FILTER_UNFILTERED
      [available, 1].max
    end

    def handle_key(msg)
      return handle_filter_key(msg) if @filter_state == FILTER_FILTERING

      kb = KeyBinding

      if kb.key_matches?(msg, @key_map, :cursor_up)
        cursor_up
      elsif kb.key_matches?(msg, @key_map, :cursor_down)
        cursor_down
      elsif kb.key_matches?(msg, @key_map, :next_page)
        next_page
      elsif kb.key_matches?(msg, @key_map, :prev_page)
        prev_page
      elsif kb.key_matches?(msg, @key_map, :goto_start)
        goto_start
      elsif kb.key_matches?(msg, @key_map, :goto_end)
        goto_end
      elsif kb.key_matches?(msg, @key_map, :filter) && @filtering_enabled
        start_filter
      elsif kb.key_matches?(msg, @key_map, :clear_filter) && @filter_state == FILTER_APPLIED
        reset_filter
      elsif kb.key_matches?(msg, @key_map, :show_full_help)
        @help.show_all = !@help.show_all
      end

      nil
    end

    def handle_filter_key(msg)
      kb = KeyBinding

      if kb.key_matches?(msg, @key_map, :accept_filter)
        accept_filter
      elsif kb.key_matches?(msg, @key_map, :clear_filter)
        reset_filter
      else
        @filter_input.update(msg)
        apply_filter
        recalculate
      end

      nil
    end

    def start_filter
      @filter_state = FILTER_FILTERING
      @filter_input.value = ""
      @filter_input.focus
      recalculate
    end

    def accept_filter
      @filter_input.blur
      if @filter_input.value.empty?
        reset_filter
      else
        @filter_state = FILTER_APPLIED
      end
    end

    def apply_filter
      if @filter_input.value.empty? || @filter_state == FILTER_UNFILTERED
        @filtered_items = @all_items.dup
      else
        query = @filter_input.value.downcase
        @filtered_items = @all_items.select { |item| fuzzy_match?(item, query) }
      end
      @cursor = @cursor.clamp(0, [filtered_count - 1, 0].max)
    end

    def fuzzy_match?(item, query)
      text = item_filter_value(item).downcase
      # Character-by-character fuzzy match
      qi = 0
      text.each_char do |c|
        qi += 1 if c == query[qi]
        return true if qi >= query.length
      end
      false
    end

    def item_filter_value(item)
      if item.respond_to?(:filter_value)
        item.filter_value
      elsif item.respond_to?(:title)
        item.title
      elsif item.is_a?(String)
        item
      else
        item.to_s
      end
    end

    def recalculate
      per = items_per_page
      @paginator.per_page = per
      @paginator.total_pages_from_items(filtered_count)
      update_paginator_page
    end

    def update_paginator_page
      return if items_per_page <= 0

      @paginator.page = @cursor / items_per_page
    end

    def render_title
      @title
    end

    def render_filter
      @filter_input.view
    end

    def render_status_bar
      prefix = @spinner_visible ? "#{@spinner.view} " : ""
      text = if @status_message
               @status_message
             elsif @filter_state == FILTER_APPLIED
               "#{filtered_count} items (filtered from #{@all_items.length})"
             else
               "#{filtered_count} items"
             end
      "#{prefix}#{text}"
    end

    def render_items
      return "  (no items)" if @filtered_items.empty?

      start, length = @paginator.slice_bounds(filtered_count)
      visible = @filtered_items[start, length] || []

      lines = visible.each_with_index.map do |item, i|
        idx = start + i
        line = render_item(item, idx)
        if idx == @cursor
          "\e[7m  #{line}\e[0m"
        else
          "  #{line}"
        end
      end

      lines.join("\n")
    end

    def render_item(item, idx)
      if @delegate.respond_to?(:render)
        @delegate.render(self, idx, item)
      else
        default_render(item)
      end
    end

    def default_render(item)
      if item.respond_to?(:title) && item.respond_to?(:description)
        "#{item.title} - #{item.description}"
      elsif item.respond_to?(:title)
        item.title.to_s
      elsif item.is_a?(String)
        item
      else
        item.to_s
      end
    end

    def render_help
      @help.view(@help_bindings)
    end
  end
end
