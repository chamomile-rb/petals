# frozen_string_literal: true

module Petals
  # Page navigation with dot or arabic display and key binding support.
  class Paginator
    TYPE_DOT    = :dot
    TYPE_ARABIC = :arabic

    attr_reader :page, :total_pages, :per_page
    attr_accessor :type, :key_map, :active_dot, :inactive_dot

    def initialize(total_pages: 1, per_page: 0, type: TYPE_DOT, key_map: DEFAULT_KEY_MAP)
      @total_pages = [total_pages, 1].max
      @per_page = [per_page, 0].max
      @type = type
      @key_map = key_map
      @active_dot = "\u25cf"   # ●
      @inactive_dot = "\u25cb" # ○
      @page = 0
    end

    # Navigation

    def page=(p)
      @page = p.clamp(0, [@total_pages - 1, 0].max)
    end

    def total_pages=(n)
      @total_pages = [n, 1].max
      @page = @page.clamp(0, @total_pages - 1)
    end

    def per_page=(n)
      @per_page = [n, 0].max
    end

    def prev_page
      self.page = @page - 1
      self
    end

    def next_page
      self.page = @page + 1
      self
    end

    def on_first_page?
      @page.zero?
    end

    def on_last_page?
      @page >= @total_pages - 1
    end

    # Slicing helper — returns [start_index, length] for Array#slice
    def slice_bounds(total_items)
      return [0, 0] if @per_page <= 0 || total_items <= 0

      start = @page * @per_page
      start = [start, total_items].min
      length = [@per_page, total_items - start].min
      [start, length]
    end

    # Calculate and update total_pages from item count and per_page.
    def total_pages_from_items(total_items)
      return if @per_page <= 0

      @total_pages = [(total_items.to_f / @per_page).ceil, 1].max
      @page = @page.clamp(0, @total_pages - 1)
    end

    # Elm protocol

    def handle(msg)
      case msg
      when Chamomile::KeyEvent
        if KeyBinding.key_matches?(msg, @key_map, :prev_page)
          prev_page
        elsif KeyBinding.key_matches?(msg, @key_map, :next_page)
          next_page
        end
      end

      nil
    end

    alias update handle

    def view
      case @type
      when TYPE_ARABIC
        "#{@page + 1}/#{@total_pages}"
      else
        (0...@total_pages).map { |i| i == @page ? @active_dot : @inactive_dot }.join(" ")
      end
    end
  end
end
