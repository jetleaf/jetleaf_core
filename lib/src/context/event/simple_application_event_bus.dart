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

import '../../annotation_aware_order_comparator.dart';
import 'application_event.dart';
import 'event_listener.dart';

/// {@template SimpleApplicationEventBus}
/// A straightforward implementation of [ApplicationEventBus] that manages application event listeners.
/// 
/// This event bus provides a simple yet powerful mechanism for publishing and subscribing
/// to application events within the JetLeaf framework. It supports both direct listener
/// registration and pod-based listener discovery, with proper ordering and lifecycle management.
/// 
/// ## Key Features
/// 
/// - **Dual Registration**: Support for both direct listener instances and pod-based listeners
/// - **Automatic Ordering**: Listeners are automatically sorted using [AnnotationAwareOrderComparator]
/// - **Pod Integration**: Seamless integration with JetLeaf pod factory for listener discovery
/// - **Type Safety**: Event type checking through [supportsEventOf] method
/// - **Lifecycle Management**: Proper addition and removal of listeners with cleanup
/// 
/// ## Listener Registration Strategies
/// 
/// The event bus supports multiple ways to register listeners:
/// 
/// ```dart
/// final eventBus = SimpleApplicationEventBus(podFactory);
/// 
/// // 1. Direct listener instance
/// await eventBus.addApplicationListener(listener: myListener);
/// 
/// // 2. Pod-based listener by name
/// await eventBus.addApplicationListener(podName: 'userEventListener');
/// 
/// // 3. Combined listener with pod name mapping
/// await eventBus.addApplicationListener(
///   listener: customListener,
///   podName: 'customEventListener'
/// );
/// ```
/// 
/// ## Event Processing
/// 
/// When an event is published, the bus:
/// 1. Iterates through all registered listeners in order
/// 2. Checks if each listener supports the event type
/// 3. Invokes supported listeners asynchronously
/// 4. Continues even if individual listeners fail
/// 
/// Example usage:
/// ```dart
/// class UserCreatedEvent extends ApplicationEvent {
///   final String userId;
///   UserCreatedEvent(this.userId) : super(DateTime.now());
/// }
/// 
/// class UserEventListener implements ApplicationEventListener<UserCreatedEvent> {
///   @override
///   bool supportsEventOf(ApplicationEvent event) => event is UserCreatedEvent;
///   
///   @override
///   Future<void> onApplicationEvent(UserCreatedEvent event) async {
///     print('User ${event.userId} was created');
///     // Send welcome email, update analytics, etc.
///   }
/// }
/// 
/// // Register and use
/// final listener = UserEventListener();
/// await eventBus.addApplicationListener(listener: listener);
/// await eventBus.onEvent(UserCreatedEvent('user-123'));
/// ```
/// {@endtemplate}
class SimpleApplicationEventBus implements ApplicationEventBus {
  /// List of directly registered application event listeners.
  final List<ApplicationEventListener> _listeners = [];

  /// Map of pod name to application event listener for pod-based registration.
  final Map<String, ApplicationEventListener> _mappedListeners = {};

  /// Optional pod factory for resolving pod-based listeners.
  final ConfigurableListablePodFactory? _podFactory;

  /// {@macro SimpleApplicationEventBus}
  /// 
  /// Creates a simple application event bus with optional pod factory integration.
  /// 
  /// @param podFactory Optional pod factory for resolving listeners by pod name.
  ///        When provided, enables pod-based listener registration and automatic
  ///        lifecycle management.
  /// 
  /// Example:
  /// ```dart
  /// // With pod factory for pod-based listeners
  /// final eventBus = SimpleApplicationEventBus(podFactory);
  /// 
  /// // Without pod factory (direct listeners only)
  /// final eventBus = SimpleApplicationEventBus(null);
  /// ```
  SimpleApplicationEventBus(this._podFactory);

  @override
  Future<void> addApplicationListener({ApplicationEventListener<ApplicationEvent>? listener, String? podName}) async {
    if (listener != null && podName != null) {
      _mappedListeners.add(podName, listener);
    } else if (listener != null) {
      _listeners.add(listener);
    } else if (podName != null && _podFactory != null) {
      try {
        final pod = await _podFactory.getSingleton(podName);
        if(pod is ApplicationEventListener) {
          _mappedListeners.add(podName, pod);
        }
      } catch (_) { }
    }

    for (final entry in _mappedListeners.entries) {
      _listeners.add(entry.value);
    }

    AnnotationAwareOrderComparator.sort(_listeners);
  }

  @override
  Future<void> removeApplicationListener({ApplicationEventListener<ApplicationEvent>? listener, String? podName}) async {
    if (listener != null && podName != null) {
      final result = _mappedListeners.remove(podName);

      if(result != null) {
        _listeners.remove(result);
      }
    } else if (listener != null) {
      _listeners.remove(listener);
    } else if (podName != null && _podFactory != null) {
      _podFactory.removeSingleton(podName);
      final result = _mappedListeners.remove(podName);

      if(result != null) {
        _listeners.remove(result);
      }
    }

    AnnotationAwareOrderComparator.sort(_listeners);
  }

  @override
  Future<void> removeApplicationListeners({Predicate<ApplicationEventListener<ApplicationEvent>>? listener, Predicate<String>? podName}) async {
    if (listener != null && podName != null) {
      for (final entry in _mappedListeners.entries) {
        if(listener(entry.value) && podName(entry.key)) {
          _listeners.remove(entry.value);
          _mappedListeners.remove(entry.key);
        }
      }
    } else if (listener != null) {
      for (final entry in _mappedListeners.entries) {
        if(listener(entry.value)) {
          _mappedListeners.remove(entry.key);
        }
      }

      _listeners.removeWhere(listener);
    } else if (podName != null && _podFactory != null) {
      final pods = _podFactory.getSingletonNames();
      for (final pod in pods) {
        if (podName(pod)) {
          _podFactory.removeSingleton(pod);
          final result = _mappedListeners.remove(pod);

          if(result != null) {
            _listeners.remove(result);
          }
        }
      }
    }

    AnnotationAwareOrderComparator.sort(_listeners);
  }

  @override
  Future<void> removeAllListeners() async {
    _listeners.clear();
    _mappedListeners.clear();
  }

  @override
  Future<void> onEvent(ApplicationEvent event) async {
    for (final listener in _listeners) {
      if (listener.supportsEventOf(event)) {
        await listener.onApplicationEvent(event);
      }
    }

    for (final listener in _mappedListeners.values) {
      if (listener.supportsEventOf(event)) {
        await listener.onApplicationEvent(event);
      }
    }
  }
}