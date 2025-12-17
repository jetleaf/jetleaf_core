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

import 'type_filter.dart';

/// {@template annotation_type_filter}
/// A [TypeFilter] that matches classes based on the presence of specific annotations.
///
/// This filter can be configured to consider either direct annotations only
/// or to include meta-annotations (annotations on annotations) when performing
/// matches. It's commonly used in component scanning and auto-configuration
/// scenarios to selectively include or exclude classes based on annotations.
///
/// **Example:**
/// ```dart
/// // Filter for classes with @Component annotation (including meta-annotations)
/// final componentFilter = AnnotationTypeFilter(
///   Class<Component>(null, PackageNames.CORE),
///   considerMetaAnnotations: true
/// );
///
/// // Filter for classes with direct @Service annotation only
/// final serviceFilter = AnnotationTypeFilter(
///   Class<Service>(null, PackageNames.CORE),
///   considerMetaAnnotations: false
/// );
///
/// // Filter for custom annotation
/// final customFilter = AnnotationTypeFilter(
///   Class<MyCustomAnnotation>(null, 'package:example/test.dart'),
///   considerMetaAnnotations: true
/// );
///
/// // Use in component scanning
/// final scanner = ClassPathPodDefinitionScanner(...);
/// scanner.addIncludeFilter(componentFilter);
/// scanner.addExcludeFilter(serviceFilter);
///
/// // Test class matching
/// final testClass = Class<MyComponent>(null, 'package:example/test.dart');
/// final isComponent = componentFilter.matches(testClass);
/// final isService = serviceFilter.matches(testClass);
///
/// print('Is component: $isComponent'); // true if @Component or meta-annotation
/// print('Is service: $isService');     // true only if directly @Service
/// ```
/// {@endtemplate}
class AnnotationTypeFilter extends TypeFilter {
  /// {@macro annotationType}
  /// The annotation type to match against.
  ///
  /// This class reference specifies which annotation to look for when
  /// determining if a class matches the filter criteria.
  final Class annotationType;

  /// {@macro considerMetaAnnotations}
  /// Whether to consider meta-annotations when matching.
  ///
  /// When true, the filter will match classes that have the target annotation
  /// either directly or through meta-annotations (annotations on annotations).
  /// When false, only direct annotations are considered.
  final bool considerMetaAnnotations;

  /// {@macro annotation_type_filter}
  /// Creates a new annotation type filter.
  ///
  /// **Parameters:**
  /// - `annotationType`: The annotation class to match
  /// - `considerMetaAnnotations`: Whether to consider meta-annotations (defaults to true)
  ///
  /// **Example:**
  /// ```dart
  /// // Filter that includes meta-annotations (default behavior)
  /// final inclusiveFilter = AnnotationTypeFilter(
  ///   Class<Component>(null, PackageNames.CORE)
  /// );
  ///
  /// // Filter that only considers direct annotations
  /// final exclusiveFilter = AnnotationTypeFilter(
  ///   Class<Service>(null, PackageNames.CORE),
  ///   considerMetaAnnotations: false
  /// );
  /// ```
  AnnotationTypeFilter(this.annotationType, {this.considerMetaAnnotations = true});

  /// {@macro matchesAnnotation}
  /// Determines if the given class matches this filter's criteria.
  ///
  /// The matching behavior depends on the [considerMetaAnnotations] setting:
  /// - When true: matches if the class has the annotation either directly or through meta-annotations
  /// - When false: matches only if the class has the annotation directly
  ///
  /// **Parameters:**
  /// - `cls`: The class to check for annotation presence
  ///
  /// **Returns:**
  /// - `true` if the class matches the filter criteria, `false` otherwise
  ///
  /// **Example:**
  /// ```dart
  /// final filter = AnnotationTypeFilter(
  ///   Class<RestController>(null, PackageNames.CORE),
  ///   considerMetaAnnotations: true
  /// );
  ///
  /// // Class with direct @RestController annotation
  /// final directClass = Class<MyRestController>(null, 'package:example/test.dart');
  /// print(filter.matches(directClass)); // true
  ///
  /// // Class with @Controller (which is meta-annotated with @RestController)
  /// final metaClass = Class<MyController>(null, 'package:example/test.dart');
  /// print(filter.matches(metaClass)); // true if considerMetaAnnotations is true
  ///
  /// // Class without the annotation
  /// final plainClass = Class<MyService>(null, 'package:example/test.dart');
  /// print(filter.matches(plainClass)); // false
  /// ```
  @override
  bool matches(Class cls) {
    if (considerMetaAnnotations) {
      return cls.getAllAnnotations().any((a) => a.getDeclaringClass() == annotationType);
    } else {
      return cls.getAllDirectAnnotations().any((a) => a.getDeclaringClass() == annotationType);
    }
  }
}