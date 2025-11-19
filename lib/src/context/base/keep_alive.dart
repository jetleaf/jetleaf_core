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

import 'dart:async' show Completer, FutureOr;

import 'package:jetleaf_lang/lang.dart';

import '../event/event_listener.dart';
import '../event/application_event.dart';
import '../lifecycle/lifecycle.dart';

/// {@template keep_alive}
/// A lifecycle-aware component that keeps the Dart VM alive as long as
/// the [ApplicationContext] is running.
///
/// This is useful for command-line or server-based JetLeaf applications
/// that would otherwise terminate after context initialization.
///
/// The keep-alive mechanism listens to [ApplicationContextEvent]s and
/// starts an internal blocking thread on [ContextSetupEvent], and
/// releases it on [ContextClosedEvent].
///
/// ---
///
/// ### Example
/// ```dart
/// void main() {
///   final context = JetLeaf.run();
///   context.addApplicationListener(KeepAlive());
/// }
/// ```
///
/// {@endtemplate}
final class KeepAlive implements Lifecycle, ApplicationEventListener<ApplicationContextEvent> {
  /// Tells if the keep alive is running
  bool _isRunning = false;

  /// Internal completer used to block the thread until shutdown.
  Completer<void> completer = Completer<void>();

  /// {@macro keep_alive}
  KeepAlive();

  @override
  bool supportsEventOf(ApplicationEvent event) => event is ApplicationContextEvent;

  @override
  Future<void> onApplicationEvent(ApplicationContextEvent event) async {
    if (event is ContextSetupEvent) {
      return await start();
    } else if (event is ContextClosedEvent) {
      return await stop();
    }
  }

  /// Starts the keep-alive thread by awaiting an uncompleted [Completer].
  ///
  /// This method will block the current execution thread until
  /// [stop] is called, making it suitable for use
  /// at the end of a `main()` method to prevent premature VM exit.
  @override
  FutureOr<void> start() async {
    if (completer.isCompleted) {
      completer = Completer<void>();
    }

    _isRunning = true;
    return await completer.future;
  }

  /// Stops the keep-alive thread, allowing the application to shut down.
  ///
  /// This completes the internal [Completer], releasing the await in
  /// [start] and allowing the process to exit gracefully.
  @override
  Future<void> stop([Runnable? runnable]) async {
    if (completer.isCompleted) return;
    completer.complete(runnable?.run());

    _isRunning = false;

    return Future.value();
  }

  @override
  bool isRunning() => _isRunning;
}