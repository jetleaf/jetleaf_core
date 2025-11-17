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
import 'package:jetleaf_pod/pod.dart';

import '../../annotation_aware_order_comparator.dart';
import 'lifecycle.dart';
import 'lifecycle_processor.dart';

/// {@template default_lifecycle_processor}
/// Default implementation of [LifecycleProcessor] that manages the lifecycle of pods.
///
/// This processor discovers and manages pods that implement [Lifecycle] or [SmartLifecycle],
/// handling initialization and shutdown in a coordinated manner. It supports ordered
/// lifecycle management and async shutdown operations for proper application lifecycle control.
///
/// **Key Features:**
/// - Automatic discovery of lifecycle-managed pods
/// - Ordered startup and shutdown based on phase and priority
/// - Support for async lifecycle operations via [SmartLifecycle]
/// - Integration with [ConfigurableListablePodFactory] for pod discovery
///
/// **Lifecycle Order:**
/// - **Startup**: SmartLifecycle pods sorted by phase (lowest first), auto-startup only
/// - **Shutdown**: All lifecycle pods in reverse discovery order
///
/// **Example:**
/// ```dart
/// final podFactory = DefaultPodFactory();
/// final processor = DefaultLifecycleProcessor(podFactory);
///
/// // Initialize and discover lifecycle pods
/// await processor.onRefresh();
///
/// // Application runs...
///
/// // Graceful shutdown
/// await processor.onClose();
/// ```
/// {@endtemplate}
class DefaultLifecycleProcessor implements LifecycleProcessor {
  final ConfigurableListablePodFactory? _podFactory;

  /// {@macro default_lifecycle_processor}
  DefaultLifecycleProcessor(this._podFactory);

  /// Collection of discovered lifecycle-managed pods.
  ///
  /// This template documents the internal storage for pods
  /// that implement lifecycle interfaces.
  /// 
  /// List of discovered lifecycle-managed pods.
  final List<Lifecycle> _lifecycles = [];

  /// Lifecycle processor running state flag.
  ///
  /// This template documents the flag that tracks whether
  /// the lifecycle processor is actively managing lifecycles.
  /// 
  /// Flag indicating whether the processor is currently running.
  bool _running = false;

  /// {@macro default_lifecycle_processor_discover}
  /// Discovers all pods from the pod factory that implement [Lifecycle].
  ///
  /// This method scans the pod factory for pods implementing the [Lifecycle] interface
  /// and stores them internally. The discovered lifecycle pods are then sorted
  /// according to their declared order for proper lifecycle management sequence.
  ///
  /// **Internal Usage:**
  /// This method is used internally by [onRefresh] to initialize the
  /// list of lifecycle-managed pods.
  ///
  /// **Example (Internal):**
  /// ```dart
  /// final processor = DefaultLifecycleProcessor(podFactory);
  /// await processor.discover(); // Internal discovery
  /// await processor.onRefresh(); // Starts discovered lifecycles
  /// ```
  Future<void> _discover() async {
    if (_podFactory != null) {
      final lc = Class<Lifecycle>(null, PackageNames.CORE);
      final pods = await _podFactory.getPodsOf(lc);
      _lifecycles.addAll(pods.values);
    }

    AnnotationAwareOrderComparator.sort(_lifecycles);
  }
  
  @override
  Future<void> onClose() async {
    if (_lifecycles.isEmpty) {
      await _discover();
    }

    if (!_running) return;

    // Stop in reverse order
    for (final lc in _lifecycles.reversed) {
      if (lc is SmartLifecycle) {
        final completer = Completer<void>();
        await lc.stop(_AsyncRunnable(completer));
        await completer.future;
      } else {
        await lc.stop();
      }
    }

    _running = false;
  }

  @override
  Future<void> onRefresh() async {
    if (_lifecycles.isEmpty) {
      await _discover();
    }

    final smart = <SmartLifecycle>[];
    final nsmart = <Lifecycle>[];
    
    for (final lc in _lifecycles) {
      if (lc is SmartLifecycle) {
        smart.add(lc);
      } else {
        nsmart.add(lc);
      }
    }

    // Sort by phase (lowest first)
    smart.sort((a, b) => a.getPhase().compareTo(b.getPhase()));

    for (final s in smart) {
      if(s.isAutoStartup()) {
        await s.start();
      }
    }

    _running = true;
  }
}

/// {@template default_lifecycle_processor_async_runnable}
/// Internal runnable implementation for completing async lifecycle operations.
///
/// This private class implements the [Runnable] interface to provide a simple
/// mechanism for completing [Completer] instances as part of asynchronous
/// lifecycle processing. It's used internally by lifecycle processors to
/// coordinate async initialization and destruction sequences.
///
/// **Internal Usage Only:**
/// This class is designed for internal framework use and should not be
/// used directly by application code. It provides the bridge between
/// synchronous runnable interfaces and asynchronous completion patterns.
///
/// **Example (Internal Framework Usage):**
/// ```dart
/// // Internal lifecycle processor implementation
/// class DefaultLifecycleProcessor {
///   Future<void> _executeAsyncShutdown() async {
///     final completer = Completer<void>();
///     final runnable = _AsyncRunnable(completer);
///     
///     // Schedule the runnable for execution
///     await _executor.execute(runnable);
///     
///     // Wait for completion
///     await completer.future;
///   }
/// }
/// ```
/// {@endtemplate}
final class _AsyncRunnable implements Runnable {
  /// {@macro asyncRunnableCompleter}
  /// The completer that will be completed when this runnable executes.
  final Completer _completer;

  /// {@macro default_lifecycle_processor_async_runnable}
  /// Creates a new async runnable that will complete the given completer.
  ///
  /// **Parameters:**
  /// - `_completer`: The completer to complete when this runnable is executed
  ///
  /// **Internal Usage:**
  /// ```dart
  /// // Internal framework usage pattern
  /// final completer = Completer<void>();
  /// final runnable = _AsyncRunnable(completer);
  /// 
  /// // Execute the runnable (completes the completer)
  /// await runnable.run();
  /// // completer is now completed
  /// ```
  _AsyncRunnable(this._completer);

  @override
  FutureOr<void> run() async => _completer.complete();
}