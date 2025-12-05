/// {@template availability_state}
/// A marker interface representing any **application availability state**.
///
/// This interface exists to provide a common type shared by both
/// [ReadinessState] and [LivenessState], allowing systems to treat
/// different availability characteristics under a unified contract.
///
/// Availability states are typically used by orchestrators, load balancers,
/// and lifecycle managers to determine how an application should be handled
/// at runtime (e.g., whether it should receive traffic, or whether it should
/// be restarted).
/// {@endtemplate}
abstract interface class AvailabilityState {}

/// {@template readiness_state}
/// Represents the **readiness state** of an application.
///
/// A readiness state indicates whether the application is prepared to
/// **accept new traffic**. Most commonly used in "readiness probes" or
/// `/ready` endpoints, this enum helps orchestrators like Kubernetes decide
/// whether a service instance should be included in load balancing.
///
/// ### When to use:
/// - Determining whether the application has completed startup
/// - Blocking incoming traffic during initialization
/// - Temporarily removing an instance from rotation
///
/// ### Example:
/// ```dart
/// if (state == ReadinessState.ACCEPTING_TRAFFIC) {
///   // Ready to receive requests
/// }
/// ```
/// {@endtemplate}
enum ReadinessState implements AvailabilityState {
  /// The application is fully initialized and able to accept incoming traffic.
  ACCEPTING_TRAFFIC,

  /// The application is not currently able to receive traffic.
  ///
  /// This may occur during:
  /// - Startup sequences
  /// - Maintenance or reconfiguration
  /// - Temporary degraded states
  /// - Graceful shutdown
  REFUSING_TRAFFIC,
}

/// {@template liveness_state}
/// Represents the **liveness state** of an application.
///
/// A liveness state indicates whether the application is **alive and
/// functioning**. Unlike readiness checks, liveness checks reveal whether
/// the application needs to be **restarted** due to an unrecoverable failure.
///
/// Commonly used in "liveness probes" or `/live` endpoints.
/// If an application reports [BROKEN], orchestrators typically restart it.
///
/// ### Example:
/// ```dart
/// if (state == LivenessState.BROKEN) {
///   // Application requires restart
/// }
/// ```
/// {@endtemplate}
enum LivenessState implements AvailabilityState {
  /// The application has entered a broken or unrecoverable state.
  ///
  /// Triggering this state typically instructs orchestration environments
  /// to restart the service instance.
  BROKEN,

  /// The application is alive and functioning normally.
  ///
  /// This indicates that the process is responsive and not in a deadlocked
  /// or irrecoverable condition.
  ACTIVE,
}