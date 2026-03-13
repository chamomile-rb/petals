# Petals — DEPRECATED

> **This gem is deprecated.** All components are now part of [Chamomile](https://github.com/chamomile-rb/chamomile) v1.0+.

## Migration

1. Replace `gem "petals"` with `gem "chamomile", "~> 1.0"` in your Gemfile
2. Replace `require "petals"` with `require "chamomile"`
3. Replace `Petals::` with `Chamomile::` throughout your code

All component APIs are unchanged — just the namespace moved.

## What happened?

Chamomile v1.0 consolidated the ecosystem from three gems (chamomile, petals, flourish) into a single gem. One `gem install chamomile`, one `require "chamomile"`, one `Chamomile::` namespace.

This v0.3.0 release is a backward-compatibility shim that pulls in `chamomile` and aliases `Petals = Chamomile`. It will print a deprecation warning on require. Use it as a bridge while you update your code.

## License

[MIT](LICENSE)
