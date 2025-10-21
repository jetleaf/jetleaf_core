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

/// {@template regex_pattern_type_filter}
/// A [TypeFilter] that matches classes based on regular expression patterns against class names.
///
/// This filter uses regular expressions to match class qualified names, allowing for
/// flexible pattern-based filtering. It's useful for matching classes by naming
/// conventions, package patterns, or specific class name structures.
///
/// **Example:**
/// ```dart
/// // Filter for classes in specific package using regex
/// final packageFilter = RegexPatternTypeFilter(
///   RegExp(r'^com\.example\.services\..*')
/// );
///
/// // Filter for classes with "Controller" suffix
/// final controllerFilter = RegexPatternTypeFilter(
///   RegExp(r'Controller$')
/// );
///
/// // Filter for classes with specific naming pattern
/// final namingFilter = RegexPatternTypeFilter(
///   RegExp(r'^[A-Z][a-zA-Z]*Impl$')
/// );
///
/// // Filter for test classes
/// final testFilter = RegexPatternTypeFilter(
///   RegExp(r'Test$')
/// );
///
/// // Use in component scanning
/// final scanner = ClassPathPodDefinitionScanner(...);
/// scanner.addIncludeFilter(packageFilter);
/// scanner.addExcludeFilter(testFilter);
///
/// // Test class matching
/// final serviceClass = Class<UserService>(null, 'package:example/test.dart.services');
/// final controllerClass = Class<UserController>(null, 'package:example/test.dart.web');
/// final testClass = Class<UserServiceTest>(null, 'package:example/test.dart.services');
///
/// print(packageFilter.matches(serviceClass));     // true - matches package pattern
/// print(controllerFilter.matches(controllerClass)); // true - ends with "Controller"
/// print(testFilter.matches(testClass));           // true - ends with "Test"
/// print(namingFilter.matches(serviceClass));      // false - doesn't match pattern
/// ```
/// {@endtemplate}
class RegexPatternTypeFilter extends TypeFilter {
  /// {@macro pattern}
  /// The regular expression pattern to match against class names.
  ///
  /// This pattern is applied to the fully qualified class name to determine
  /// if the class matches the filter criteria.
  final RegExp pattern;

  /// {@macro regex_pattern_type_filter}
  /// Creates a new regex pattern type filter.
  ///
  /// **Parameters:**
  /// - `pattern`: The regular expression pattern for matching class names
  ///
  /// **Example:**
  /// ```dart
  /// // Match all classes in "dao" package
  /// final daoFilter = RegexPatternTypeFilter(
  ///   RegExp(r'\.dao\.')
  /// );
  ///
  /// // Match classes with "Factory" in name
  /// final factoryFilter = RegexPatternTypeFilter(
  ///   RegExp(r'Factory')
  /// );
  ///
  /// // Match classes with specific prefix and suffix
  /// final customFilter = RegexPatternTypeFilter(
  ///   RegExp(r'^com\.company\.module\.Abstract.*Handler$')
  /// );
  ///
  /// // Match using case-insensitive pattern
  /// final caseInsensitiveFilter = RegexPatternTypeFilter(
  ///   RegExp(r'repository', caseSensitive: false)
  /// );
  /// ```
  const RegexPatternTypeFilter(this.pattern);

  /// {@macro matchesRegex}
  /// Determines if the given class matches the regular expression pattern.
  ///
  /// This method applies the regex pattern to the class's fully qualified name
  /// and returns whether there's at least one match.
  ///
  /// **Parameters:**
  /// - `cls`: The class to check against the regex pattern
  ///
  /// **Returns:**
  /// - `true` if the class's qualified name matches the pattern, `false` otherwise
  ///
  /// **Example:**
  /// ```dart
  /// // Filter for web-related classes
  /// final webFilter = RegexPatternTypeFilter(
  ///   RegExp(r'\.web\.|Controller|Rest|Endpoint')
  /// );
  ///
  /// // Filter for utility classes
  /// final utilFilter = RegexPatternTypeFilter(
  ///   RegExp(r'Utils?$|Helper$|Util$')
  /// );
  ///
  /// // Test various classes
  /// final webClass = Class<UserController>(null, 'package:example/test.dart.web');
  /// final utilClass = Class<StringUtils>(null, 'package:example/test.dart.utils');
  /// final serviceClass = Class<UserService>(null, 'package:example/test.dart.services');
  ///
  /// print(webFilter.matches(webClass));    // true - contains "Controller"
  /// print(utilFilter.matches(utilClass));  // true - ends with "Utils"
  /// print(webFilter.matches(serviceClass)); // false - no web pattern match
  /// print(utilFilter.matches(serviceClass)); // false - no util pattern match
  /// ```
  @override
  bool matches(Class cls) => pattern.hasMatch(cls.getQualifiedName());
}