import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../context/base/application_context.dart';
import '../context/event/application_event.dart';

/// {@template startup_event}
/// An application–level event signaling that the JetLeaf application
/// has completed its startup sequence.
///
/// A [StartupEvent] is published during the container bootstrapping phase
/// and provides a reference to the associated [StartupTracker], which
/// contains timing, diagnostics, and metadata about the startup process.
///
/// This event is dispatched through the application's event bus and may be
/// listened to by components that need to perform actions after the system
/// has fully initialized (e.g., warm-up routines, analytics reporting,
/// cache preparation, background task scheduling).
///
/// ## Event Characteristics
/// - **Event Source:** The originating [ApplicationContext]
/// - **Timestamp:** Provided by the inherited event clock
/// - **Tracker:** A [StartupTracker] instance describing startup metrics
///
/// ## Publication
/// Use the static [publish] method to dispatch a new [StartupEvent] to the
/// application event bus.
///
/// ## Example
/// ```dart
/// await StartupEvent.publish(context, tracker);
/// ```
/// {@endtemplate}
class StartupEvent extends ApplicationContextEvent {
  /// The tracker containing metrics and diagnostic information about
  /// the application's startup lifecycle.
  ///
  /// This includes timestamps, durations, and any optional startup-phase
  /// instrumentation collected before the event is emitted.
  final StartupTracker tracker;

  /// Creates a new [StartupEvent] using the provided event [source]
  /// and associated [tracker].
  /// 
  /// {@macro startup_event}
  StartupEvent(super.source, this.tracker);

  /// Creates a new [StartupEvent] while explicitly supplying a custom
  /// event clock function. This is typically used when deterministic
  /// timestamps are required (e.g., during testing).
  /// 
  /// {@macro startup_event}
  StartupEvent.withClock(super.source, super.clock, this.tracker) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;

  /// Publishes a [StartupEvent] into the given [ConfigurableApplicationContext].
  ///
  /// This method constructs a timestamped event using the context as its
  /// source and dispatches it through the application's event bus.
  ///
  /// The supplied [tracker] is included in the event so that subscribers
  /// can access startup metrics or perform post-startup logic.
  ///
  /// ## Example
  /// ```dart
  /// await StartupEvent.publish(context, tracker);
  /// ```
  static Future<void> publish(ConfigurableApplicationContext context, StartupTracker tracker) async {
    await context.getApplicationEventBus().onEvent(StartupEvent.withClock(context, () => DateTime.now(), tracker));
  }
}