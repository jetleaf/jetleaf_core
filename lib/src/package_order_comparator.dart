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

/// {@template packageOrderComparator}
/// A comparator that orders classes based on their package hierarchy and origin.
///
/// This comparator provides a specific ordering for classes based on their
/// package structure, giving priority to core framework packages over
/// application and third-party packages. The hierarchy is:
///
/// 1. **Root package** (0) - Highest priority
/// 2. **JetLeaf main package** (1) - Core framework classes
/// 3. **JetLeaf subpackages** (2) - Framework extensions and modules
/// 4. **Dart packages** (3) - Dart SDK and core libraries
/// 5. **Everything else** (4) - Application and third-party packages
/// 6. **Unknown packages** (Ordered.LOWEST_PRECEDENCE) - Lowest priority
///
/// This ordering ensures that framework components are processed before
/// application-specific components during configuration and initialization.
///
/// **Example:**
/// ```dart
/// final comparator = PackageOrderComparator();
/// final classes = [
///   Class<UserService>(null, 'package:jetleaf_example'),      // Application class (4)
///   Class<Cache>(null, PackageNames.MAIN),            // JetLeaf main (1)
///   Class<Router>(null, 'dart.core'),                 // Dart package (3)
///   Class<Scheduling>(null, 'jetleaf.scheduling'),    // JetLeaf subpackage (2)
///   Class<Object>(null, ''),                          // Root package (0)
/// ];
///
/// classes.sort(comparator);
/// // Order will be: Object, Cache, Scheduling, Router, UserService
/// ```
/// {@endtemplate}
final class PackageOrderComparator extends OrderComparator {
  /// {@macro packageOrderComparator}
  PackageOrderComparator();

  /// {@macro comparePackageOrder}
  /// Compares two classes based on their package hierarchy.
  ///
  /// This method delegates to [getHierarchy] to determine the priority
  /// of each class and returns the comparison result.
  ///
  /// **Parameters:**
  /// - `o1`: First class to compare
  /// - `o2`: Second class to compare
  ///
  /// **Returns:**
  /// - Negative integer if `o1` has higher priority than `o2`
  /// - Positive integer if `o1` has lower priority than `o2`
  /// - Zero if both classes have the same priority
  ///
  /// **Example:**
  /// ```dart
  /// final comparator = PackageOrderComparator();
  /// 
  /// final class1 = Class<Cache>(null, PackageNames.MAIN);     // Priority 1
  /// final class2 = Class<UserService>(null, 'package:jetleaf_example');   // Priority 4
  /// 
  /// final result = comparator.compare(class1, class2);
  /// print(result); // Negative value - class1 has higher priority
  /// 
  /// // Use in sorting
  /// final classes = [class2, class1];
  /// classes.sort(comparator);
  /// // classes now ordered: [class1, class2]
  /// ```
  @override
  int compare(Object o1, Object o2) {
    final p1 = o1 as Class;
    final p2 = o2 as Class;
    return getHierarchy(p1).compareTo(getHierarchy(p2));
  }

  /// {@macro getPackageHierarchy}
  /// Determines the hierarchy level of a class based on its package.
  ///
  /// This method analyzes the class's package to assign it a priority level
  /// for ordering. Lower numbers indicate higher priority.
  ///
  /// **Parameters:**
  /// - `cls`: The class to analyze
  ///
  /// **Returns:**
  /// - Integer representing the hierarchy level (0-4) or [Ordered.LOWEST_PRECEDENCE]
  ///
  /// **Example:**
  /// ```dart
  /// final comparator = PackageOrderComparator();
  /// 
  /// // Root package
  /// final rootClass = Class<Object>(null, '');
  /// print(comparator.getHierarchy(rootClass)); // 0
  /// 
  /// // JetLeaf main package
  /// final mainClass = Class<Cache>(null, PackageNames.MAIN);
  /// print(comparator.getHierarchy(mainClass)); // 1
  /// 
  /// // JetLeaf subpackage
  /// final subClass = Class<Scheduling>(null, 'jetleaf.scheduling');
  /// print(comparator.getHierarchy(subClass)); // 2
  /// 
  /// // Dart package
  /// final dartClass = Class<String>(null, 'dart.core');
  /// print(comparator.getHierarchy(dartClass)); // 3
  /// 
  /// // Application package
  /// final appClass = Class<UserService>(null, 'package:jetleaf_example');
  /// print(comparator.getHierarchy(appClass)); // 4
  /// 
  /// // Unknown package
  /// final unknownClass = Class<Unknown>(null, 'unknown');
  /// print(comparator.getHierarchy(unknownClass)); // Ordered.LOWEST_PRECEDENCE
  /// ```
  int getHierarchy(Class cls) {
    final package = cls.getPackage();

    if (package != null) {
      final name = package.getName();

      // 0 = root
      if (package.getIsRootPackage()) {
        return 0;
      }

      // 1 = jetleaf main package
      if (name == PackageNames.MAIN) {
        return 1;
      }

      // 2 = jetleaf subpackages
      if (name.startsWith('${PackageNames.MAIN}')) {
        return 2;
      }

      // 3 = dart packages
      if (name == Constant.DART_PACKAGE_NAME || name.startsWith('${Constant.DART_PACKAGE_NAME}')) {
        return 3;
      }

      // 4 = everything else
      return 4;
    }

    // If no package info is available, push to the end
    return Ordered.LOWEST_PRECEDENCE;
  }
}