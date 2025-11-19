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

import '../../annotations/lifecycle.dart';
import '../../aware.dart';
import '../base/application_context.dart';

/// {@template applicationAnnotatedLifecycleProcessor}
/// Processor for application lifecycle annotations that discovers and invokes
/// methods annotated with [@OnApplicationStopping] and [@OnApplicationStopped].
///
/// This processor scans all methods in the runtime for lifecycle annotations
/// and automatically invokes them during application shutdown phases. It handles
/// constructor resolution and parameter injection for the annotated methods,
/// using the provided [ApplicationContext] for dependency resolution and context injection.
///
/// **Key Features:**
/// - Runtime scanning for lifecycle annotations
/// - Application context-aware method invocation
/// - Automatic instantiation of annotated method classes
/// - Application context parameter injection
/// - Ordered invocation of lifecycle callbacks
///
/// **Annotation Support:**
/// - `@OnApplicationStopping`: Invoked when application is about to stop
/// - `@OnApplicationStopped`: Invoked after application has stopped
///
/// **Example:**
/// ```dart
/// class DatabaseCleanup {
///   @OnApplicationStopping
///   void cleanup(ApplicationContext context) {
///     // Cleanup database connections before app stops
///     context.getPod<DatabasePool>().close();
///   }
/// }
///
/// class MetricsReporter {
///   @OnApplicationStopped
///   void reportShutdown(ApplicationContext context) {
///     // Report final metrics after app has stopped
///     Metrics.flush();
///   }
/// }
///
/// // Usage with application context
/// final context = ApplicationContext();
/// final processor = ApplicationAnnotatedLifecycleProcessor(context);
/// await processor.discover(); // Scan and prepare lifecycle methods
/// await processor.onStopping(); // Invoke @OnApplicationStopping methods
/// await processor.onStopped();  // Invoke @OnApplicationStopped methods
/// ```
/// {@endtemplate}
final class ApplicationAnnotatedLifecycleProcessor implements SmartInitializingSingleton, PodFactoryAware {
  /// {@macro applicationContext}
  /// The application context used for dependency resolution and context injection.
  final ApplicationContext context;

  /// {@macro applicationAnnotatedLifecycleProcessor}
  /// Creates a new application annotated lifecycle processor with the given context.
  ///
  /// **Parameters:**
  /// - `context`: The application context for dependency resolution and injection
  ///
  /// **Example:**
  /// ```dart
  /// final context = ApplicationContext();
  /// final processor = ApplicationAnnotatedLifecycleProcessor(context);
  /// ```
  ApplicationAnnotatedLifecycleProcessor(this.context);

  /// {@macro applicationStoppingMethods}
  /// Registry of methods annotated with [@OnApplicationStopping] and their instances.
  final Map<Object, Method> _onApplicationStoppingMethods = {};

  /// {@macro applicationStoppedMethods}
  /// Registry of methods annotated with [@OnApplicationStopped] and their instances.
  final Map<Object, Method> _onApplicationStoppedMethods = {};

  PodFactory? _podFactory;

  @override
  String getPackageName() => PackageNames.CORE;
  
  @override
  Future<void> onSingletonReady() async {
    final onStoppingMethods = <Method>{};
    final onStoppedMethods = <Method>{};

    MethodUtils.collectMethods<OnApplicationStopped>(onStoppedMethods);
    MethodUtils.collectMethods<OnApplicationStopping>(onStoppingMethods);

    for (final method in onStoppedMethods) {
      final cls = method.getDeclaringClass();
      if (_podFactory != null && await _podFactory!.containsType(cls)) {
        final target = await _podFactory!.get(cls);
        _onApplicationStoppedMethods[target] = method;
      } else if (cls.isInvokable()) {
        final cst = cls.getNoArgConstructor() ?? cls.getBestConstructor([]) ?? cls.getDefaultConstructor();

        if (cst != null) {
          final target = cst.newInstance();
          _onApplicationStoppedMethods[target] = method;
        }
      }
    }

    for (final method in onStoppingMethods) {
      final cls = method.getDeclaringClass();
      if (_podFactory != null && await _podFactory!.containsType(cls)) {
        final target = await _podFactory!.get(cls);
        _onApplicationStoppingMethods[target] = method;
      } else if (cls.isInvokable()) {
        final cst = cls.getNoArgConstructor() ?? cls.getBestConstructor([]) ?? cls.getDefaultConstructor();

        if (cst != null) {
          final target = cst.newInstance();
          _onApplicationStoppingMethods[target] = method;
        }
      }
    }
  }
  
  @override
  void setPodFactory(PodFactory podFactory) {
    _podFactory = podFactory;
  }

  /// {@macro onApplicationStopping}
  /// Invokes all methods annotated with [@OnApplicationStopping].
  ///
  /// This method is called when the application is about to stop but before
  /// the main shutdown sequence. It provides an opportunity for components
  /// to perform cleanup operations while the application context is still active.
  ///
  /// **Parameter Injection:**
  /// - Methods can accept an [ApplicationContext] parameter which will be
  ///   automatically injected using the provided context instance
  ///
  /// **Example:**
  /// ```dart
  /// await processor.onStopping();
  /// // All @OnApplicationStopping methods have been invoked with context
  /// ```
  Future<void> onStopping() async {
    for (final m in _onApplicationStoppingMethods.entries) {
      final method = m.value;
      final instance = m.key;

      final arguments = <String, Object?>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }

      method.invoke(instance, arguments);
    }
  }

  /// {@macro onApplicationStopped}
  /// Invokes all methods annotated with [@OnApplicationStopped].
  ///
  /// This method is called after the application has completely stopped and
  /// the main shutdown sequence has finished. It's suitable for final
  /// reporting, logging, or cleanup that doesn't require the application context.
  ///
  /// **Parameter Injection:**
  /// - Methods can accept an [ApplicationContext] parameter which will be
  ///   automatically injected using the provided context instance
  ///
  /// **Example:**
  /// ```dart
  /// await processor.onStopped();
  /// // All @OnApplicationStopped methods have been invoked with context
  /// ```
  Future<void> onStopped() async {
    for (final m in _onApplicationStoppedMethods.entries) {
      final method = m.value;
      final instance = m.key;

      final arguments = <String, Object?>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }

      method.invoke(instance, arguments);
    }
  }

  /// {@macro isAssignableFromApplicationContext}
  /// Checks if the given class is assignable to [ApplicationContext].
  bool _isAssignableFromApplicationContext(Class clazz) => Class<ApplicationContext>().isAssignableFrom(clazz);
}