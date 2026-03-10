# frozen_string_literal: true

RSpec.describe Petals::CommandPalette do
  let(:items) do
    [
      { label: "Run migrations", action: :run_migrate, key: "db:migrate" },
      { label: "Start server", action: :server_start, key: "server" },
      { label: "Run tests", action: :run_tests, key: "test" },
    ]
  end

  subject(:palette) { described_class.new(items: items) }

  def key_msg(key)
    Chamomile::KeyMsg.new(key: key, mod: [])
  end

  describe "visibility" do
    it "starts hidden" do
      expect(palette).not_to be_visible
    end

    it "can be shown and hidden" do
      palette.show
      expect(palette).to be_visible
      palette.hide
      expect(palette).not_to be_visible
    end

    it "renders empty string when hidden" do
      expect(palette.render(width: 80, height: 24)).to eq("")
    end
  end

  describe "#handle_key" do
    before { palette.show }

    it "returns nil when hidden" do
      palette.hide
      expect(palette.handle_key(key_msg(:enter))).to be_nil
    end

    it "hides on escape" do
      palette.handle_key(key_msg(:escape))
      expect(palette).not_to be_visible
    end

    it "selects item on enter" do
      result = palette.handle_key(key_msg(:enter))
      expect(result).not_to be_nil
      expect(result.action).to eq(:run_migrate)
      expect(palette).not_to be_visible
    end

    it "navigates down with j" do
      palette.handle_key(key_msg("j"))
      result = palette.handle_key(key_msg(:enter))
      expect(result.action).to eq(:server_start)
    end

    it "navigates up with k" do
      palette.handle_key(key_msg("j"))
      palette.handle_key(key_msg("k"))
      result = palette.handle_key(key_msg(:enter))
      expect(result.action).to eq(:run_migrate)
    end

    it "navigates with arrow keys" do
      palette.handle_key(key_msg(:down))
      palette.handle_key(key_msg(:down))
      result = palette.handle_key(key_msg(:enter))
      expect(result.action).to eq(:run_tests)
    end

    it "does not go below last item" do
      10.times { palette.handle_key(key_msg(:down)) }
      result = palette.handle_key(key_msg(:enter))
      expect(result.action).to eq(:run_tests)
    end

    it "does not go above first item" do
      palette.handle_key(key_msg(:up))
      result = palette.handle_key(key_msg(:enter))
      expect(result.action).to eq(:run_migrate)
    end
  end

  describe "filtering" do
    before { palette.show }

    it "filters items by typing" do
      palette.handle_key(key_msg("s"))
      palette.handle_key(key_msg("e"))
      palette.handle_key(key_msg("r"))
      items = palette.filtered_items
      expect(items.size).to eq(1)
      expect(items.first.action).to eq(:server_start)
    end

    it "filters by key field" do
      palette.handle_key(key_msg("d"))
      palette.handle_key(key_msg("b"))
      items = palette.filtered_items
      expect(items.size).to eq(1)
      expect(items.first.action).to eq(:run_migrate)
    end

    it "resets cursor on filter change" do
      palette.handle_key(key_msg(:down))
      expect(palette.cursor).to eq(1)
      palette.handle_key(key_msg("t"))
      expect(palette.cursor).to eq(0)
    end

    it "supports backspace" do
      palette.handle_key(key_msg("x"))
      expect(palette.filtered_items).to be_empty
      palette.handle_key(key_msg(:backspace))
      expect(palette.filtered_items.size).to eq(3)
    end

    it "handles navigation with empty filter results" do
      palette.handle_key(key_msg("z"))
      palette.handle_key(key_msg("z"))
      palette.handle_key(key_msg("z"))
      expect(palette.filtered_items).to be_empty
      palette.handle_key(key_msg(:down))
      expect(palette.cursor).to eq(0)
      palette.handle_key(key_msg(:up))
      expect(palette.cursor).to eq(0)
    end

    it "returns nil on enter with empty filter results" do
      palette.handle_key(key_msg("z"))
      palette.handle_key(key_msg("z"))
      palette.handle_key(key_msg("z"))
      result = palette.handle_key(key_msg(:enter))
      expect(result).to be_nil
    end
  end

  describe "#render" do
    before { palette.show }

    it "renders a box with items" do
      output = palette.render(width: 80, height: 24)
      expect(output).to include("Run migrations")
      expect(output).to include("Start server")
      expect(output).to include("Run tests")
    end

    it "highlights the selected item with reverse video" do
      output = palette.render(width: 80, height: 24)
      expect(output).to include("\e[7m")
    end

    it "shows navigation help" do
      output = palette.render(width: 80, height: 24)
      expect(output).to include("navigate")
      expect(output).to include("Esc cancel")
    end
  end
end
