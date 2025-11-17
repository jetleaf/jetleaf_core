# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2025-11-17

Patch release: dependency alignment and small improvements.

### Fixed / Changed

- Updated package dependencies and alignment with other JetLeaf modules.
- Minor performance improvements in scanning and configuration processing.

## [1.0.0+1] - 2025-11-17

- Updated dependencies for `jetleaf_lang`.
- Added `disable` parameter to `ImportClass` to allow conditional import suppression.
- Rearranged `ConfigurationClassPostProcessor`, `ConfigurationClass`, and other classes that handle scanning and configuration processing to be more efficient.
- Conditional scanning is now more efficient than before.

## [1.0.0] - 2025-11-17

Initial release.

### Added

- Core runtime and lifecycle primitives used by JetLeaf (context, application lifecycle, core helpers).

### Notes

- This package implements the core runtime foundations for JetLeaf. Future breaking changes will include migration notes and guidance.

### Links

- Homepage: https://jetleaf.hapnium.com
- Documentation: https://jetleaf.hapnium.com/docs/core
- Repository: https://github.com/jetleaf/jetleaf_core
- Issues: https://github.com/jetleaf/jetleaf_core/issues

Contributors: Hapnium & JetLeaf contributors