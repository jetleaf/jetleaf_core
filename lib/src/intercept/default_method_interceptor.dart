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

import 'dart:async';

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../annotation_aware_order_comparator.dart';
import '../annotations/intercept.dart';
import '../aware.dart';
import '../exceptions.dart';
import 'abstract_method_dispatcher.dart';
import 'intercept_registry.dart';
import 'interceptable.dart';
import 'method_interceptor.dart';

/// {@template default_interceptor_registry}
/// Default implementation of [MethodInterceptorRegistry] and related intercept processing.
///
/// This class serves as the central registry and dispatcher for method-level
/// interceptors in a JetLeaf application. It is responsible for:
/// 1. Collecting all [MethodInterceptor] implementations from the PodFactory.
/// 2. Applying ordering rules based on [PriorityOrdered] and [Ordered] annotations.
/// 3. Managing a custom [MethodInterceptorDispatcher] if provided.
/// 4. Injecting itself into any [Interceptable] pods so they can delegate method
///    calls for interception.
///
/// ## Responsibilities
/// - **Interceptor Management**: Add, remove, and maintain ordered sets of
///   interceptors.
/// - **Dispatcher Configuration**: Support custom dispatcher injection and fallback
///   to default dispatching logic.
/// - **Pod Lifecycle Integration**: Implements [PodInstantiationProcessor] and
///   [SmartInitializingSingleton] to hook into pod creation and initialization
///   events for automatic registration of interceptors.
/// - **Logging**: Uses JetLeaf logging for info/debug during interceptor collection
///   and registration.
///
/// ## Lifecycle
/// 1. During pod instantiation, this registry can attach itself to [Interceptable] pods.
/// 2. After singleton initialization ([onSingletonReady]), it:
///    - Collects all [MethodInterceptor] pods from the [PodFactory].
///    - Collects all [MethodInterceptorConfigurer] pods and invokes
///      their `configure` method to register additional interceptors.
/// 3. Interceptors are sorted by priority and order annotations using
///    [AnnotationAwareOrderComparator].
/// 4. Once initialized, the registry can be used to intercept method calls
///    transparently via [AbstractMethodDispatcher].
///
/// ## Example Usage
/// ```dart
/// final registry = DefaultMethodInterceptor();
/// registry.setPodFactory(podFactory);
/// await registry.onSingletonReady(); // Collect interceptors
///
/// // Adding a custom interceptor manually
/// registry.addMethodInterceptor(CustomLoggingInterceptor());
///
/// // Setting a custom dispatcher if needed
/// registry.setMethodInterceptorDispatcher(MyCustomDispatcher());
/// ```
/// {@endtemplate}
final class DefaultMethodInterceptor extends AbstractMethodDispatcher implements PodFactoryAware, SmartInitializingSingleton, PodInitializationProcessor, MethodInterceptorRegistry {
  /// The pod factory used to discover and instantiate interceptors and configurers.
  ///
  /// This is a late-initialized reference to the application's [ConfigurableListablePodFactory].
  /// It provides access to all available pods of certain types and allows
  /// the registry to collect interceptors automatically during initialization.
  ///
  /// Typically set via [setPodFactory] when the registry is created or initialized.
  late ConfigurableListablePodFactory podFactory;

  /// Logger instance for diagnostics and informational messages.
  ///
  /// Used throughout the registry to log key lifecycle events, such as:
  /// - Discovery of interceptors and configurers.
  /// - Registration and ordering of interceptors.
  /// - Warnings or errors when expected pods or methods are not found.
  ///
  /// This uses JetLeaf's logging framework via [LogFactory].
  final Log _logger = LogFactory.getLog(DefaultMethodInterceptor);

  /// The registry of all active [MethodInterceptor] instances.
  ///
  /// Maps an optional *pod name* (or unique identifier) to its corresponding
  /// [MethodInterceptor]. This map serves as the central source of truth for
  /// all interceptors that participate in method dispatching.
  ///
  /// When a method invocation occurs, this registry is consulted to determine
  /// which interceptors should apply via [MethodInterceptor.canIntercept].
  ///
  /// Interceptor registration is internally synchronized to prevent
  /// concurrent modification issues during application startup or dynamic
  /// registration at runtime.
  final Map<String?, MethodInterceptor> _methodInterceptors = {};

  /// A cache of ordering relationships between interceptors.
  ///
  /// Each [MethodInterceptor] is mapped to a resolved [_InterceptorRelations]
  /// instance, which describes its declared `before` and `after` dependencies
  /// (derived from `@RunBefore` and `@RunAfter` annotations).
  ///
  /// This cache allows fast lookup during sorting and prevents redundant
  /// recomputation of relationships each time interceptors are reordered.
  ///
  /// It is typically populated during initialization and referenced by
  /// [_sortInterceptorsByRelations] when determining execution order.
  final Map<MethodInterceptor, _InterceptorRelations> _interceptorOrderCache = {};

  /// Optional custom dispatcher for method interception.
  ///
  /// If set via [setMethodInterceptorDispatcher], this dispatcher will handle
  /// the execution of interceptors when a method call occurs. If null, the
  /// registry will fall back to the default dispatching mechanism provided by
  /// [AbstractMethodDispatcher].
  ///
  /// This allows developers to plug in custom interception logic or control
  /// the order/strategy of applying interceptors.
  MethodInterceptorDispatcher? _customMethodInterceptorDispatcher;

  /// {@macro default_interceptor_registry}
  DefaultMethodInterceptor();

  @override
  void addMethodInterceptor(MethodInterceptor interceptor, [String? podName]) {
    return synchronized(_methodInterceptors, () {
      final cls = interceptor.getClass();
      final key = podName ?? cls.getQualifiedName();
      _methodInterceptors[key] = interceptor;

      // Cache the ordering annotations once
      final runBefore = cls.getDirectAnnotation<RunBefore>();
      final runAfter = cls.getDirectAnnotation<RunAfter>();

      if (runBefore != null || runAfter != null) {
        _interceptorOrderCache[interceptor] = _resolveInterceptorRelations(runBefore, runAfter);
      }
    });
  }

  /// Resolves and normalizes the declared interceptor relationships from
  /// the `@RunBefore` and `@RunAfter` annotations into a unified
  /// [_InterceptorRelations] structure.
  ///
  /// Each annotation may specify a mix of:
  ///  - **String identifiers** (interpreted as pod or qualified class names)
  ///  - **Type references** (resolved to `Class` objects via [ClassUtils])
  ///
  /// This function separates them into four lists:
  ///  - `beforeNames` — names that this interceptor should run *before*
  ///  - `beforeTypes` — types that this interceptor should run *before*
  ///  - `afterNames` — names that this interceptor should run *after*
  ///  - `afterTypes` — types that this interceptor should run *after*
  ///
  /// String values that look like class names (according to
  /// [ClassUtils.isClass]) are ignored as names to avoid confusion with types.
  /// Type values are converted to `Class` instances.
  ///
  /// Returns:
  ///   A fully populated [_InterceptorRelations] instance, even if both
  ///   annotations are `null`.
  _InterceptorRelations _resolveInterceptorRelations(RunBefore? before, RunAfter? after) {
    List<String> bn = [];
    List<Class> bt = [];
    List<String> an = [];
    List<Class> at = [];

    if (before != null) {
      for (final val in before.targets) {
        if (val is String && !ClassUtils.isClass(val)) {
          bn.add(val);
        } else if (val is Type) {
          bt.add(ClassUtils.getClass(val));
        }
      }
    }

    if (after != null) {
      for (final val in after.targets) {
        if (val is String) {
          an.add(val);
        } else if (val is Type) {
          at.add(ClassUtils.getClass(val));
        }
      }
    }

    return _InterceptorRelations(beforeNames: bn, beforeTypes: bt, afterNames: an, afterTypes: at);
  }

  @override
  void setMethodInterceptorDispatcher(MethodInterceptorDispatcher dispatcher) {
    _customMethodInterceptorDispatcher = dispatcher;
  }

  @override
  String getPackageName() => PackageNames.CORE;

  @override
  void setPodFactory(PodFactory podFactory) async {
    if (podFactory is ConfigurableListablePodFactory) {
      this.podFactory = podFactory;
    }
  }
  
  @override
  Future<Object?> processAfterInitialization(Object pod, Class podClass, String name) async {
    final proxyClass = podClass.getSubClasses().find((cls) => cls.getName().startsWith(Constant.PROXY_IDENTIFIER));
    if (proxyClass != null) {
      final newInstance = proxyClass.getDefaultConstructor()?.newInstance({}, [pod]);
      (newInstance as Interceptable).support = getMethodInterceptorDispatcher() ?? this;

      return newInstance;
    }

    if (pod is Interceptable) {
      pod.support = getMethodInterceptorDispatcher() ?? this;
    }

    return pod;
  }
  
  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async => pod;
  
  @override
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async => false;

  @override
  Future<void> onSingletonReady() async {
    if(_logger.getIsTraceEnabled()) {
      _logger.trace("Starting method interceptor post-processing for PodFactory");
    }

    await _findAndCollectInterceptors();
    await _findAndCollectConfigurers();
    
    if (_logger.getIsTraceEnabled()) {
      _logger.trace("Method interceptor post-processing completed successfully");
    }
  }

  /// Discovers, orders, and registers all [MethodInterceptor] implementations
  /// available in the application's [podFactory].
  ///
  /// This private asynchronous method is part of the interceptor initialization
  /// lifecycle and is typically called during the post-processing phase
  /// ([onSingletonReady]) of the [DefaultMethodInterceptor].
  ///
  /// ## Behavior
  /// 1. Logs the start of the interceptor discovery process at INFO level.
  /// 2. Uses the pod factory to retrieve all pods of type [MethodInterceptor]
  ///    from the `jetleaf.advice` package. Eager initialization is enabled to ensure all
  ///    interceptors are instantiated before registration.
  /// 3. If any interceptors are found:
  ///    - Logs the count at DEBUG level.
  ///    - Converts the pods into a list and sorts them using [AnnotationAwareOrderComparator]
  ///      to respect any ordering annotations or priorities.
  ///    - Registers each interceptor via [addMethodInterceptor], ensuring
  ///      thread-safe addition.
  ///    - Logs the total number of registered interceptors at INFO level.
  /// 4. If no interceptors are found, logs a message indicating none were discovered.
  ///
  /// This method ensures that all method interceptors are collected, ordered, and
  /// made available for dispatching when method invocations occur.
  ///
  /// @private
  /// @async
  /// @return Future that completes once interceptors are discovered and registered
  Future<void> _findAndCollectInterceptors() async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace("Loading Interceptors");
    }
    
    final type = Class<MethodInterceptor>(null, PackageNames.CORE);
    final pods = await podFactory.getPodsOf(type, allowEagerInit: true);

    if (pods.isNotEmpty) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace("Found ${pods.length} MethodInterceptor implementations");
      }

      // Convert to list of entries to keep the keys
      final entries = pods.entries.toList();

      // Sort entries by the interceptor order
      entries.sort((a, b) => AnnotationAwareOrderComparator().compare(a.value, b.value));

      for (final entry in entries) {
        addMethodInterceptor(entry.value, entry.key);
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace("Registered ${entries.length} Interceptors");
      }
    } else {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace("No MethodInterceptor implementations found");
      }
    }
  }

  /// Discovers, orders, and applies all [MethodInterceptorConfigurer] implementations
  /// available in the application's [podFactory].
  ///
  /// This private asynchronous method is part of the interceptor post-processing
  /// lifecycle and is typically called during [onSingletonReady] of
  /// [DefaultMethodInterceptor].
  ///
  /// ## Behavior
  /// 1. Logs the start of the interceptor configurer discovery process at INFO level.
  /// 2. Uses the pod factory to retrieve all pods of type [MethodInterceptorConfigurer]
  ///    from the `jetleaf.advice` package. Eager initialization is enabled to ensure
  ///    all configurers are instantiated before application.
  /// 3. If any configurers are found:
  ///    - Logs the number of discovered configurers at DEBUG level.
  ///    - Converts the pods into a list and sorts them using [AnnotationAwareOrderComparator]
  ///      to respect ordering annotations or priorities.
  ///    - Iterates through each configurer and calls [configure] on the current registry
  ///      instance, allowing configurers to register additional interceptors.
  ///    - Logs the total number of applied configurers at INFO level.
  /// 4. If no configurers are found, logs a message indicating none were discovered.
  ///
  /// This method ensures that all method interceptor configurers are discovered,
  /// sorted, and applied, allowing modular configuration of method interceptors
  /// within the application.
  ///
  /// @private
  /// @async
  /// @return Future that completes once all configurers are discovered and applied
  Future<void> _findAndCollectConfigurers() async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace("Loading Interceptors");
    }
    
    final type = Class<MethodInterceptorConfigurer>(null, PackageNames.CORE);
    final pods = await podFactory.getPodsOf(type, allowEagerInit: true);

    if (pods.isNotEmpty) {
      if (_logger.getIsDebugEnabled()) {
        _logger.debug("Found ${pods.length} MethodInterceptorConfigurer implementations");
      }
      
      final configurers = List<MethodInterceptorConfigurer>.from(pods.values);
      AnnotationAwareOrderComparator.sort(configurers);

      for (final configurer in configurers) {
        configurer.configure(this);
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace("Registered ${configurers.length} Interceptors");
      }
    } else {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace("No MethodInterceptorConfigurer implementations found");
      }
    }
  }

  @override
  List<MethodInterceptor> getMethodInterceptors() {
    // Use dependency graph sorting (topological)
    final sorted = _sortInterceptorsByRelations();
    return List.unmodifiable(sorted);
  }

  /// Sorts registered [MethodInterceptor]s based on declared
  /// `before` and `after` relationships.
  ///
  /// This algorithm performs a relaxed topological sort:
  /// - Interceptors that depend on others via `after` are deferred
  ///   until their dependencies are already sorted.
  /// - Interceptors that specify `before` are inserted before their targets
  ///   in the final list.
  /// - Throws [CircularDependencyException] with a detailed description if a
  ///   circular dependency or unresolvable graph is detected.
  ///
  /// The result is always a valid, deterministic list.
  List<MethodInterceptor> _sortInterceptorsByRelations() {
    final entries = _methodInterceptors.entries.toList();
    final interceptors = entries.map((e) => e.value).toList();

    String? podNameOf(MethodInterceptor i) => entries.find((e) => e.value == i)?.key;

    String nameOf(MethodInterceptor i) => podNameOf(i) ?? i.getClass().getQualifiedName();

    bool dependsAfter(MethodInterceptor i, MethodInterceptor j) {
      final r = _interceptorOrderCache[i];
      if (r == null) return false;
      final jName = podNameOf(j);
      final jCls = j.getClass();
      return r.afterNames.contains(jName) || r.afterTypes.contains(jCls);
    }

    bool dependsBefore(MethodInterceptor i, MethodInterceptor j) {
      final r = _interceptorOrderCache[i];
      if (r == null) return false;
      final jName = podNameOf(j);
      final jCls = j.getClass();
      return r.beforeNames.contains(jName) || r.beforeTypes.contains(jCls);
    }

    // Simplified topological sort
    final sorted = <MethodInterceptor>[];
    final remaining = interceptors.toSet();
    const maxPasses = 10000;
    var passes = 0;

    while (remaining.isNotEmpty && passes++ < maxPasses) {
      final ready = remaining.firstWhere(
        (i) => remaining.every((r) => !dependsAfter(i, r)),
        orElse: () {
          // Build diagnostic info
          final buffer = StringBuffer();
          buffer.writeln('Circular or unresolvable interceptor dependency detected:');
          buffer.writeln('Remaining interceptors (${remaining.length}):');

          for (final i in remaining) {
            final afters = remaining
                .where((r) => dependsAfter(i, r))
                .map(nameOf)
                .join(', ');
            final befores = remaining
                .where((r) => dependsBefore(i, r))
                .map(nameOf)
                .join(', ');

            buffer.writeln(' • ${nameOf(i)}');
            if (afters.isNotEmpty) buffer.writeln('     dependsAfter: [$afters]');
            if (befores.isNotEmpty) buffer.writeln('     dependsBefore: [$befores]');
          }

          buffer.writeln('\nThis typically indicates a circular dependency between interceptors.');
          throw CircularDependencyException(buffer.toString());
        },
      );

      // Insert based on 'before' relation if applicable
      final beforeTarget = sorted.find((s) => dependsBefore(ready, s));
      if (beforeTarget != null) {
        final index = sorted.indexOf(beforeTarget);
        sorted.insert(index, ready);
      } else {
        sorted.add(ready);
      }

      remaining.remove(ready);
    }

    // Safety catch if maxPasses exceeded (shouldn’t normally happen)
    if (remaining.isNotEmpty) {
      final unresolved = remaining.map(nameOf).join(', ');
      throw CircularDependencyException(
        'Sorting aborted after $maxPasses passes. '
        'Unresolved interceptors: [$unresolved]',
      );
    }

    return sorted;
  }

  @override
  MethodInterceptorDispatcher? getMethodInterceptorDispatcher() => _customMethodInterceptorDispatcher;
}

/// {@template jetleaf_interceptor_relations}
/// An internal model class that represents **explicit ordering relationships**
/// between interceptors, as declared by the
/// [`@RunBefore`](../annotations/run_before.dart) and
/// [`@RunAfter`](../annotations/run_after.dart) annotations.
///
/// This class is used internally by the JetLeaf dispatcher and interceptor
/// resolution subsystem to construct a **directed dependency graph** that
/// determines the execution order of interceptors during the request pipeline.
///
///
/// ### Overview
///
/// Each interceptor may declare that it should run *before* or *after* one or
/// more other interceptors. Those relationships are captured here in two forms:
///
/// - **By name** (`beforeNames`, `afterNames`) – used when referencing interceptors
///   registered as dependency injection pods or symbolic identifiers.
/// - **By type** (`beforeTypes`, `afterTypes`) – used when referencing interceptors
///   directly by Dart class type.
///
/// The JetLeaf ordering system uses this structure to compute a consistent and
/// deterministic interceptor chain via **topological sorting**.
///
///
/// ### Example
///
/// Suppose we have:
///
/// ```dart
/// @RunBefore([AuthInterceptor])
/// class LoggingInterceptor {}
///
/// @RunAfter([LoggingInterceptor])
/// class AuthInterceptor {}
/// ```
///
/// When parsed, the relationships for each interceptor might look like:
///
/// ```dart
/// final loggingRelations = _InterceptorRelations(
///   beforeTypes: [AuthInterceptor],
/// );
///
/// final authRelations = _InterceptorRelations(
///   afterTypes: [LoggingInterceptor],
/// );
/// ```
///
/// These relations are then used by the ordering engine to determine that:
///
/// ```text
/// LoggingInterceptor → AuthInterceptor
/// ```
///
/// ### Fields
///
/// - [beforeNames] → Interceptors (by pod name) that this one must execute **before**.
/// - [afterNames] → Interceptors (by pod name) that this one must execute **after**.
/// - [beforeTypes] → Interceptors (by Dart class type) that this one must execute **before**.
/// - [afterTypes] → Interceptors (by Dart class type) that this one must execute **after**.
///
///
/// ### See Also
///
/// - [RunBefore] – Declares interceptors that must run **before** others.
/// - [RunAfter] – Declares interceptors that must run **after** others.
///
///
/// ### Summary
///
/// `_InterceptorRelations` acts as a low-level metadata container connecting
/// declared interceptor relationships to JetLeaf’s runtime execution order
/// calculation system.
///
/// {@endtemplate}
class _InterceptorRelations {
  /// The list of **interceptor names (pod identifiers)** that this interceptor
  /// should run **before**.
  final List<String> beforeNames;

  /// The list of **interceptor names (pod identifiers)** that this interceptor
  /// should run **after**.
  final List<String> afterNames;

  /// The list of **interceptor class types** that this interceptor should run **before**.
  final List<Class> beforeTypes;

  /// The list of **interceptor class types** that this interceptor should run **after**.
  final List<Class> afterTypes;

  /// Creates a new [_InterceptorRelations] instance describing explicit
  /// ordering relationships for a given interceptor.
  ///
  /// All parameters default to empty lists when omitted.
  const _InterceptorRelations({
    this.beforeNames = const [],
    this.afterNames = const [],
    this.beforeTypes = const [],
    this.afterTypes = const [],
  });
}