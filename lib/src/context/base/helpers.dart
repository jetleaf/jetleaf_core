// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta.dart';

/// {@template pod_factory_post_processor}
/// Factory hook that allows for custom modification of an application
/// context's pod definitions, adapting the pod property values of
/// the context's underlying pod factory.
///
/// This interface is called after all pod definitions have been loaded
/// but before any pods have been instantiated. It allows for overriding
/// or adding properties to pod definitions.
///
/// It supports two types of constructors:
/// - No-Args: Meaning that there will no arguments in the constructor.
/// - One-Arg: Meaning that there will be only one argument in the constructor of type [Environment]
///
/// ## Usage Example
///
/// ```dart
/// class PropertyPlaceholderPostProcessor implements PodFactoryPostProcessor {
///   @override
///   Future<void> processFactory(ConfigurableListablePodFactory podFactory) {
///     final podNames = podFactory.getPodDefinitionNames();
///     for (final name in podNames) {
///       final definition = podFactory.getPodDefinition(name);
///       processPlaceholders(definition);
///     }
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class PodFactoryPostProcessor {
  /// {@macro pod_factory_post_processor}
  const PodFactoryPostProcessor();

  /// {@macro pod_factory_post_processor}
  ///
  /// Modify the application context's internal pod factory after its
  /// standard initialization.
  ///
  /// All pod definitions will have been loaded, but no pods will have
  /// been instantiated yet. This allows for overriding or adding properties
  /// even to eager-initializing pods.
  ///
  /// ## Parameters
  ///
  /// - [podFactory]: The pod factory used by the application context
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory);
}

/// {@template import_selector}
/// 🫘 A strategy interface for selecting which imports should be applied.
///
/// `ImportSelector` is an abstract interface that allows libraries or frameworks
/// to determine dynamically which imports to include at runtime or configuration
/// time. It is often used in modular application setups where certain
/// dependencies or components should only be imported conditionally.
///
/// ## Usage
///
/// Implement this interface in a class and override [selects] to return
/// a list of import identifiers (usually library URIs or package paths).
///
/// ```dart
/// class MyImportSelector implements ImportSelector {
///   const MyImportSelector();
///
///   @override
///   List<String> selects() {
///     return [
///       'package:my_app/services/user_service.dart',
///       'package:my_app/repositories/user_repository.dart',
///     ];
///   }
/// }
/// ```
///
/// The framework or bootstrap process can then query [selects] to know
/// which imports to include.
///
/// ## Contract
///
/// - Classes implementing this interface must be `const` constructible.
/// - [selects] must return a list of valid strings representing import URIs.
/// - The list may be empty if no imports are required.
///
/// See also:
/// - [ApplicationStartup] 🫘 for orchestrating application initialization.
/// - [PodFactory] 🫘 for dependency resolution.
///
/// @since 1.0.0
///
/// {@endtemplate}
abstract interface class ImportSelector {
  /// Creates a constant [ImportSelector].
  ///
  /// {@macro import_selector}
  const ImportSelector();

  /// Returns a list of import URIs to include.
  ///
  /// Each string in the list should represent a library path (e.g.,
  /// `'package:my_app/my_service.dart'`). Implementations may return
  /// an empty list if no imports are needed.
  List<ImportClass> selects();
}

/// {@template import_class}
/// 🫘 Represents a **logical import entry** with qualification
/// and enablement metadata.
///
/// [ImportClass] is a lightweight value object describing **what**
/// should be imported during code generation or dependency analysis,
/// without directly emitting a Dart `import` statement.
///
/// An import may optionally reference a concrete Dart [Class],
/// while always retaining the owning package name.
///
/// Additionally, imports can be **enabled** or **disabled**, allowing
/// generators and registries to track optional or conditional imports
/// without losing intent or metadata.
///
/// ---
///
/// ## Import Forms
///
/// [ImportClass] supports two closely related forms:
///
/// ### 📦 Package Import
/// Represents an import by package name only.
///
/// - [packageName] is set
/// - [importedClass] is `null`
///
/// ```dart
/// const pkg = ImportClass.package('my_service', false);
/// ```
///
/// ### 🧬 Class Import
/// Represents an import of a specific Dart [Class].
///
/// - [packageName] is derived from the class’s owning package
/// - [importedClass] is non-null
///
/// ```dart
/// final cls = ImportClass.forClass(MyService, false);
/// ```
///
/// ---
///
/// ## Enablement
///
/// Imports are represented by two concrete variants:
///
/// - [EnabledImportClass] — actively emitted during generation
/// - [DisabledImportClass] — retained for metadata but intentionally skipped
///
/// This enables advanced workflows such as:
/// - Feature-flagged imports
/// - Environment-specific generation
/// - Deferred or conditional dependency wiring
///
/// ---
///
/// ## Equality Semantics
///
/// Two [ImportClass] instances are considered equal if they refer to the
/// same [packageName] and [importedClass], regardless of whether they are
/// enabled or disabled. This makes the type safe for use in sets, caches,
/// and registries.
///
/// ---
///
/// ## Use Cases
///
/// - Tracking import intent during code generation
/// - Differentiating package-level vs class-level imports
/// - Supporting disabled or conditional imports without loss of metadata
/// - Stable equality and hashing for dependency resolution
///
/// {@endtemplate}
abstract final class ImportClass with EqualsAndHashCode {
  /// The name of the package to import.
  ///
  /// This value is **always non-null**, even for class-level imports,
  /// where it is derived from the owning package of [importedClass].
  final String packageName;

  /// The class being imported, if this represents a class-level import.
  ///
  /// This field is `null` for package-level imports.
  final Class? importedClass;

  /// Base constructor shared by all import variants.
  ///
  /// {@macro import_class}
  const ImportClass(this.packageName, this.importedClass);

  /// Creates a **package-level import**.
  ///
  /// This constructor is used when importing by package name only,
  /// without referencing a specific Dart [Class].
  ///
  /// If [isDisabled] is `true`, the returned import will be a
  /// [DisabledImportClass]; otherwise an [EnabledImportClass].
  ///
  /// {@macro import_class}
  factory ImportClass.package(String packageName, [bool isDisabled = false]) => isDisabled 
    ? DisabledImportClass(packageName, null)
    : EnabledImportClass(packageName, null);

  /// Creates a **class-level import**.
  ///
  /// The [packageName] is automatically derived from the owning
  /// package of [importedClass].
  ///
  /// If [isDisabled] is `true`, the returned import will be a
  /// [DisabledImportClass]; otherwise an [EnabledImportClass].
  ///
  /// {@macro import_class}
  factory ImportClass.forClass(Class importedClass, [bool isDisabled = false]) => isDisabled 
    ? DisabledImportClass(importedClass.getPackage().getName(), importedClass)
    : EnabledImportClass(importedClass.getPackage().getName(), importedClass);

  @override
  List<Object?> equalizedProperties() => [packageName, importedClass ?? ImportClass];
}

/// Represents an **active import entry**.
///
/// An [EnabledImportClass] indicates that the import is eligible to be
/// **emitted**, **resolved**, or **applied** during code generation or
/// dependency analysis.
///
/// Enabled imports participate fully in:
/// - Generated `import` statements
/// - Dependency graphs
/// - Resolution and wiring logic
///
/// This class carries no additional behavior beyond its semantic role;
/// enablement is conveyed by the concrete type itself.
@internal
final class EnabledImportClass extends ImportClass {
  /// Creates an enabled import entry.
  ///
  /// {@macro import_class}
  EnabledImportClass(super.packageName, super.importedClass);
}

/// Represents a **disabled import entry**.
///
/// A [DisabledImportClass] preserves import metadata while explicitly
/// preventing it from being emitted or applied during generation.
///
/// Disabled imports are useful for:
/// - Feature-flagged or conditional imports
/// - Environment-specific generation
/// - Retaining intent without affecting output
///
/// Like [EnabledImportClass], this type is semantic rather than behavioral;
/// the disabled state is expressed by the concrete class itself.
@internal
final class DisabledImportClass extends ImportClass {
  /// Creates a disabled import entry.
  ///
  /// {@macro import_class}
  DisabledImportClass(super.packageName, super.importedClass);
}