# frozen_string_literal: true

module Petals
  # Auto-generated keybinding help view with short and full display modes.
  class Help
    ELLIPSIS = "\u2026"

    attr_accessor :width, :short_separator, :full_separator, :ellipsis, :show_all

    def initialize(width: 80)
      @width = width
      @short_separator = " \u2022 "
      @full_separator = "    "
      @ellipsis = ELLIPSIS
      @show_all = false
    end

    def short_help_view(bindings)
      filtered = enabled_bindings(bindings)
      return "" if filtered.empty?

      parts = filtered.map { |b| "#{b[:key]} #{b[:desc]}" }
      result = parts.join(@short_separator)

      return result if @width <= 0 || result.length <= @width

      truncate(parts)
    end

    def full_help_view(groups)
      filtered_groups = groups.map { |g| enabled_bindings(g) }.reject(&:empty?)
      return "" if filtered_groups.empty?

      max_rows = filtered_groups.map(&:length).max
      lines = Array.new(max_rows, "")

      max_rows.times do |row|
        cols = filtered_groups.map do |group|
          if row < group.length
            b = group[row]
            "#{b[:key]}  #{b[:desc]}"
          else
            ""
          end
        end
        lines[row] = cols.join(@full_separator).rstrip
      end

      lines.join("\n")
    end

    def view(bindings_or_groups)
      if @show_all
        groups = bindings_or_groups.first.is_a?(Array) ? bindings_or_groups : [bindings_or_groups]
        full_help_view(groups)
      else
        flat = bindings_or_groups.first.is_a?(Array) ? bindings_or_groups.flatten : bindings_or_groups
        short_help_view(flat)
      end
    end

    def handle(_msg)
      nil
    end

    alias update handle

    private

    def enabled_bindings(bindings)
      bindings.select { |b| b.fetch(:enabled, true) }
    end

    def truncate(parts)
      result = ""
      parts.each_with_index do |part, i|
        candidate = if i.zero?
                      part
                    else
                      "#{result}#{@short_separator}#{part}"
                    end
        if candidate.length + @ellipsis.length + @short_separator.length > @width && i.positive?
          return "#{result}#{@short_separator}#{@ellipsis}"
        end

        result = candidate
      end
      result
    end
  end
end
