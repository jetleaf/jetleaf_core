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

import 'dart:async' show Completer;

import 'event/event_listener.dart';
import 'event/application_event.dart';

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
final class KeepAlive implements ApplicationEventListener<ApplicationContextEvent> {
  /// Internal completer used to block the thread until shutdown.
  Completer<void> completer = Completer<void>();

  /// {@macro keep_alive}
  KeepAlive();

  @override
  bool supportsEventOf(ApplicationEvent event) => event is ApplicationContextEvent;

  @override
  Future<void> onApplicationEvent(ApplicationContextEvent event) async {
    if (event is ContextSetupEvent) {
      startKeepAliveThread();
    } else if (event is ContextClosedEvent) {
      stopKeepAliveThread();
    }
  }

  /// Starts the keep-alive thread by awaiting an uncompleted [Completer].
  ///
  /// This method will block the current execution thread until
  /// [stopKeepAliveThread] is called, making it suitable for use
  /// at the end of a `main()` method to prevent premature VM exit.
  void startKeepAliveThread() async {
    if (completer.isCompleted) {
      completer = Completer<void>();
    }

    await completer.future;
  }

  /// Stops the keep-alive thread, allowing the application to shut down.
  ///
  /// This completes the internal [Completer], releasing the await in
  /// [startKeepAliveThread] and allowing the process to exit gracefully.
  void stopKeepAliveThread() {
    if (completer.isCompleted) return;
    completer.complete();
  }
}