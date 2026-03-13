# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-03-12

### Changed

- **DEPRECATED**: This gem is now a shim that depends on `chamomile ~> 1.0`. All components have been merged into the main Chamomile gem. Replace `gem "petals"` with `gem "chamomile"` and change `Petals::` to `Chamomile::`.

## [Unreleased]

### Added

- `Table` block DSL: `Table.new(rows: rows) { |t| t.column "Name", width: 20 }`
- `Table` hash column form: `Table.new(columns: [{ title: "Name", width: 20 }], rows: rows)`
- `Viewport#width=`, `Viewport#height=`, `Viewport#content=` — Ruby-style setters

### Changed

- All components: `update(msg)` renamed to `handle(msg)` (`update` kept as backward-compat alias)
- Internal type references updated to use `KeyEvent`/`MouseEvent`/`PasteEvent` names
- README updated: all examples use `handle(msg)`, `=` setters, and Table block DSL

### Deprecated

- `update(msg)` on all components — use `handle(msg)` instead (alias still works)
- `Viewport#set_width`, `Viewport#set_height`, `Viewport#set_content` — use `=` setters instead (old methods still work)

## [0.1.0] - 2026-02-27

### Added

- KeyBinding: modifier-order-insensitive key matching for composable key maps
- Spinner: 12 predefined animation types (LINE, DOT, MINI_DOT, etc.) with ID/tag tick routing
- TextInput: single-line input with cursor movement, word/line editing, echo modes (normal/password/none), horizontal scrolling, char limits, validation, paste support
- Stopwatch: count-up timer with start/stop/toggle/reset, ID/tag tick routing
- Timer: countdown timer with configurable timeout, TimerTimeoutMsg notification on completion
- Paginator: dot and arabic display modes, key-bound navigation (arrows, h/l, page up/down), slice_bounds helper for array pagination
- Interactive examples: spinner_demo, text_input_demo, combined_demo, timer_stopwatch_demo
- Headless smoke test covering all components
