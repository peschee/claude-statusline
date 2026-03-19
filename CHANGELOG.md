# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-03-19

### Added

- Make `CLAUDE_DIR` configurable via environment variable in install script
- `CHANGELOG.md` following Keep a Changelog format

## [1.2.0] - 2026-03-19

### Added

- Asylum sandbox indicator to statusline

## [1.1.2] - 2026-03-18

### Fixed

- `grep` failing with `set -e` when no insertions/deletions found

## [1.1.1] - 2026-03-18

### Fixed

- Use `~/.claude/` instead of absolute path in `settings.json`

## [1.1.0] - 2026-03-18

### Added

- Fail-fast shell options (`set -eu`) to both scripts
- CI workflow to run shellcheck on push and PRs
- Makefile with shellcheck linting
- Reference to official Claude Code statusline docs

### Changed

- Update `actions/checkout` to v6

### Fixed

- Shellcheck lint errors

## [1.0.0] - 2026-03-18

### Added

- Custom Claude Code statusline displaying model, git branch, diff stats, last commit, context usage, session duration, and cost
- Install script with automatic `settings.json` patching

[Unreleased]: https://github.com/peschee/claude-statusline/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/peschee/claude-statusline/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/peschee/claude-statusline/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/peschee/claude-statusline/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/peschee/claude-statusline/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/peschee/claude-statusline/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/peschee/claude-statusline/releases/tag/v1.0.0
