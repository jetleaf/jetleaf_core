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
/// Default implementation of [LifecycleProcessor] that manages
/// the discovery, startup, and shutdown of [Lifecycle] and
/// [SmartLifecycle] pods in the application context.
///
/// It uses a [ConfigurableListablePodFactory] to find pods
/// that implement the [Lifecycle] contract and controls
/// their lifecycle phases.
///
/// ### Behavior
/// - **Startup (`onRefresh`)**
///   - Discovers all [Lifecycle] pods from the pod factory.
///   - Starts [SmartLifecycle] pods first, ordered by their
///     [SmartLifecycle.getPhase] (lowest phase starts first).
///   - Starts regular [Lifecycle] pods afterwards.
/// - **Shutdown (`onClose`)**
///   - Stops all [Lifecycle] pods in reverse order.
///   - For [SmartLifecycle] pods, ensures async shutdown
///     is completed via a [_AsyncRunnable].
///
/// ### Example
/// ```dart
/// final processor = DefaultLifecycleProcessor(podFactory);
///
/// // Start lifecycle pods
/// processor.onRefresh();
///
/// // Later, when shutting down
/// await processor.onClose();
/// ```
/// {@endtemplate}
class DefaultLifecycleProcessor implements LifecycleProcessor {
  final ConfigurableListablePodFactory? _podFactory;

  /// {@macro default_lifecycle_processor}
  DefaultLifecycleProcessor(this._podFactory) {
    _discoverLifecyclePods();
  }

  List<Lifecycle> _lifecycles = [];
  bool _running = false;

  /// {@template default_lifecycle_processor_discover}
  /// Discovers all pods from the pod factory that implement [Lifecycle].
  ///
  /// This is used internally by [onRefresh] to initialize the
  /// list of lifecycle-managed pods.
  /// {@endtemplate}
  Future<List<Lifecycle>> _discoverLifecyclePods() async {
    final list = <Lifecycle>[];
    
    final lc = Class<Lifecycle>(null, PackageNames.CORE);
    final names = await _podFactory?.getPodNames(lc, includeNonSingletons: true, allowEagerInit: true) ?? [];
    if (names.isNotEmpty) {
      for (final n in names) {
        if(_podFactory != null) {
          final pod = await _podFactory.getPod(n);
          list.add(pod);
        }
      }
    }

    return list;
  }
  
  @override
  Future<void> onClose() async {
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
  void onRefresh() async {
    // Discover lifecycle pods
    _lifecycles.clear();
    _lifecycles.addAll(await _discoverLifecyclePods());

    AnnotationAwareOrderComparator.sort(_lifecycles);

    final smart = _lifecycles.where((l) => l is SmartLifecycle).toList();

    // Sort by phase (lowest first)
    smart.sort((a, b) => (a as SmartLifecycle).getPhase().compareTo((b as SmartLifecycle).getPhase()));
    smart.process((s) async {
      final sl = s as SmartLifecycle;
      if(sl.isAutoStartup()) {
        await sl.start();
      }
    });

    final nsmart = _lifecycles.where((l) => l is! SmartLifecycle).toList();
    nsmart.process((s) async => await s.start());

    _running = true;
  }
}

/// {@template default_lifecycle_processor_async_runnable}
/// Internal adapter used to complete a [Completer] once a
/// [SmartLifecycle] asynchronous shutdown is finished.
/// {@endtemplate}
final class _AsyncRunnable implements Runnable {
  final Completer _completer;

  /// {@macro default_lifecycle_processor_async_runnable}
  _AsyncRunnable(this._completer);

  @override
  FutureOr<void> run() async => _completer.complete();
}