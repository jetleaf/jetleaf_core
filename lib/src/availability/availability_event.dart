import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';

import 'availability_state.dart';

/// {@template availability_event}
/// Represents an application-level event that conveys a change or report
/// regarding an application's **availability state**.
///
/// An [AvailabilityEvent] is emitted to signal transitions or updates in
/// either:
/// - **Readiness** (via [ReadinessState]), or
/// - **Liveness** (via [LivenessState]),
///
/// depending on the generic type parameter.
///
/// This event integrates into the broader application event pipeline by
/// extending [ApplicationEvent], allowing monitoring subsystems, lifecycle
/// managers, or orchestration layers to react to real-time availability
/// changes.
///
/// ### Generic Parameter
/// The generic type [Available] specifies the particular availability
/// enum being reported.
///
/// Must extend:
/// ```dart
/// AvailabilityState
/// ```
///
/// ### Example
/// ```dart
/// final event = AvailabilityEvent(
///   this,
///   ReadinessState.ACCEPTING_TRAFFIC,
///   DateTime.now(),
/// );
/// ```
/// {@endtemplate}
@Generic(AvailabilityEvent)
class AvailabilityEvent<Available extends AvailabilityState> extends ApplicationEvent {
  /// The concrete availability state being reported.
  ///
  /// This may represent:
  /// - A readiness state (e.g., [ReadinessState.ACCEPTING_TRAFFIC])
  /// - A liveness state (e.g., [LivenessState.ACTIVE])
  ///
  /// Consumers of this event can inspect [availability] to determine the
  /// application's current operational status.
  final Available availability;

  /// {@template availability_event_constructor}
  /// Creates a new [AvailabilityEvent] with the given [source], [availability],
  /// and explicit [timestamp].
  ///
  /// This constructor is used when the event issuer wants to provide a
  /// precise timestamp rather than relying on a generated one.
  ///
  /// ### Parameters
  /// - `source`: The object that triggered or emitted this event
  /// - `availability`: The availability state being reported
  /// - `timestamp`: When the event occurred
  /// {@endtemplate}
  /// 
  /// {@macro availability_event}
  const AvailabilityEvent(super.source, this.availability, super.timestamp);

  /// Creates a new [AvailabilityEvent] using an injected or default clock.
  ///
  /// This constructor is useful when timestamps are generated automatically
  /// by a time source, helping ensure consistent time generation across the
  /// system (such as through virtual clocks or testable clock abstractions).
  ///
  /// ### Parameters
  /// - `source`: The originator of the event  
  /// - `availability`: The availability state being reported  
  /// - `clock`: A clock instance used for timestamp generation
  /// 
  /// {@macro availability_event}
  AvailabilityEvent.withClock(super.source, this.availability, super.clock);

  /// Publishes an availability state event into the application's event bus.
  ///
  /// This method is a convenience wrapper around [justPublish], automatically
  /// obtaining the [`ApplicationEventBus`](ApplicationEventBus) from the supplied
  /// [ConfigurableApplicationContext]. It is used to broadcast changes to
  /// application readiness or liveness state (e.g., transitioning to
  /// `ReadinessState.ACCEPTING_TRAFFIC` or `LivenessState.BROKEN`).
  ///
  /// The published event is an [AvailabilityEvent] containing:
  /// - the event **source** (the application context)
  /// - the new availability **state**
  /// - the event **timestamp**
  ///
  /// The returned [Future] completes once the event has been delivered to the bus.
  ///
  /// ### Example
  /// ```dart
  /// await AvailabilityEvent.publish(context, ReadinessState.ACCEPTING_TRAFFIC);
  /// ```
  static Future<void> publish<S extends AvailabilityState>(ConfigurableApplicationContext context, S state) async {
    await justPublish(context.getApplicationEventBus(), context, state);
  }

  /// Publishes an availability event directly to the provided [eventBus].
  ///
  /// This is the low-level variant of [publish], allowing callers to explicitly
  /// supply the event bus and the event source. An [AvailabilityEvent] is
  /// created and dispatched asynchronously through the bus using [`onEvent`].
  ///
  /// Used internally by the framework and by advanced integrations that wish to
  /// emit availability changes from non-context sources.
  ///
  /// ### Parameters
  /// - `eventBus`: The bus responsible for distributing application lifecycle events.
  /// - `source`: The originator of the availability change (context, subsystem, etc.).
  /// - `state`: The new availability state, such as a [ReadinessState] or [LivenessState].
  ///
  /// ### Behavior
  /// - Emits an [AvailabilityEvent] containing `source`, `state`, and a timestamp.
  /// - Returns a [Future] that completes when the event has been dispatched.
  /// - Does not perform additional filtering or transformations.
  ///
  /// ### Example
  /// ```dart
  /// await AvailabilityEvent.justPublish(bus, this, LivenessState.ACTIVE);
  /// ```
  static Future<void> justPublish<S extends AvailabilityState>(ApplicationEventBus eventBus, Object source, S state) async {
    await eventBus.onEvent(AvailabilityEvent(source, state, DateTime.now()));
  }

  @override
  String getPackageName() => PackageNames.MAIN;
}