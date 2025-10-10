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

/// {@template simple_application_event_bus}
/// A simple implementation of [ApplicationEventBus] that manages application
/// event listeners and dispatches events to them.
///
/// This bus supports two kinds of listeners:
/// - **Unmapped listeners**: Directly registered listeners stored in an internal list.
/// - **Mapped listeners**: Listeners associated with a specific pod name,
///   managed via the [ConfigurableListablePodFactory].
///
/// It allows adding, removing, and clearing listeners, as well as
/// dispatching events to those that support the given event type.
///
/// ### Example
/// ```dart
/// final podFactory = MyPodFactory();
/// final bus = SimpleApplicationEventBus(podFactory);
///
/// // Add a listener directly
/// bus.addApplicationListener(listener: MyEventListener());
///
/// // Add a listener by pod name
/// bus.addApplicationListener(podName: "myEventListenerPod");
///
/// // Dispatch an event
/// bus.onEvent(MyCustomEvent("App started"));
/// ```
/// {@endtemplate}
class SimpleApplicationEventBus implements ApplicationEventBus {
  final List<ApplicationEventListener> _listeners = [];
  final Map<String, ApplicationEventListener> _mappedListeners = {};
  final ConfigurableListablePodFactory? _podFactory;

  /// {@macro simple_application_event_bus}
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
        listener.onApplicationEvent(event);
      }
    }

    for (final listener in _mappedListeners.values) {
      if (listener.supportsEventOf(event)) {
        listener.onApplicationEvent(event);
      }
    }
  }
}