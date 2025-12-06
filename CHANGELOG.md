# Changelog

All notable changes to this project will be documented in this file.

## [1.0.8]

- Updated dependencies - `jetleaf_lang`, `jetleaf_env`, `jetleaf_convert`, `jetleaf_logging`, `jetleaf_utils` and `jetleaf_pod`

## [1.0.7]

- Updated dependencies - `jetleaf_env`

## [1.0.6]

- Updated dependencies
- Added `Availability` api
- Added `Diagnostics` api
- Included `StartupEvent` events

## [1.0.5]

- Updated dependencies

## [1.0.4]

- Updated dependencies

## [1.0.3]

- Updated dependencies

## [1.0.2]

- Updated dependencies

## [1.0.1+1]

Patch release: dependency alignment and small improvements.

### Changed

- Updated package dependencies and alignment with other JetLeaf modules.

## [1.0.1]

Patch release: dependency alignment and small improvements.

### Fixed / Changed

- Updated package dependencies and alignment with other JetLeaf modules.
- Minor performance improvements in scanning and configuration processing.

## [1.0.0+1]

- Updated dependencies for `jetleaf_lang`.
- Added `disable` parameter to `ImportClass` to allow conditional import suppression.
- Rearranged `ConfigurationClassPostProcessor`, `ConfigurationClass`, and other classes that handle scanning and configuration processing to be more efficient.
- Conditional scanning is now more efficient than before.

## [1.0.0]

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