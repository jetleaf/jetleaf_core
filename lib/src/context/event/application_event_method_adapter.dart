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

import 'application_event.dart';
import 'event_listener.dart';

/// {@template jetleaf_class_ApplicationEventAdapter}
/// An **adapter class** in Jetleaf that bridges [ApplicationEvent]s with listener methods.
///
/// This class dynamically resolves the target pod and invokes a listener
/// method when an event is published. It inspects method parameters and
/// injects values based on type:
///
/// - Supplies the [ApplicationEvent] itself if required.
/// - Assigns default values for primitive parameters.
/// - Resolves complex dependencies from a [PodFactory].
///
/// ### Example
///
/// ```dart
/// // Assume we have a custom ApplicationEvent
/// class UserCreatedEvent extends ApplicationEvent {
///   final String userId;
///   UserCreatedEvent(this.userId);
/// }
///
/// // A pod class with an event handler method
/// class UserEventHandler {
///   void handleUserCreated(UserCreatedEvent event) {
///     print('User created with ID: ${event.userId}');
///   }
/// }
///
/// // Register the adapter
/// final podFactory = MyPodFactory();
/// final method = Method(UserEventHandler, 'handleUserCreated');
/// final adapter = ApplicationEventMethodAdapter(
///   Class<UserCreatedEvent>(),
///   'userEventHandlerPod',
///   method,
///   podFactory,
/// );
///
/// // Later, when the event is published, the adapter will:
/// // - resolve the `UserEventHandler` pod
/// // - inject the `UserCreatedEvent`
/// // - invoke `handleUserCreated`
/// await adapter.onApplicationEvent(UserCreatedEvent('abc123'));
/// ```
///
/// {@endtemplate}
class ApplicationEventMethodAdapter implements ApplicationEventListener<ApplicationEvent>, Ordered {
  /// {@template aema_event_class}
  /// The expected [ApplicationEvent] class type for this adapter.
  ///
  /// If `null`, the adapter listens to all event types. If non-null,
  /// only events assignable to this type are accepted.
  /// {@endtemplate}
  final Class? _eventClass;

  /// {@template aema_method}
  /// The listener method to be invoked when a matching event occurs.
  ///
  /// The method signature may include:
  /// - An [ApplicationEvent] (or subtype) parameter.
  /// - Primitive parameters with default values.
  /// - Other dependencies resolvable through the [PodFactory].
  /// {@endtemplate}
  final Method _method;

  /// {@template aema_pod_name}
  /// The name of the pod that contains the listener method.
  ///
  /// The adapter uses this name to lazily resolve the pod instance
  /// from the [PodFactory] at event publication time.
  /// {@endtemplate}
  final String _podName;

  /// {@template aema_pod_factory}
  /// A [PodFactory] used to resolve pods and other dependencies.
  ///
  /// It provides runtime resolution of listener targets and method
  /// arguments, ensuring that dependencies are injected dynamically.
  /// {@endtemplate}
  final ConfigurableListablePodFactory _podFactory;

  /// {@macro application_event_method_adapter}
  ApplicationEventMethodAdapter(this._eventClass, this._podName, this._method, this._podFactory);

  @override
  Future<void> onApplicationEvent(ApplicationEvent event) async {
    if (!supportsEventOf(event)) {
      return;
    }

    // Resolve the pod instance (listener target). We do this lazily so that
    // pods that are not available at registration time are resolved at publish time.
    final target = await _podFactory.getPod(_podName);

    // Build positional arguments for the method invocation.
    final params = _method.getParameters();
    final List<Object?> positionalArgs = List<Object?>.filled(params.length, null);
    final Map<String, Object?> namedArgs = {};

    for (int i = 0; i < params.length; i++) {
      final param = params[i];
      final paramClass = param.getReturnClass();

      // 1) If parameter expects an ApplicationEvent (or subtype) -> pass the actual event instance
      if (paramClass.isAssignableTo(Class<ApplicationEvent>(null, PackageNames.CORE))) {
        if (param.isPositional()) {
          positionalArgs[i] = event;
        } else {
          namedArgs[param.getName()] = event;
        }
        continue;
      }

      // 2) Primitive-ish types -> do NOT resolve from pod factory
      if (paramClass.isPrimitive()) {
        // Leave as null (or optionally attempt to map from event payload)
        if (param.isPositional()) {
          positionalArgs[i] = param.getDefaultValue();
        } else {
          namedArgs[param.getName()] = param.getDefaultValue();
        }
        continue;
      }

      // 3) Non-primitive -> try resolving from PodFactory by type
      try {
        final resolved = await _podFactory.get(paramClass);
        if (param.isPositional()) {
          positionalArgs[i] = resolved;
        } else {
          namedArgs[param.getName()] = resolved;
        }
      } catch (err) {
        // Not resolvable: optionally log and leave null.
        // print('Could not resolve parameter ${param.getName()} of type ${paramClass.getName()}: $err');
        if (param.isPositional()) {
          positionalArgs[i] = param.getDefaultValue();
        } else {
          namedArgs[param.getName()] = param.getDefaultValue();
        }
      }
    }

    _method.invoke(target, namedArgs, positionalArgs);
  }

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE;

  @override
  bool supportsEventOf(ApplicationEvent event) {
    if (_eventClass == null) {
      return true;
    }

    return _eventClass.isAssignableFrom(event.getClass(null, event.getPackageName()));
  }
}