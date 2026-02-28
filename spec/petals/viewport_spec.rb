# frozen_string_literal: true

require "spec_helper"

RSpec.describe Petals::Viewport do
  def key(k, mod: []) = Chamomile::KeyMsg.new(key: k, mod: mod)

  def mouse(button, x: 0, y: 0)
    Chamomile::MouseMsg.new(button: button, action: :press, x: x, y: y, mod: [])
  end

  def make_content(n)
    n.times.map { |i| "line #{i}" }.join("\n")
  end

  subject(:vp) { described_class.new(width: 80, height: 5) }

  describe "initialization" do
    it "defaults to 80x24" do
      v = described_class.new
      expect(v.width).to eq(80)
      expect(v.height).to eq(24)
    end

    it "starts at y_offset 0" do
      expect(vp.y_offset).to eq(0)
    end

    it "starts with no content" do
      expect(vp.total_line_count).to eq(0)
    end

    it "enables mouse wheel by default" do
      expect(vp.mouse_wheel_enabled).to be true
    end

    it "defaults mouse_wheel_delta to 3" do
      expect(vp.mouse_wheel_delta).to eq(3)
    end
  end

  describe "#set_content / #content" do
    it "sets and retrieves content" do
      vp.set_content("hello\nworld")
      expect(vp.content).to eq("hello\nworld")
    end

    it "splits content into lines" do
      vp.set_content("a\nb\nc")
      expect(vp.total_line_count).to eq(3)
    end

    it "preserves trailing newline" do
      vp.set_content("a\nb\n")
      expect(vp.total_line_count).to eq(3)
    end

    it "returns self" do
      expect(vp.set_content("hi")).to equal(vp)
    end

    it "clamps offset when content shrinks" do
      vp.set_content(make_content(20))
      vp.y_offset = 15
      vp.set_content(make_content(3))
      expect(vp.y_offset).to eq(0)
    end
  end

  describe "#scroll_up / #scroll_down" do
    before { vp.set_content(make_content(20)) }

    it "scrolls down by 1" do
      vp.scroll_down
      expect(vp.y_offset).to eq(1)
    end

    it "scrolls up by 1" do
      vp.y_offset = 5
      vp.scroll_up
      expect(vp.y_offset).to eq(4)
    end

    it "scrolls down by n" do
      vp.scroll_down(3)
      expect(vp.y_offset).to eq(3)
    end

    it "scrolls up by n" do
      vp.y_offset = 10
      vp.scroll_up(3)
      expect(vp.y_offset).to eq(7)
    end

    it "clamps at bottom" do
      vp.scroll_down(100)
      expect(vp.y_offset).to eq(15) # 20 - 5
    end

    it "clamps at top" do
      vp.scroll_up(100)
      expect(vp.y_offset).to eq(0)
    end
  end

  describe "#page_up / #page_down" do
    before { vp.set_content(make_content(20)) }

    it "scrolls down by height" do
      vp.page_down
      expect(vp.y_offset).to eq(5)
    end

    it "scrolls up by height" do
      vp.y_offset = 10
      vp.page_up
      expect(vp.y_offset).to eq(5)
    end
  end

  describe "#half_page_up / #half_page_down" do
    before { vp.set_content(make_content(20)) }

    it "scrolls down by half height" do
      vp.half_page_down
      expect(vp.y_offset).to eq(2) # 5/2 = 2
    end

    it "scrolls up by half height" do
      vp.y_offset = 10
      vp.half_page_up
      expect(vp.y_offset).to eq(8)
    end
  end

  describe "#goto_top / #goto_bottom" do
    before do
      vp.set_content(make_content(20))
      vp.y_offset = 10
    end

    it "goes to top" do
      vp.goto_top
      expect(vp.y_offset).to eq(0)
    end

    it "goes to bottom" do
      vp.goto_bottom
      expect(vp.y_offset).to eq(15)
    end
  end

  describe "#at_top? / #at_bottom?" do
    before { vp.set_content(make_content(20)) }

    it "is at top initially" do
      expect(vp.at_top?).to be true
      expect(vp.at_bottom?).to be false
    end

    it "is at bottom when scrolled to end" do
      vp.goto_bottom
      expect(vp.at_top?).to be false
      expect(vp.at_bottom?).to be true
    end

    it "is both for content shorter than height" do
      vp.set_content("short")
      expect(vp.at_top?).to be true
      expect(vp.at_bottom?).to be true
    end
  end

  describe "#scroll_percent" do
    before { vp.set_content(make_content(20)) }

    it "is 0.0 at top" do
      expect(vp.scroll_percent).to eq(0.0)
    end

    it "is 1.0 at bottom" do
      vp.goto_bottom
      expect(vp.scroll_percent).to eq(1.0)
    end

    it "is 0.5 at middle" do
      vp.y_offset = 7
      expect(vp.scroll_percent).to be_within(0.1).of(0.47)
    end

    it "is 1.0 when content fits in viewport (all content visible)" do
      vp.set_content("short")
      expect(vp.scroll_percent).to eq(1.0)
    end
  end

  describe "#visible_line_count" do
    it "returns height when content exceeds height" do
      vp.set_content(make_content(20))
      expect(vp.visible_line_count).to eq(5)
    end

    it "returns line count when content is shorter" do
      vp.set_content("a\nb")
      expect(vp.visible_line_count).to eq(2)
    end

    it "returns 0 for empty content" do
      expect(vp.visible_line_count).to eq(0)
    end
  end

  describe "#view" do
    it "shows visible slice of content" do
      vp.set_content(make_content(20))
      lines = vp.view.split("\n")
      expect(lines[0]).to eq("line 0")
      expect(lines[4]).to eq("line 4")
    end

    it "shows correct slice after scrolling" do
      vp.set_content(make_content(20))
      vp.y_offset = 5
      lines = vp.view.split("\n")
      expect(lines[0]).to eq("line 5")
      expect(lines[4]).to eq("line 9")
    end

    it "pads with empty lines when content is short" do
      vp.set_content("only one")
      lines = vp.view.split("\n", -1)
      expect(lines.length).to eq(5)
      expect(lines[0]).to eq("only one")
      expect(lines[1]).to eq("")
    end

    it "returns empty lines for no content" do
      lines = vp.view.split("\n", -1)
      expect(lines.length).to eq(5)
      expect(lines.all?(&:empty?)).to be true
    end
  end

  describe "#update with KeyMsg" do
    before { vp.set_content(make_content(20)) }

    it "scrolls down on j" do
      vp.update(key("j"))
      expect(vp.y_offset).to eq(1)
    end

    it "scrolls up on k" do
      vp.y_offset = 5
      vp.update(key("k"))
      expect(vp.y_offset).to eq(4)
    end

    it "scrolls down on down arrow" do
      vp.update(key(:down))
      expect(vp.y_offset).to eq(1)
    end

    it "scrolls up on up arrow" do
      vp.y_offset = 5
      vp.update(key(:up))
      expect(vp.y_offset).to eq(4)
    end

    it "pages down on f" do
      vp.update(key("f"))
      expect(vp.y_offset).to eq(5)
    end

    it "pages up on b" do
      vp.y_offset = 10
      vp.update(key("b"))
      expect(vp.y_offset).to eq(5)
    end

    it "pages down on space" do
      vp.update(key(" "))
      expect(vp.y_offset).to eq(5)
    end

    it "half-pages down on ctrl+d" do
      vp.update(key("d", mod: [:ctrl]))
      expect(vp.y_offset).to eq(2)
    end

    it "half-pages up on ctrl+u" do
      vp.y_offset = 10
      vp.update(key("u", mod: [:ctrl]))
      expect(vp.y_offset).to eq(8)
    end

    it "goes to top on g" do
      vp.y_offset = 10
      vp.update(key("g"))
      expect(vp.y_offset).to eq(0)
    end

    it "goes to bottom on G" do
      vp.update(key("G", mod: [:shift]))
      expect(vp.y_offset).to eq(15)
    end

    it "returns nil" do
      expect(vp.update(key("j"))).to be_nil
    end

    it "ignores unknown keys" do
      vp.update(key("z"))
      expect(vp.y_offset).to eq(0)
    end
  end

  describe "#update with MouseMsg" do
    before { vp.set_content(make_content(20)) }

    it "scrolls up on wheel_up" do
      vp.y_offset = 10
      vp.update(mouse(:wheel_up))
      expect(vp.y_offset).to eq(7)
    end

    it "scrolls down on wheel_down" do
      vp.update(mouse(:wheel_down))
      expect(vp.y_offset).to eq(3)
    end

    it "respects mouse_wheel_delta" do
      vp.mouse_wheel_delta = 1
      vp.update(mouse(:wheel_down))
      expect(vp.y_offset).to eq(1)
    end

    it "ignores mouse when disabled" do
      vp.mouse_wheel_enabled = false
      vp.update(mouse(:wheel_down))
      expect(vp.y_offset).to eq(0)
    end
  end

  describe "horizontal scrolling" do
    let(:narrow_vp) { described_class.new(width: 20, height: 5) }

    before do
      narrow_vp.set_content("short\nthis is a much longer line that extends beyond the width\nend")
    end

    it "starts at x_offset 0" do
      expect(narrow_vp.x_offset).to eq(0)
    end

    it "scrolls right" do
      narrow_vp.scroll_right(5)
      expect(narrow_vp.x_offset).to eq(5)
    end

    it "scrolls left" do
      narrow_vp.scroll_right(10)
      narrow_vp.scroll_left(3)
      expect(narrow_vp.x_offset).to eq(7)
    end

    it "clamps x_offset at 0" do
      narrow_vp.scroll_left(10)
      expect(narrow_vp.x_offset).to eq(0)
    end

    it "truncates lines in view" do
      narrow_vp.instance_variable_set(:@width, 10)
      narrow_vp.scroll_right(5)
      lines = narrow_vp.view.split("\n")
      expect(lines[0]).to eq("") # "short" is only 5 chars, offset 5 = empty
      expect(lines[1]).to start_with("is a ")
    end

    it "x_offset= sets with clamping" do
      narrow_vp.x_offset = 5
      expect(narrow_vp.x_offset).to eq(5)
      narrow_vp.x_offset = -5
      expect(narrow_vp.x_offset).to eq(0)
    end

    it "responds to left/right keys" do
      narrow_vp.update(key(:right))
      expect(narrow_vp.x_offset).to eq(1)
      narrow_vp.update(key(:left))
      expect(narrow_vp.x_offset).to eq(0)
    end

    it "responds to alt+h/alt+l" do
      narrow_vp.update(key("l", mod: [:alt]))
      expect(narrow_vp.x_offset).to eq(1)
      narrow_vp.update(key("h", mod: [:alt]))
      expect(narrow_vp.x_offset).to eq(0)
    end

    it "max_horizontal_scroll is longest line minus width" do
      narrow_vp.instance_variable_set(:@width, 10)
      long_line = "this is a much longer line that extends beyond the width"
      expect(narrow_vp.max_horizontal_scroll).to eq(long_line.length - 10)
    end
  end

  describe "soft wrap" do
    before do
      vp.soft_wrap = true
      vp.instance_variable_set(:@width, 10)
    end

    it "wraps lines at width boundary" do
      vp.set_content("1234567890abcde")
      expect(vp.total_line_count).to eq(2) # "1234567890" + "abcde"
    end

    it "view shows wrapped content" do
      vp.set_content("1234567890abcde")
      lines = vp.view.split("\n", -1)
      expect(lines[0]).to eq("1234567890")
      expect(lines[1]).to eq("abcde")
    end

    it "ignores horizontal scroll when soft_wrap is on" do
      vp.set_content("1234567890abcde")
      vp.scroll_right(5)
      expect(vp.x_offset).to eq(0)
    end

    it "x_offset= is no-op when soft_wrap" do
      vp.set_content("1234567890abcde")
      vp.x_offset = 5
      expect(vp.x_offset).to eq(0)
    end

    it "max_scroll uses wrapped line count" do
      content = 10.times.map { "1234567890abcde" }.join("\n") # 10 lines, each wraps to 2
      vp.set_content(content)
      vp.instance_variable_set(:@height, 5)
      # 20 wrapped lines - 5 height = 15
      expect(vp.send(:max_scroll)).to eq(15)
    end

    it "scrolling works with wrapped content" do
      content = 10.times.map { "1234567890abcde" }.join("\n")
      vp.set_content(content)
      vp.instance_variable_set(:@height, 5)
      vp.scroll_down(2)
      expect(vp.y_offset).to eq(2)
    end

    it "handles empty lines" do
      vp.set_content("hello\n\nworld")
      expect(vp.total_line_count).to eq(3) # "hello", "", "world"
    end
  end

  describe "#ensure_visible" do
    before { vp.set_content(make_content(20)) }

    it "scrolls down to make line visible" do
      vp.ensure_visible(10)
      expect(vp.y_offset).to eq(6) # 10 - 5 + 1
    end

    it "scrolls up to make line visible" do
      vp.y_offset = 10
      vp.ensure_visible(3)
      expect(vp.y_offset).to eq(3)
    end

    it "does nothing when line is already visible" do
      vp.y_offset = 5
      vp.ensure_visible(7)
      expect(vp.y_offset).to eq(5)
    end

    it "returns self" do
      expect(vp.ensure_visible(0)).to equal(vp)
    end
  end

  describe "dimension setters" do
    before { vp.set_content(make_content(20)) }

    it "set_width updates width" do
      vp.set_width(40)
      expect(vp.width).to eq(40)
    end

    it "set_height updates height and clamps offset" do
      vp.y_offset = 15
      vp.set_height(10)
      expect(vp.height).to eq(10)
      expect(vp.y_offset).to eq(10) # max_scroll = 20-10 = 10
    end

    it "set_height with larger height clamps offset" do
      vp.y_offset = 15
      vp.set_height(20)
      expect(vp.y_offset).to eq(0) # max_scroll = 0
    end
  end

  describe "edge cases" do
    it "handles empty content" do
      expect(vp.total_line_count).to eq(0)
      expect(vp.view.split("\n", -1).length).to eq(5)
    end

    it "handles single line" do
      vp.set_content("hello")
      expect(vp.at_top?).to be true
      expect(vp.at_bottom?).to be true
      expect(vp.view).to include("hello")
    end

    it "handles content exactly equal to height" do
      vp.set_content(make_content(5))
      expect(vp.at_top?).to be true
      expect(vp.at_bottom?).to be true
      vp.scroll_down
      expect(vp.y_offset).to eq(0)
    end

    it "handles y_offset= with negative" do
      vp.set_content(make_content(20))
      vp.y_offset = -5
      expect(vp.y_offset).to eq(0)
    end
  end
end
