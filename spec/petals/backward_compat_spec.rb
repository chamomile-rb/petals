# frozen_string_literal: true

require "spec_helper"

RSpec.describe "backward compatibility" do
  describe "TextInput#update still works" do
    it "update is an alias for handle" do
      input = Petals::TextInput.new
      input.focus
      msg = Chamomile::KeyEvent.new(key: "a", mod: [])
      input.update(msg)
      expect(input.value).to eq("a")
    end
  end

  describe "Viewport setters" do
    it "set_width still works" do
      vp = Petals::Viewport.new(width: 80, height: 24)
      vp.set_width(100)
      expect(vp.width).to eq(100)
    end

    it "set_height still works" do
      vp = Petals::Viewport.new(width: 80, height: 24)
      vp.set_height(30)
      expect(vp.height).to eq(30)
    end

    it "set_content still works" do
      vp = Petals::Viewport.new(width: 80, height: 24)
      vp.set_content("hello\nworld")
      expect(vp.content).to eq("hello\nworld")
    end
  end

  describe "Viewport#update still works" do
    it "update is an alias for handle" do
      vp = Petals::Viewport.new(width: 80, height: 3)
      vp.set_content((1..50).map { |i| "line #{i}" }.join("\n"))
      msg = Chamomile::KeyEvent.new(key: "j", mod: [])
      vp.update(msg)
      expect(vp.y_offset).to eq(1)
    end
  end

  describe "Table::Column.new still works" do
    it "creates columns with the old struct form" do
      columns = [
        Petals::Table::Column.new(title: "Name", width: 20),
        Petals::Table::Column.new(title: "Size", width: 10),
      ]
      table = Petals::Table.new(columns: columns, rows: [["foo", "10"]])
      expect(table.columns.length).to eq(2)
    end
  end

  describe "Table#update still works" do
    it "update is an alias for handle" do
      table = Petals::Table.new(
        columns: [Petals::Table::Column.new(title: "Name", width: 20)],
        rows: [["a"], ["b"], ["c"]],
      )
      table.focus
      msg = Chamomile::KeyEvent.new(key: "j", mod: [])
      table.update(msg)
      expect(table.cursor).to eq(1)
    end
  end
end
