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

import '../base/helpers.dart';

/// {@template podPostProcessorManager}
/// Manager for coordinating pod factory post-processors and pod-aware processors
/// with proper ordering and lifecycle management.
///
/// This manager handles the discovery, sorting, and invocation of post-processors
/// and registration of pod-aware processors according to their priority and order.
/// It ensures that processors are executed in the correct sequence based on their
/// implemented ordering interfaces ([PriorityOrdered], [Ordered]).
///
/// **Processing Order:**
/// 1. **PriorityOrdered** processors (highest priority first)
/// 2. **Ordered** processors (by order value)
/// 3. **Regular** processors (no specific order)
///
/// **Supported Processor Types:**
/// - [PodFactoryPostProcessor]: For post-processing the pod factory itself
/// - [PodFactoryPostProcessor]: For processing individual pods during creation
///
/// **Example:**
/// ```dart
/// final podFactory = DefaultListablePodFactory();
/// final manager = PodPostProcessorManager(podFactory);
///
/// // Invoke all post-processors (discovered + provided)
/// await manager.invoke([customPostProcessor]);
///
/// // Register all pod-aware processors
/// await manager.register();
///
/// // Pod factory is now fully configured with all processors
/// ```
/// {@endtemplate}
final class PodPostProcessorManager {
  /// {@macro configurablePodFactory}
  /// The configurable pod factory to manage processors for.
  final ConfigurableListablePodFactory pf;

  /// {@macro podPostProcessorManager}
  /// Creates a new pod post processor manager for the given pod factory.
  ///
  /// **Parameters:**
  /// - `pf`: The configurable pod factory to manage processors for
  ///
  /// **Example:**
  /// ```dart
  /// final factory = DefaultListablePodFactory();
  /// final manager = PodPostProcessorManager(factory);
  /// ```
  PodPostProcessorManager(this.pf);

  /// {@macro invokePostProcessors}
  /// Invokes all pod factory post-processors in the correct order.
  ///
  /// This method processes both provided processors and discovered processors
  /// from the pod factory, ensuring proper ordering based on priority and order
  /// annotations. Processors are executed in three phases:
  ///
  /// 1. **PriorityOrdered**: Highest priority processors first
  /// 2. **Ordered**: Processors with explicit order values
  /// 3. **Regular**: Processors without specific ordering
  ///
  /// **Parameters:**
  /// - `processors`: Optional list of additional processors to invoke
  ///
  /// **Example:**
  /// ```dart
  /// await manager.invoke([
  ///   HighPriorityPostProcessor(),
  ///   RegularPostProcessor()
  /// ]);
  /// ```
  Future<void> invokePodFactoryPostProcessor([List<PodFactoryPostProcessor> processors = const []]) async {
    final cls = Class<PodFactoryPostProcessor>(null, PackageNames.CORE);
    final names = await pf.getPodNames(cls, includeNonSingletons: true, allowEagerInit: false);

    final simpleNames = <String>[];
    final prioritizedProcessors = <PodFactoryPostProcessor>[];
    final orderedNames = <String>[];

    for (final name in names) {
      if (await pf.isTypeMatch(name, Class<PriorityOrdered>(null, PackageNames.LANG))) {
        final processor = await pf.getPod<PodFactoryPostProcessor>(name);
        if (processor is PriorityOrdered) {
          prioritizedProcessors.add(processor);
        }
      } else if (await pf.isTypeMatch(name, Class<Ordered>(null, PackageNames.LANG))) {
        orderedNames.add(name);
      } else {
        simpleNames.add(name);
      }
    }

    // Process prioritized processors
    if (prioritizedProcessors.isNotEmpty) {
      await _applySorting(prioritizedProcessors);
      await _invoke(prioritizedProcessors);
    }

    // Process ordered processors
    if (orderedNames.isNotEmpty) {
      final orderedProcessors = <PodFactoryPostProcessor>[];
      for (final name in orderedNames) {
        final processor = await pf.getPod<PodFactoryPostProcessor>(name, null, cls);
        orderedProcessors.add(processor);
      }

      await _applySorting(orderedProcessors);
      await _invoke(orderedProcessors);
    }

    // Process simple processors
    if (simpleNames.isNotEmpty) {
      final simpleProcessors = <PodFactoryPostProcessor>[];
      for (final name in simpleNames) {
        final processor = await pf.getPod<PodFactoryPostProcessor>(name, null, cls);
        simpleProcessors.add(processor);
      }

      await _invoke(simpleProcessors);
    }

    await _invoke(processors);
  }

  /// {@macro invokeProcessorList}
  /// Invokes a list of pod factory post-processors.
  Future<void> _invoke(List<PodFactoryPostProcessor> processors) async {
    for (final processor in processors) {
      await processor.postProcessFactory(pf);
    }
  }

  /// {@macro applyProcessorSorting}
  /// Applies sorting to a list of processors based on their order.
  Future<void> _applySorting(List<Object> processors) async {
    Comparator<Object>? comparator;
    if (pf is DefaultListablePodFactory) {
      final comp = (pf as DefaultListablePodFactory).getDependencyComparator();
      if (comp != null) {
        comparator = comp;
      }
    }

    comparator ??= OrderComparator.INSTANCE;
    processors.sort(comparator.compare);
  }

  /// {@macro registerPodProcessors}
  /// Registers all pod-aware processors with the pod factory in the correct order.
  ///
  /// This method discovers and registers pod-aware processors from the pod factory,
  /// ensuring they are added in the proper order based on priority and order annotations.
  /// Processors are registered in three phases:
  ///
  /// 1. **PriorityOrdered**: Highest priority processors first
  /// 2. **Ordered**: Processors with explicit order values
  /// 3. **Regular**: Processors without specific ordering
  ///
  /// **Example:**
  /// ```dart
  /// await manager.register();
  /// // All pod-aware processors are now registered with the factory
  /// ```
  Future<void> registerPodProcessors() async {
    final cls = Class<PodProcessor>(null, PackageNames.CORE);
    final names = await pf.getPodNames(cls, includeNonSingletons: true, allowEagerInit: false);

    final simpleNames = <String>[];
    final prioritizedProcessors = <PodProcessor>[];
    final orderedNames = <String>[];

    for (final name in names) {
      if (await pf.isTypeMatch(name, Class<PriorityOrdered>(null, PackageNames.LANG))) {
        final processor = await pf.getPod(name);
        if (processor is PodProcessor) {
          if (processor is PriorityOrdered) {
            prioritizedProcessors.add(processor);
          }
        }
      } else if (await pf.isTypeMatch(name, Class<Ordered>(null, PackageNames.LANG))) {
        orderedNames.add(name);
      } else {
        simpleNames.add(name);
      }
    }

    // Process prioritized processors
    if (prioritizedProcessors.isNotEmpty) {
      await _applySorting(prioritizedProcessors);
      await _register(prioritizedProcessors);
    }

    // Process ordered processors
    if (orderedNames.isNotEmpty) {
      final orderedProcessors = <PodProcessor>[];
      for (final name in orderedNames) {
        final processor = await pf.getPod(name, null, cls);
        orderedProcessors.add(processor);
      }

      await _applySorting(orderedProcessors);
      await _register(orderedProcessors);
    }

    // Process simple processors
    if (simpleNames.isNotEmpty) {
      final simpleProcessors = <PodProcessor>[];
      for (final name in simpleNames) {
        final processor = await pf.getPod(name, null, cls);
        simpleProcessors.add(processor);
      }

      await _register(simpleProcessors);
    }
  }

  /// {@macro registerProcessorList}
  /// Registers a list of pod-aware processors with the pod factory.
  Future<void> _register(List<PodProcessor> processors) async {
    for (final processor in processors) {
      pf.addPodProcessor(processor);
    }
  }
}

/// {@macro configurablePodFactory}
/// Configurable pod factory for processor management.
///
/// This template documents the pod factory instance that is managed
/// by the post processor manager.
/// {@endtemplate}

/// {@macro invokePostProcessors}
/// Post processor invocation with proper ordering.
///
/// This template documents the process of invoking pod factory
/// post-processors in the correct priority sequence.
/// {@endtemplate}

/// {@macro invokeProcessorList}
/// Processor list invocation operation.
///
/// This template documents the internal method for invoking
/// a list of post-processors on the pod factory.
/// {@endtemplate}

/// {@macro applyProcessorSorting}
/// Processor sorting application.
///
/// This template documents the process of sorting processors
/// based on their order and priority.
/// {@endtemplate}

/// {@macro registerPodProcessors}
/// Pod-aware processor registration with ordering.
///
/// This template documents the process of registering pod-aware
/// processors with the pod factory in proper sequence.
/// {@endtemplate}

/// {@macro registerProcessorList}
/// Processor list registration operation.
///
/// This template documents the internal method for registering
/// a list of pod-aware processors with the pod factory.
/// {@endtemplate}
