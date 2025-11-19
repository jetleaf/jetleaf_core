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
/// 🫘 Represents an import entry with optional qualification metadata.
///
/// [ImportClass] is a value object that encapsulates the name of a class or
/// symbol being imported, along with a flag that indicates whether the import
/// uses a fully qualified name.
///
/// ## Fields
///
/// - [name] – The package name or qualified class name to be imported.
/// - [isQualifiedName] – Whether [name] is a fully qualified identifier
///   (e.g. `package:my_app/src/service.MyService`) instead of a simple class name.
///
/// ## Example
///
/// ```dart
/// const simple = ImportClass.package('service');
/// const qualified = ImportClass.qualified('package:my_app/src/service.MyService');
///
/// print(simple.name);           // service
/// print(simple.isQualifiedName); // false
/// print(qualified.isQualifiedName); // true
/// ```
///
/// ## Use Cases
///
/// - Tracking import metadata in code generation.
/// - Differentiating between short names and fully qualified names.
/// - Used by import selectors or registries to manage dependency references.
///
/// {@endtemplate}
final class ImportClass with EqualsAndHashCode {
  /// The name of the class or symbol to import.
  final String name;

  /// Whether [name] is fully qualified (e.g. includes a package or path).
  final bool isQualifiedName;

  /// Whether this is a `disable` import
  final bool disable;

  /// Creates a new [ImportClass] with the given [name] and [isQualifiedName] flag.
  ///
  /// {@macro import_class}
  const ImportClass(this.name, this.isQualifiedName, [this.disable = false]);

  /// Creates a new [ImportClass] with the given [name].
  /// This constructor is used when the import is not qualified.
  ///
  /// {@macro import_class}
  const ImportClass.package(this.name, [this.disable = false]) : isQualifiedName = false;

  /// Creates a new [ImportClass] with the given [name].
  /// This constructor is used when the import is qualified.
  ///
  /// {@macro import_class}
  const ImportClass.qualified(this.name, [this.disable = false]) : isQualifiedName = true;

  @override
  List<Object?> equalizedProperties() => [name, isQualifiedName];
}
