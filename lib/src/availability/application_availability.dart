import 'package:jetleaf_lang/lang.dart';

import 'availability_event.dart';
import 'availability_state.dart';

/// {@template application_availability}
/// Defines the contract for accessing and tracking an application's
/// **availability information**, including both its **liveness** and
/// **readiness** states.
///
/// This abstraction is used by systems responsible for:
/// - Health and availability endpoints (`/live`, `/ready`)
/// - Monitoring and observability tooling
/// - Application lifecycle and orchestration systems
/// - Internal components needing real-time state insight
///
/// Implementations store the latest availability state for each
/// availability dimension and may also retain past [AvailabilityEvent]
/// instances for audit or diagnostic purposes.
///
/// ### Responsibilities
/// - Provide the current *liveness* and *readiness* states  
/// - Expose the latest availability event for each type  
/// - Allow retrieval of arbitrary availability states via generics  
/// - Provide default fallback states when none have been reported  
///
/// ### Example
/// ```dart
/// final availability = MyAvailabilityTracker();
///
/// if (availability.getLivenessState() == LivenessState.BROKEN) {
///   // system requires restart
/// }
///
/// final readiness = availability.getReadinessState();
/// final lastEvent = availability.getLastEvent(Class<ReadinessState>());
/// ```
/// {@endtemplate}
abstract class ApplicationAvailability {
  /// Returns the application's current **liveness state**, or a fallback value.
  ///
  /// Liveness indicates whether the application is **alive**, functioning, and
  /// not in a deadlocked or unrecoverable failure state.
  ///
  /// Uses [getStateOrDefault] with:
  /// - Type: `Class<LivenessState>()`
  /// - Default: [LivenessState.BROKEN]
  LivenessState getLivenessState() => getStateOrDefault(Class<LivenessState>(), LivenessState.BROKEN);

  /// Returns the application's current **readiness state**, or a fallback value.
  ///
  /// Readiness indicates whether the application is **prepared to accept
  /// incoming traffic**.  
  ///
  /// Uses [getStateOrDefault] with:
  /// - Type: `Class<ReadinessState>()`
  /// - Default: [ReadinessState.REFUSING_TRAFFIC]
  ReadinessState getReadinessState() => getStateOrDefault(Class<ReadinessState>(), ReadinessState.REFUSING_TRAFFIC);

  /// Retrieves the most recently known availability state of type [S].
  ///
  /// This method may return `null` if no state has yet been reported.
  ///
  /// Typical availability types:
  /// - [LivenessState]
  /// - [ReadinessState]
  ///
  /// ### Parameters
  /// - **stateType**: A reflective identifier indicating which availability
  ///   state type is being requested.
  ///
  /// ### Returns
  /// The current state of type [S], or `null` if none has been recorded.
  S? getState<S extends AvailabilityState>(Class<S> stateType);

  /// Retrieves the availability state of type [S], providing a default if needed.
  ///
  /// This method wraps [getState] and returns:
  /// - The retrieved state when available
  /// - [defaultState] when no state has been recorded
  ///
  /// ### Parameters
  /// - **stateType**: The reflective type descriptor  
  /// - **defaultState**: A fallback state returned when no value exists  
  ///
  /// ### Returns
  /// A non-null availability state of type [S].
  S getStateOrDefault<S extends AvailabilityState>(Class<S> stateType, S defaultState) {
    final state = getState(stateType);
    if (state != null) {
      return state;
    }

    return defaultState;
  }

  /// Returns the most recent [AvailabilityEvent] associated with availability
  /// type [S].
  ///
  /// This method allows consumers to retrieve not just the current state,
  /// but a full event object containing:
  /// - The origin (`source`)
  /// - The reported state (`availability`)
  /// - The timestamp  
  ///
  /// ### Parameters
  /// - **stateType**: The availability dimension whose last event is requested
  ///
  /// ### Returns
  /// The last recorded availability event of type [S], or `null` if none exist.
  AvailabilityEvent<S>? getLastEvent<S extends AvailabilityState>(Class<S> stateType);
}