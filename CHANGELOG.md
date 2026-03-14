# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **SLICE-001 — YouTube Music Provider Support:** InnerTube-based YouTube Music search,
  streaming, and song metadata accessible via a local Rust proxy. No CDN URLs are exposed
  directly to the QML MediaPlayer.
- **SLICE-001:** Provider selector in Settings page (OptionSelector) — choice persisted to
  SQLite via new `settings` table.
- **SLICE-001:** Source badges ("YouTube" / "NetEase") shown in Search results, Now Playing,
  Album view, and Artist view.
- **SLICE-001:** `settings` table in SQLite with `getSetting` / `setSetting` helper functions.

[Unreleased]: https://github.com/johangm90/cloudmusic-qml/compare/v1.9.0...HEAD
