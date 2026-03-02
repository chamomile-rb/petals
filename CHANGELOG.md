# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Updated all examples to use `start` instead of `init` following the chamomile API rename

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
