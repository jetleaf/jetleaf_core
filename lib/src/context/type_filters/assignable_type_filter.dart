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

/// {@template assignable_type_filter}
/// A [TypeFilter] that matches classes assignable to a specific target type.
///
/// This filter checks whether a given class is assignable to (i.e., is a subtype of)
/// the specified target type. It's useful for finding all implementations of an
/// interface, all subclasses of a base class, or classes that implement specific
/// functionality.
///
/// **Example:**
/// ```dart
/// // Filter for all classes that implement Cache interface
/// final cacheFilter = AssignableTypeFilter(
///   Class<Cache>(null, PackageNames.CORE)
/// );
///
/// // Filter for all subclasses of AbstractService
/// final serviceFilter = AssignableTypeFilter(
///   Class<AbstractService>(null, 'package:example/test.dart')
/// );
///
/// // Filter for all classes assignable to Repository
/// final repositoryFilter = AssignableTypeFilter(
///   Class<Repository>(null, PackageNames.CORE)
/// );
///
/// // Use in component scanning
/// final scanner = ClassPathPodDefinitionScanner(...);
/// scanner.addIncludeFilter(cacheFilter);
/// scanner.addIncludeFilter(serviceFilter);
///
/// // Test class matching
/// final memoryCacheClass = Class<MemoryCache>(null, 'package:example/test.dart.cache');
/// final userServiceClass = Class<UserService>(null, 'package:example/test.dart.services');
/// final plainClass = Class<PlainClass>(null, 'package:example/test.dart');
///
/// print(cacheFilter.matches(memoryCacheClass));     // true if MemoryCache implements Cache
/// print(serviceFilter.matches(userServiceClass));   // true if UserService extends AbstractService
/// print(repositoryFilter.matches(plainClass));      // false if PlainClass doesn't implement Repository
/// ```
/// {@endtemplate}
class AssignableTypeFilter extends TypeFilter {
  /// {@macro targetType}
  /// The target type to check assignability against.
  ///
  /// This class reference specifies the supertype or interface that candidate
  /// classes must be assignable to in order to match the filter.
  final Class targetType;

  /// {@macro assignable_type_filter}
  /// Creates a new assignable type filter.
  ///
  /// **Parameters:**
  /// - `targetType`: The target type that classes must be assignable to
  ///
  /// **Example:**
  /// ```dart
  /// // Filter for event handler implementations
  /// final eventHandlerFilter = AssignableTypeFilter(
  ///   Class<EventHandler>(null, 'package:example/test.dart.events')
  /// );
  ///
  /// // Filter for plugin implementations
  /// final pluginFilter = AssignableTypeFilter(
  ///   Class<Plugin>(null, 'package:example/test.dart.plugins')
  /// );
  ///
  /// // Filter for service base class
  /// final baseServiceFilter = AssignableTypeFilter(
  ///   Class<BaseService>(null, 'package:example/test.dart.services')
  /// );
  /// ```
  AssignableTypeFilter(this.targetType);

  /// {@macro matchesAssignable}
  /// Determines if the given class is assignable to the target type.
  ///
  /// This method uses the `isAssignableFrom` method to check if the candidate
  /// class is a subtype of the target type, either through inheritance or
  /// interface implementation.
  ///
  /// **Parameters:**
  /// - `cls`: The class to check for assignability
  ///
  /// **Returns:**
  /// - `true` if the class is assignable to the target type, `false` otherwise
  ///
  /// **Example:**
  /// ```dart
  /// final filter = AssignableTypeFilter(
  ///   Class<Runnable>(null, PackageNames.CORE)
  /// );
  ///
  /// // Class that implements Runnable
  /// final runnableClass = Class<MyTask>(null, 'package:example/test.dart.tasks');
  /// print(filter.matches(runnableClass)); // true if MyTask implements Runnable
  ///
  /// // Class that doesn't implement Runnable
  /// final nonRunnableClass = Class<DataModel>(null, 'package:example/test.dart.models');
  /// print(filter.matches(nonRunnableClass)); // false
  ///
  /// // Interface assignment check
  /// final cacheFilter = AssignableTypeFilter(
  ///   Class<Cache>(null, PackageNames.CORE)
  /// );
  /// final memoryCacheClass = Class<MemoryCache>(null, 'package:example/test.dart.cache');
  /// final isCache = cacheFilter.matches(memoryCacheClass); // true if MemoryCache implements Cache
  /// ```
  @override
  bool matches(Class cls) => targetType.isAssignableFrom(cls);
}