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

import '../../annotations/configuration.dart';
import '../../scope/scope_metadata_resolver.dart';
import '../type_filters/type_filter.dart';

/// {@template configuration_class}
/// Represents a parsed configuration class within Jetleaf's dependency injection system.
///
/// A `ConfigurationClass` holds all metadata extracted from configuration parsing:
/// - Class metadata and applied annotations
/// - Declared `@Pod` methods
/// - Imported configuration classes via `@Import`
/// - Component scanning rules
///
/// ### Usage
/// Typically, `ConfigurationClass` is created internally by Jetleaf's
/// `ConfigurationClassParser` when analyzing application configuration.
/// You can inspect the parsed configuration for debugging or tooling purposes:
///
/// ```dart
/// void main() {
///   final configClass = ConfigurationClass(
///     'myAppConfig',
///     Class.forName('MyAppConfig'),
///   );
///
///   configClass.addPodMethod(
///     PodMethod(
///       method: Method.forName('provideService'),
///       configurationClass: configClass,
///     ),
///   );
///
///   print(configClass);
///   // Output: ConfigurationClass[MyAppConfig]
/// }
/// ```
///
/// {@endtemplate}
class ConfigurationClass extends CommonConfiguration with EqualsAndHashCode {
  /// The class type representing this configuration.
  final Class type;

  /// The pod definition representing this configuration.
  final PodDefinition definition;

  /// The optional pod name assigned to this configuration class.
  final String podName;

  /// {@macro configuration_class}
  ConfigurationClass(
    this.podName,
    this.type,
    this.definition, [
    super.proxyPodMethods,
    super.scopeResolver,
  ]);

  @override
  String toString() => 'ConfigurationClass[${type.getSimpleName()}]';

  @override
  List<Object?> equalizedProperties() => [type, proxyPodMethods, definition];
}

/// {@template pod_method}
/// Represents a single `@Pod` method discovered inside a configuration class.
///
/// This structure contains all metadata required to produce a `PodDefinition`:
/// - The method declaration and return type
/// - The pod name and qualifiers
/// - Scope metadata
/// - Conditional annotations
///
/// ### Usage
/// `PodMethod` instances are typically created during configuration parsing.
/// You can use it to inspect what pods are being declared:
///
/// ```dart
/// final podMethod = PodMethod(
///   method: Method.forName('provideService'),
///   configurationClass: configClass,
/// );
///
/// print(podMethod.getMethodName());
/// // Output: provideService
/// ```
///
/// {@endtemplate}
class PodMethod with EqualsAndHashCode {
  /// The method declaration this pod method represents.
  final Method method;

  /// The configuration class declaring this method.
  final ConfigurationClass configurationClass;

  /// {@macro pod_method}
  PodMethod({required this.method, required this.configurationClass});

  /// Returns the name of the method that provides the pod.
  String getMethodName() => method.getName();

  @override
  String toString() => 'PodMethod[${configurationClass.podName}.${getMethodName()}()]';

  @override
  List<Object?> equalizedProperties() => [method, configurationClass];
}

/// {@template component_scan_configuration}
/// Holds metadata extracted from `@ComponentScan` annotations.
///
/// Defines the scanning rules for discovering components:
/// - Base packages to scan
/// - Include/exclude filters
/// - Whether to use default filters
/// - Custom scope resolver and name generator
///
/// ### Usage
/// Typically created during annotation parsing when encountering `@ComponentScan`.
///
/// ```dart
/// final scanConfig = ComponentScanConfiguration(
///   basePackages: ['package:example/test.dart.services'],
///   includeFilters: [AnnotationTypeFilter(Class.forName('Service'))],
/// );
///
/// print(scanConfig.basePackages);
/// // Output: [package:example/test.dart.services]
/// ```
///
/// {@endtemplate}
class ComponentScanConfiguration with EqualsAndHashCode {
  /// Base packages to scan for annotated components.
  final List<String> basePackages;

  /// Base package classes (alternative to specifying packages by string).
  final List<Class> basePackageClasses;

  /// Filters that must match for a component to be included.
  final List<TypeFilter> includeFilters;

  /// Filters that must match for a component to be excluded.
  final List<TypeFilter> excludeFilters;

  /// Whether Jetleaf should apply its default filters (@Component, @Service, etc.).
  final bool useDefaultFilters;

  /// Optional custom scope metadata resolver.
  final ScopeMetadataResolver? scopeResolver;

  /// Optional custom name generator for discovered components.
  final PodNameGenerator? nameGenerator;

  /// {@macro component_scan_configuration}
  ComponentScanConfiguration({
    this.basePackages = const [],
    this.basePackageClasses = const [],
    this.includeFilters = const [],
    this.excludeFilters = const [],
    this.useDefaultFilters = true,
    this.scopeResolver,
    this.nameGenerator,
  });

  @override
  List<Object?> equalizedProperties() => [
    basePackages,
    basePackageClasses,
    includeFilters,
    excludeFilters,
    useDefaultFilters,
    scopeResolver,
    nameGenerator,
  ];
}