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

/// {@template typeFilter}
/// Abstract base class for type filtering strategies used in component scanning.
///
/// Type filters are used to selectively include or exclude classes during
/// component scanning based on various criteria such as annotations, naming
/// patterns, or other class characteristics. Implementations define the
/// specific matching logic while this base class provides the common interface.
///
/// **Common Implementations:**
/// - [AnnotationTypeFilter] - Matches classes based on annotations
/// - [AssignableTypeFilter] - Matches classes assignable to a specific type
/// - [RegexPatternTypeFilter] - Matches classes based on name patterns
///
/// **Example:**
/// ```dart
/// // Custom filter for specific business logic
/// class MyCustomFilter extends TypeFilter {
///   @override
///   bool matches(Class cls) {
///     return cls.getName().startsWith('My') && 
///            cls.hasAnnotation<BusinessService>();
///   }
/// }
///
/// // Use in component scanning
/// final scanner = ClassPathPodDefinitionScanner(...);
/// scanner.addIncludeFilter(MyCustomFilter());
///
/// // Multiple filters can be combined
/// scanner.addIncludeFilter(AnnotationTypeFilter(
///   Class<Component>(null, PackageNames.CORE)
/// ));
/// scanner.addExcludeFilter(AnnotationTypeFilter(
///   Class<Deprecated>(null, PackageNames.DART)
/// ));
/// ```
/// {@endtemplate}
abstract class TypeFilter {
  /// {@macro typeFilter}
  const TypeFilter();

  /// {@macro typeFilterMatches}
  /// Returns `true` if the given [cls] matches this filter.
  ///
  /// This method defines the core matching logic for the filter. Implementations
  /// should examine the class and return whether it meets the filter criteria.
  ///
  /// **Parameters:**
  /// - `cls`: The class to evaluate against the filter criteria
  ///
  /// **Returns:**
  /// - `true` if the class matches the filter, `false` otherwise
  ///
  /// **Example:**
  /// ```dart
  /// class MyAnnotationFilter extends TypeFilter {
  ///   @override
  ///   bool matches(Class cls) {
  ///     // Match classes with @MyAnnotation
  ///     return cls.hasAnnotation<MyAnnotation>();
  ///   }
  /// }
  ///
  /// class PackageFilter extends TypeFilter {
  ///   final String packagePrefix;
  ///
  ///   PackageFilter(this.packagePrefix);
  ///
  ///   @override
  ///   bool matches(Class cls) {
  ///     // Match classes in specific package
  ///     final package = cls.getPackage()?.getName() ?? '';
  ///     return package.startsWith(packagePrefix);
  ///   }
  /// }
  ///
  /// // Usage
  /// final annotationFilter = MyAnnotationFilter();
  /// final packageFilter = PackageFilter('package:example/test.dart.');
  ///
  /// final testClass = Class<MyService>(null, 'package:example/test.dart.services');
  /// final matchesAnnotation = annotationFilter.matches(testClass);
  /// final matchesPackage = packageFilter.matches(testClass);
  /// ```
  bool matches(Class cls);

  /// {@macro setEntryApplication}
  /// Sets the entry application class for context-aware filtering.
  ///
  /// This method provides the entry application class to filters that need
  /// context about the main application for their matching logic. The default
  /// implementation does nothing, but subclasses can override to use the
  /// application context.
  ///
  /// **Parameters:**
  /// - `mainClass`: The main application class
  ///
  /// **Example:**
  /// ```dart
  /// class ContextAwareFilter extends TypeFilter {
  ///   Class<Object>? _mainClass;
  ///
  ///   @override
  ///   void setEntryApplication(Class<Object> mainClass) {
  ///     _mainClass = mainClass;
  ///   }
  ///
  ///   @override
  ///   bool matches(Class cls) {
  ///     // Use main class context in matching logic
  ///     if (_mainClass != null) {
  ///       return cls.getPackage() == _mainClass!.getPackage();
  ///     }
  ///     return false;
  ///   }
  /// }
  /// ```
  void setEntryApplication(Class<Object> mainClass) {}
}