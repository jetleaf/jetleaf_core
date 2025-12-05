import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_lang/lang.dart';

import 'application_availability.dart';
import 'availability_event.dart';
import 'availability_state.dart';

/// {@template application_availability_auto_configuration}
/// Provides the default auto-configuration for managing and tracking
/// application **availability states**—including both liveness and readiness.
///
/// This implementation:
/// - Listens for incoming [AvailabilityEvent] instances  
/// - Stores the latest event per availability type  
/// - Exposes the current state via [ApplicationAvailability] APIs  
///
/// It is automatically registered through the `@AutoConfiguration` annotation
/// and is intended to be used by health probes, monitoring endpoints,  
/// orchestration systems, and internal framework components.
///
/// ### How It Works
/// - Each time an [AvailabilityEvent] is received, it is stored in an internal map,
///   keyed by the event’s availability state type (e.g. `LivenessState`, `ReadinessState`).
/// - Consumers then retrieve the current or last-known state through
///   [getState], [getStateOrDefault], or [getLastEvent].
///
/// ### Example
/// ```dart
/// final availability = ApplicationAvailabilityAutoConfiguration();
/// availability.onApplicationEvent(
///   AvailabilityEvent(source, ReadinessState.ACCEPTING_TRAFFIC, DateTime.now())
/// );
///
/// final readiness = availability.getReadinessState(); // ACCEPTING_TRAFFIC
/// ```
/// {@endtemplate}
@AutoConfiguration()
class ApplicationAvailabilityAutoConfiguration extends ApplicationAvailability implements ApplicationEventListener<AvailabilityEvent> {
  /// Internal storage holding the latest [AvailabilityEvent] for each
  /// availability type.
  ///
  /// The map key is the reflective [Class] representing a specific
  /// [AvailabilityState] subtype (e.g. `Class<LivenessState>()`).
  final Map<Class<AvailabilityState>, AvailabilityEvent> _events = HashMap();

  /// {@macro application_availability_auto_configuration}
  ApplicationAvailabilityAutoConfiguration();

  @override
  AvailabilityEvent<S>? getLastEvent<S extends AvailabilityState>(Class<S> stateType) {
    final event = _events[stateType];
    return event as AvailabilityEvent<S>;
  }

  @override
  S? getState<S extends AvailabilityState>(Class<S> stateType) {
    final event = getLastEvent(stateType);
    return event?.availability;
  }

  @override
  Future<void> onApplicationEvent(AvailabilityEvent<AvailabilityState> event) async {
    final type = getStateType(event.availability);
    _events.put(type, event);
  }

  /// Determines the reflective type ([Class]) associated with the given
  /// [AvailabilityState] instance.
  ///
  /// This method ensures that availability states—whether represented by
  /// enums or concrete classes—are consistently mapped to the correct
  /// reflective type used as the key in the internal event registry.
  ///
  /// ### Logic
  /// - If the state is an enum, use the runtime enum type  
  /// - Otherwise, use the class metadata from the state instance  
  ///
  /// ### Parameters
  /// - **state**: The availability state instance from which to derive the type
  ///
  /// ### Returns
  /// The [Class] object representing the state’s concrete type.
  Class<AvailabilityState> getStateType(AvailabilityState state) {
    if (state is Enum) {
      return Class.fromQualifiedName(state.runtimeType.getClass().getQualifiedName());
    }

    return Class.fromQualifiedName(state.getClass().getQualifiedName());
  }

  @override
  bool supportsEventOf(ApplicationEvent event) => event is AvailabilityEvent;
}