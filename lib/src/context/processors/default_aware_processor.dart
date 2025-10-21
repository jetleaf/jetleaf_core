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

import '../../aware.dart';
import '../application_context.dart';
import '../core/abstract_application_context.dart';

/// {@template jetleaf_class_DefaultAwareProcessor}
/// 🫘 Default processor that injects JetLeaf "aware" contracts into pods.
///
/// [DefaultAwareProcessor] extends [PodProcessor] and implements
/// [PriorityOrdered], ensuring it runs at the highest precedence during
/// pod initialization.
///
/// ## Responsibilities
///
/// - Checks if a newly created pod implements any of the `*Aware` contracts,
///   and injects the corresponding dependency:
///   - [EnvironmentAware] → injects the current [Environment].
///   - [ApplicationContextAware] → injects the [ApplicationContext].
///   - [PodFactoryAware] → injects the [PodFactory].
///   - [PodNameAware] → injects the pod’s registration name.
///   - [ConversionServiceAware] → injects the [ConversionService].
///   - [MessageSourceAware] → injects the [MessageSource] (if available).
///   - [ApplicationEventBusAware] → injects the [ApplicationEventBus] (if available).
///
/// ## Ordering
///
/// This processor declares [Ordered.HIGHEST_PRECEDENCE], ensuring it runs
/// before other processors that may rely on these aware dependencies.
///
/// ## Example
///
/// ```dart
/// final context = MyApplicationContext();
/// final processor = DefaultAwareProcessor(context);
///
/// // When the pod factory creates a new pod, the processor ensures
/// // that any implemented Aware interfaces are populated.
/// ```
///
/// See also:
/// - [PodProcessor] 🫘 base class for processors.
/// - [PriorityOrdered] 🫘 for ordering processors.
/// - [PodInitializationProcessor] 🫘 for initialization-specific processing.
/// - [AbstractApplicationContext] 🫘 for extended context features.
///
/// {@endtemplate}
final class DefaultAwareProcessor extends PodInitializationProcessor implements PriorityOrdered {
  /// The application context this processor uses for dependency injection.
  final ApplicationContext applicationContext;

  /// Creates a new [DefaultAwareProcessor] bound to the given [applicationContext].
  ///
  /// {@macro jetleaf_class_DefaultAwareProcessor}
  DefaultAwareProcessor(this.applicationContext);

  @override
  int getOrder() => Ordered.HIGHEST_PRECEDENCE;

  @override
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async => true;

  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    final podFactory = applicationContext.getPodFactory();
    final instance = pod;

    if (instance is EnvironmentAware) {
      instance.setEnvironment(applicationContext.getEnvironment());
    }

    if (instance is ApplicationContextAware) {
      instance.setApplicationContext(applicationContext);
    }

    if (instance is EntryApplicationAware) {
      instance.setEntryApplication(applicationContext.getMainApplicationClass());
    }

    if (instance is PodFactoryAware) {
      instance.setPodFactory(podFactory);
    }

    if (instance is PodNameAware) {
      instance.setPodName(name);
    }

    if (instance is ConversionServiceAware) {
      instance.setConversionService(podFactory.getConversionService());
    }

    if (applicationContext is ConfigurableApplicationContext) {
      final aac = applicationContext as ConfigurableApplicationContext;

      if (instance is MessageSourceAware) {
        instance.setMessageSource(aac.getMessageSource());
      }

      if (instance is ApplicationEventBusAware) {
        instance.setApplicationEventBus(aac.getApplicationEventBus());
      }
    }

    return instance;
  }
}