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
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../../annotations/lifecycle.dart';
import '../../aware.dart';
import '../application_context.dart';
import '../core/abstract_application_context.dart';
import '../event/application_event.dart';
import '../event/application_event_method_adapter.dart';
import '../helpers.dart';

/// {@template jetleaf_class_EventListenerMethodProcessor}
/// A **Jetleaf lifecycle processor** that scans pods for methods
/// annotated with [EventListener] and registers them as event listeners.
///
/// This processor integrates into the application context lifecycle:
///
/// - It implements [SmartInitializingSingleton] so that it runs after all
///   singletons are initialized.
/// - It implements [PodFactoryPostProcessor] to capture a reference to the
///   [ConfigurableListablePodFactory].
/// - It implements [ApplicationContextAware] to receive the active
///   [ApplicationContext].
///
/// ### Responsibilities
///
/// - Iterates over all pods managed by the [PodFactory].
/// - Inspects methods annotated with [EventListener].
/// - Determines the event type either from the annotation or from the
///   method parameter type.
/// - Wraps each discovered listener method in an
///   [ApplicationEventMethodAdapter].
/// - Registers the adapter with the [ApplicationContext].
///
/// ### Example
///
/// ```dart
/// // Define a custom event
/// class OrderPlacedEvent extends ApplicationEvent {
///   final String orderId;
///   OrderPlacedEvent(this.orderId);
/// }
///
/// // Define a pod with an event listener method
/// class OrderService {
///   @EventListener()
///   void onOrderPlaced(OrderPlacedEvent event) {
///     print('Order placed: ${event.orderId}');
///   }
/// }
///
/// // When the context initializes, the EventListenerMethodProcessor will:
/// // - discover the `onOrderPlaced` method
/// // - determine that it listens to OrderPlacedEvent
/// // - register it via an ApplicationEventMethodAdapter
/// ```
///
/// {@endtemplate}
final class EventListenerMethodProcessor implements PodFactoryPostProcessor, ApplicationContextAware {
  /// {@template elmp_application_context}
  /// The current [ApplicationContext] for this processor.
  ///
  /// Injected via [ApplicationContextAware.setApplicationContext].
  /// Used to register [ApplicationEventMethodAdapter]s with the context.
  /// {@endtemplate}
  late ApplicationContext _applicationContext;

  /// {@template elmp_logger}
  /// A [Log] instance for emitting debug and diagnostic information
  /// about discovered event listeners.
  /// {@endtemplate}
  final Log _logger = LogFactory.getLog(EventListenerMethodProcessor);

  /// {@macro jetleaf_class_EventListenerMethodProcessor}
  EventListenerMethodProcessor();

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    final podNames = podFactory.getDefinitionNames();
    
    for (final podName in podNames) {
      final def = podFactory.getDefinition(podName);
      final cls = def.type;
      final methods = cls.getMethods().where((m) => m.hasDirectAnnotation<EventListener>());

      for (final method in methods) {
        if (!method.hasDirectAnnotation<EventListener>()) {
          continue;
        }

        final listener = method.getDirectAnnotation<EventListener>();
        final parameter = method.getParameters().find((p) => p.getClass().isAssignableTo(Class<ApplicationEvent>(null, PackageNames.CORE)));
        final eventClass = _determineFromAnnotation(listener) ?? parameter?.getClass();
        
        if (_logger.getIsTraceEnabled()) {
          _logger.trace("Adding event listener method '${method.getName()}' of class ${method.getDeclaringClass().getName()} - ${method.getDeclaringClass().getQualifiedName()}");
        }

        if (_applicationContext is AbstractApplicationContext) {
          (_applicationContext as AbstractApplicationContext).addApplicationListener(ApplicationEventMethodAdapter(eventClass, podName, method, podFactory));
        }
      }
    }
  }

  /// Determines the event type from the [EventListener] annotation.
  /// 
  /// {@macro event_type}
  Class? _determineFromAnnotation(EventListener? listener) {
    if (listener != null) {
      final event = listener.event;

      if (event != null) {
        return event.getType();
      }
    }

    return null;
  }
}