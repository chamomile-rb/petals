# frozen_string_literal: true

module Chamomile
  module Leaves
    # Utilities for matching KeyMsg against normalized key maps.
    module KeyBinding
      # Normalize a key map so mod arrays are sorted and frozen.
      # Call once at definition time to avoid per-keystroke allocations.
      #
      #   normalize({ action => [[key, mods], ...] })
      #   # => { action => [[key, sorted_frozen_mods], ...] }
      def self.normalize(key_map)
        key_map.transform_values do |bindings|
          bindings.map { |key, mods| [key, (mods || []).sort.freeze] }.freeze
        end.freeze
      end

      # Check if a KeyMsg matches any binding for a named action.
      # Expects a normalized key map (from .normalize) for best performance.
      def self.key_matches?(msg, key_map, action)
        return false unless msg.is_a?(Chamomile::KeyMsg)

        bindings = key_map[action]
        return false unless bindings

        sorted_mod = msg.mod.sort
        bindings.any? do |key, mods|
          msg.key == key && sorted_mod == (mods || [])
        end
      end
    end
  end
end
