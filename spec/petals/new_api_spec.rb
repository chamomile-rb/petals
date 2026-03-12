# frozen_string_literal: true

require "spec_helper"

RSpec.describe "new API" do
  describe "TextInput#handle" do
    it "works identically to old #update" do
      input = Petals::TextInput.new
      input.focus
      msg = Chamomile::KeyEvent.new(key: "a", mod: [])
      input.handle(msg)
      expect(input.value).to eq("a")
    end
  end

  describe "Viewport setters" do
    it "content= works" do
      vp = Petals::Viewport.new(width: 80, height: 24)
      vp.content = "hello\nworld"
      expect(vp.content).to eq("hello\nworld")
    end

    it "width= works" do
      vp = Petals::Viewport.new(width: 80, height: 24)
      vp.width = 120
      expect(vp.width).to eq(120)
    end

    it "height= works" do
      vp = Petals::Viewport.new(width: 80, height: 24)
      vp.height = 40
      expect(vp.height).to eq(40)
    end
  end

  describe "Viewport#handle" do
    it "works for key events" do
      vp = Petals::Viewport.new(width: 80, height: 24)
      vp.content = (1..50).map { |i| "line #{i}" }.join("\n")
      msg = Chamomile::KeyEvent.new(key: "j", mod: [])
      vp.handle(msg)
      expect(vp.y_offset).to eq(1)
    end
  end

  describe "Table block DSL" do
    it "adds columns via block" do
      table = Petals::Table.new(rows: [["a", "b"]]) do |t|
        t.column "Name", width: 20
        t.column "Size", width: 10
      end
      expect(table.columns.length).to eq(2)
      expect(table.columns[0].title).to eq("Name")
      expect(table.columns[1].title).to eq("Size")
    end

    it "column count and titles are correct" do
      table = Petals::Table.new(rows: []) do |t|
        t.column "ID", width: 8
        t.column "Name", width: 20
        t.column "Created", width: 16
      end
      expect(table.columns.map(&:title)).to eq(%w[ID Name Created])
    end

    it "renders correctly with block DSL" do
      table = Petals::Table.new(rows: [["1", "foo"]]) do |t|
        t.column "ID", width: 5
        t.column "Name", width: 10
      end
      table.focus
      output = table.view
      expect(output).to include("ID")
      expect(output).to include("Name")
      expect(output).to include("foo")
    end
  end

  describe "Table hash column form" do
    it "accepts hash column definitions" do
      table = Petals::Table.new(
        columns: [{ title: "Name", width: 20 }, { title: "Size", width: 10 }],
        rows: [["a", "b"]],
      )
      expect(table.columns.length).to eq(2)
      expect(table.columns[0].title).to eq("Name")
    end
  end

  describe "Table#handle" do
    it "works for key events" do
      table = Petals::Table.new(rows: [["a"], ["b"], ["c"]]) do |t|
        t.column "Name", width: 20
      end
      table.focus
      msg = Chamomile::KeyEvent.new(key: "j", mod: [])
      table.handle(msg)
      expect(table.cursor).to eq(1)
    end
  end
end
