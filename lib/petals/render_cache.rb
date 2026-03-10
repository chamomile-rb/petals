# frozen_string_literal: true

module Petals
  # Mixin for render result caching keyed on content hash.
  # Include in components whose render output depends only on their data and dimensions.
  module RenderCache
    def cached_render(width:, height:, cache_key:)
      key = [width, height, cache_key]
      return @render_cache if @render_cache_key == key

      @render_cache_key = key
      @render_cache = yield
    end
  end
end
