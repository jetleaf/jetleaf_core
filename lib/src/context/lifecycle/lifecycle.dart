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

/// {@template lifecycle}
/// A common interface defining methods for start/stop lifecycle control.
/// 
/// The typical use case for this is to control asynchronous processing.
/// This interface does not imply specific auto-startup semantics.
/// 
/// ## Usage Example
/// 
/// ```dart
/// class BackgroundTaskManager implements Lifecycle {
///   bool _running = false;
/// 
///   @override
///   void start() {
///     if (!_running) {
///       startBackgroundTasks();
///       _running = true;
///     }
///   }
/// 
///   @override
///   void stop() {
///     if (_running) {
///       stopBackgroundTasks();
///       _running = false;
///     }
///   }
/// 
///   @override
///   bool isRunning() => _running;
/// }
/// ```
/// {@endtemplate}
abstract interface class Lifecycle {
  /// {@macro lifecycle}
  /// 
  /// Start this component.
  /// 
  /// Should not throw an exception if the component is already running.
  FutureOr<void> start();

  /// Stop this component, typically in a synchronous fashion.
  /// 
  /// Should not throw an exception if the component is not running.
  /// 
  /// The callback is used to enable asynchronous shutdown. Implementations
  /// should call the callback once their shutdown process is complete.
  /// 
  /// ## Parameters
  /// 
  /// - [callback]: A callback to invoke once shutdown is complete (may be null)
  /// 
  /// ## Implementation Notes
  /// 
  /// - If shutdown is synchronous, call the callback immediately
  /// - If shutdown is asynchronous, call the callback when complete
  /// - Always call the callback, even if it's null (null-safe call)
  FutureOr<void> stop([Runnable? callback]);

  /// Check whether this component is currently running.
  /// 
  /// ## Return Value
  /// 
  /// Returns true if this component is currently running, false otherwise.
  bool isRunning();
}

/// {@template phased}
/// Interface for objects that may participate in a phased process
/// such as lifecycle management.
/// 
/// The phase value determines the order in which objects are started
/// and stopped. Lower values have higher priority (start earlier, stop later).
/// 
/// ## Phase Values
/// 
/// - **Negative values**: High priority (start first, stop last)
/// - **Zero**: Default priority
/// - **Positive values**: Low priority (start last, stop first)
/// 
/// ## Usage Example
/// 
/// ```dart
/// class DatabaseConnectionManager implements Phased {
///   @override
///   int getPhase() => -1000; // Start early, stop late
/// }
/// 
/// class WebServer implements Phased {
///   @override
///   int getPhase() => 1000; // Start late, stop early
/// }
/// ```
/// {@endtemplate}
abstract interface class Phased {
  /// {@macro phased}
  /// 
  /// Return the phase value of this object.
  /// 
  /// ## Return Value
  /// 
  /// Returns the phase value (lower values have higher priority)
  int getPhase();
}

/// {@template smart_lifecycle}
/// An extension of the [Lifecycle] interface for those objects that require
/// to be started upon ApplicationContext refresh and/or shutdown in a
/// particular order.
/// 
/// The [isAutoStartup] return value indicates whether this object should
/// be started at the time of a context refresh. The callback-accepting
/// [stop] method is useful for objects that have an asynchronous shutdown
/// process.
/// 
/// This interface extends [Phased], and the [getPhase] method's return value
/// indicates the phase within which this Lifecycle component should be started
/// and stopped. The startup process begins with the lowest phase value and
/// ends with the highest phase value. The shutdown process applies the
/// reverse order.
/// 
/// ## Phase-based Startup/Shutdown
/// 
/// 1. **Startup**: Phase -1000 → -100 → 0 → 100 → 1000
/// 2. **Shutdown**: Phase 1000 → 100 → 0 → -100 → -1000
/// 
/// ## Usage Example
/// 
/// ```dart
/// class MessageBroker implements SmartLifecycle {
///   bool _running = false;
/// 
///   @override
///   bool isAutoStartup() => true;
/// 
///   @override
///   int getPhase() => 0;
/// 
///   @override
///   void start() {
///     if (!_running) {
///       connectToBroker();
///       _running = true;
///     }
///   }
/// 
///   @override
///   void stop(Runnable? callback) {
///     if (_running) {
///       disconnectFromBroker(() {
///         _running = false;
///         callback?.run();
///       });
///     } else {
///       callback?.run();
///     }
///   }
/// 
///   @override
///   bool isRunning() => _running;
/// }
/// ```
/// {@endtemplate}
abstract class SmartLifecycle implements Lifecycle, Phased {
  /// Default phase for SmartLifecycle implementations.
  static const int DEFAULT_PHASE = 0;

  /// {@macro smart_lifecycle}
  /// 
  /// Returns true if this Lifecycle component should get started automatically
  /// by the container at the time of ApplicationContext refresh.
  /// 
  /// A value of false indicates that the component is intended to be started
  /// through an explicit start() call instead, analogous to a plain Lifecycle
  /// implementation.
  /// 
  /// ## Return Value
  /// 
  /// Returns true if this component should be started automatically, false otherwise.
  bool isAutoStartup();

  @override
  int getPhase() => DEFAULT_PHASE;
}