# frozen_string_literal: true

RSpec.describe Petals::RenderCache do
  let(:test_class) do
    Class.new do
      include Petals::RenderCache

      attr_accessor :data

      def initialize(data)
        @data = data
      end

      def render(width:, height:)
        cached_render(width: width, height: height, cache_key: @data.hash) do
          "rendered: #{@data} (#{width}x#{height})"
        end
      end
    end
  end

  it "caches render results for same inputs" do
    obj = test_class.new("hello")
    result1 = obj.render(width: 80, height: 24)
    result2 = obj.render(width: 80, height: 24)
    expect(result1).to eq(result2)
    expect(result1).to eq("rendered: hello (80x24)")
  end

  it "invalidates cache when data changes" do
    obj = test_class.new("hello")
    result1 = obj.render(width: 80, height: 24)
    obj.data = "world"
    result2 = obj.render(width: 80, height: 24)
    expect(result1).not_to eq(result2)
    expect(result2).to eq("rendered: world (80x24)")
  end

  it "invalidates cache when dimensions change" do
    obj = test_class.new("hello")
    result1 = obj.render(width: 80, height: 24)
    result2 = obj.render(width: 120, height: 40)
    expect(result1).not_to eq(result2)
  end
end
