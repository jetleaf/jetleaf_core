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

import '../../annotations/others.dart';

/// {@template jetleaf_class_CommonAnnotationPodProcessor}
/// A built-in Pod processor in Jetleaf that handles common lifecycle
/// annotations such as:
///
/// - `@PreConstruct` → executed **before initialization**
/// - `@PostConstruct` → executed **after initialization**
/// - `@PreDestroy` → executed **before destruction**
/// - `@Cleanup` → executed **after destruction**
///
/// This processor automatically scans the Pod's class for methods annotated
/// with these lifecycle annotations and invokes them at the appropriate time.
///
/// ### Example
/// ```dart
/// // Define a Pod with lifecycle methods
/// class MyService {
///   @PreConstruct
///   void initResources() {
///     print('Preparing resources...');
///   }
///
///   @PostConstruct
///   void afterInit() {
///     print('Service initialized.');
///   }
///
///   @PreDestroy
///   void beforeDestroy() {
///     print('Cleaning up before destruction...');
///   }
///
///   @Cleanup
///   void finalCleanup() {
///     print('Final cleanup done.');
///   }
/// }
///
/// // Register the processor in Jetleaf
/// final processor = CommonAnnotationPodProcessor();
/// // Jetleaf internally calls processor hooks during Pod lifecycle
/// ```
///
/// ### When to use
/// - When you want to define lifecycle behavior directly in your Pod classes.
/// - When you prefer declarative annotations instead of manual lifecycle handling.
/// - Useful for resource initialization, cleanup, caching, and service setup.
///
/// This class is part of **Jetleaf** – a framework developers can use
/// to build web applications.
/// {@endtemplate}
class CommonAnnotationPodProcessor extends DestructionAwarePodProcessor implements PriorityOrdered {
  /// {@macro jetleaf_class_CommonAnnotationPodProcessor}
  CommonAnnotationPodProcessor();

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE;

  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PreConstruct>()) {
        method.invoke(pod);
      }
    }

    return pod;
  }

  @override
  Future<Object?> processAfterInitialization(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PostConstruct>()) {
        method.invoke(pod);
      }
    }

    return pod;
  }

  @override
  Future<void> processAfterDestruction(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<Cleanup>()) {
        method.invoke(pod);
      }
    }
  }

  @override
  Future<void> processBeforeDestruction(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PreDestroy>()) {
        method.invoke(pod);
      }
    }
  }
}