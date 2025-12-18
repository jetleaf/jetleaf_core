# Changelog

All notable changes to this project will be documented in this file.  
This project follows a simple, human-readable changelog format inspired by
[Keep a Changelog](https://keepachangelog.com/) and adheres to semantic versioning.

---

## [1.1.1]

### Changed
- Updated dependencies:
  - `jetleaf_lang`
  - `jetleaf_env`
  - `jetleaf_convert`
  - `jetleaf_logging`
  - `jetleaf_utils`
  - `jetleaf_pod`

---

## [1.1.0]

### Changed
- Updated dependencies:
  - `jetleaf_lang`
  - `jetleaf_env`
  - `jetleaf_convert`
  - `jetleaf_logging`
  - `jetleaf_utils`
  - `jetleaf_pod`

### Removed
- `MethodArgument` APIs, now fully replaced by `ExecutableArgument`.
- `Version` and `VersionRange`, as these are now provided by `jetleaf_lang`.

---

## [1.0.9]

### Changed
- Updated dependencies:
  - `jetleaf_lang`
  - `jetleaf_env`
  - `jetleaf_convert`
  - `jetleaf_logging`
  - `jetleaf_utils`
  - `jetleaf_pod`

---

## [1.0.8]

### Changed
- Updated dependencies:
  - `jetleaf_lang`
  - `jetleaf_env`
  - `jetleaf_convert`
  - `jetleaf_logging`
  - `jetleaf_utils`
  - `jetleaf_pod`

---

## [1.0.7]

### Changed
- Updated dependency: `jetleaf_env`

---

## [1.0.6]

### Added
- `Availability` API.
- `Diagnostics` API.
- `StartupEvent` lifecycle events.

### Changed
- Updated dependencies.

---

## [1.0.5]

### Changed
- Updated dependencies.

---

## [1.0.4]

### Changed
- Updated dependencies.

---

## [1.0.3]

### Changed
- Updated dependencies.

---

## [1.0.2]

### Changed
- Updated dependencies.

---

## [1.0.1+1]

Patch release focused on dependency alignment and small improvements.

### Changed
- Updated package dependencies and alignment with other JetLeaf modules.

---

## [1.0.1]

Patch release focused on dependency alignment and performance improvements.

### Changed
- Updated package dependencies and alignment with other JetLeaf modules.
- Minor performance improvements in scanning and configuration processing.

---

## [1.0.0+1]

### Added
- `disable` parameter to `ImportClass` for conditional import suppression.

### Changed
- Updated dependency: `jetleaf_lang`.
- Rearranged `ConfigurationClassPostProcessor`, `ConfigurationClass`, and related
  scanning and configuration classes for improved efficiency.
- Improved conditional scanning performance.

---

## [1.0.0]

Initial release.

### Added
- Core runtime and lifecycle primitives used by JetLeaf, including:
  - Application context
  - Lifecycle management
  - Core helpers and infrastructure

### Notes
- This package provides the core runtime foundation for JetLeaf. Any future
  breaking changes will include clear migration notes and guidance.

---

## Links

- Homepage: https://jetleaf.hapnium.com  
- Documentation: https://jetleaf.hapnium.com/docs/core  
- Repository: https://github.com/jetleaf/jetleaf_core  
- Issues: https://github.com/jetleaf/jetleaf_core/issues  

---

**Contributors:** Hapnium & JetLeaf contributors