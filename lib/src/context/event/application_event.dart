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

import '../base/application_context.dart';
import 'event_listener.dart';

// ============================================== EVENT OBJECT =============================================

/// {@template event_object}
/// A base class for all framework-level events.
///
/// This class captures the origin of the event ([_source]) and the time it occurred ([_timestamp]).
/// Subclasses typically define the specific type of event (e.g., context refresh, startup, shutdown).
///
/// Events are generally published and consumed within an application event system,
/// allowing for decoupled communication between components.
///
/// ### Example
/// ```dart
/// class ApplicationStartedEvent extends EventObject {
///   ApplicationStartedEvent(Object source) : super(source);
/// }
///
/// final event = ApplicationStartedEvent(appContext);
/// print(event.getSource()); // appContext
/// print(event.getTimestamp()); // DateTime of creation
/// ```
///
/// See also:
/// - [EventListener]
/// - [ApplicationEventPublisher]
/// {@endtemplate}
abstract class EventObject with EqualsAndHashCode, ToString implements PackageIdentifier {
  /// {@macro event_object}
  
  /// The object that originated (or published) the event.
  final Object _source;

  /// The time at which the event was created.
  final DateTime? _timestamp;

  /// Creates a new [EventObject] with the given [source].
  const EventObject(this._source, [this._timestamp]);

  /// Returns the source of the event.
  Object getSource() => _source;

  /// Returns the timestamp of the event.
  DateTime getTimestamp() => _timestamp ?? DateTime.now();

  @override
  List<Object?> equalizedProperties() => [_source, _timestamp];

  @override
  ToStringOptions toStringOptions() => ToStringOptions(customParameterNames: ["source", "timestamp"])
    ..includeClassName = true;
}

/// {@template application_event}
/// A base class for application-specific events within the JetLeaf framework.
///
/// Extends [EventObject] and allows capturing the event creation time using
/// either the system clock or a custom clock function.
///
/// Subclasses of [ApplicationEvent] are used to represent meaningful events
/// in the lifecycle of an application, such as context initialization, refresh,
/// shutdown, etc.
///
/// ---
///
/// ### Example
/// ```dart
/// class ContextRefreshedEvent extends ApplicationEvent {
///   ContextRefreshedEvent(Object source) : super(source);
/// }
///
/// final event = ContextRefreshedEvent(appContext);
/// print(event.source); // appContext
/// print(event.timestamp); // time of creation
/// ```
///
/// {@endtemplate}
abstract class ApplicationEvent extends EventObject {
  /// {@macro application_event}

  /// Creates a new [ApplicationEvent] with the system clock as timestamp.
  ///
  /// Uses `DateTime.now()` by default.
  const ApplicationEvent(super.source, [super.timestamp]);

  /// Creates a new [ApplicationEventconst ] using a custom clock function.
  ///
  /// This is useful for testing or fine-grained control over timestamps.
  ///
  /// Example:
  /// ```dart
  /// final fixedClock = () => DateTime.utc(2023, 1, 1);
  /// final event = ApplicationEvent.withClock(appContext, fixedClock);
  /// ```
  ApplicationEvent.withClock(Object source, DateTime Function() clock) : super(source, clock());
}

// ====================================== APPLICATION CONTEXT EVENT ========================================

/// {@template application_context_event}
/// A base class for all events that are published within the context of an [ApplicationContext].
///
/// This class is an extension of [ApplicationEvent] that ensures the source
/// of the event is always an [ApplicationContext]. It is intended to be subclassed
/// for specific types of application context lifecycle events such as context refresh,
/// close, or start.
///
/// ---
///
/// ### Example:
/// ```dart
/// class ContextRefreshedEvent extends ApplicationContextEvent {
///   ContextRefreshedEvent(ApplicationContext source) : super(source);
/// }
///
/// void handle(ContextRefreshedEvent event) {
///   final context = event.getSource();
///   print("Application context refreshed: $context");
/// }
/// ```
///
/// This abstraction allows for strongly typed event listeners specific to the lifecycle
/// of the JetLeaf application context.
/// {@endtemplate}
abstract class ApplicationContextEvent extends ApplicationEvent {
  /// {@macro application_context_event}
  const ApplicationContextEvent(ApplicationContext super.source);

  /// {@macro application_context_event}
  ApplicationContextEvent.withClock(ApplicationContext super.source, super.clock) : super.withClock();

  /// Returns the [ApplicationContext] that published this event.
  ///
  /// This overrides the base `source` accessor to provide
  /// a typed reference to the [ApplicationContext].
  @override
  ApplicationContext getSource() => super._source as ApplicationContext;

  /// Returns the [ApplicationContext] that triggered this event.
  /// 
  /// This is a convenience method that returns the source of the event.
  ApplicationContext getApplicationContext() => getSource();
}

// ======================================== CONTEXT CLOSED EVENT ============================================

/// {@template context_closed_event}
/// Event published when an [ApplicationContext] is closed.
///
/// This indicates that the application context is shutting down,
/// and all managed pods should release resources, stop background tasks,
/// or perform any necessary cleanup before termination.
///
/// This event is typically fired at the end of the application lifecycle,
/// right before the context is destroyed.
///
/// ---
///
/// ### Example:
/// ```dart
/// class MyShutdownListener implements ApplicationListener<ContextClosedEvent> {
///   @override
///   void onApplicationEvent(ContextClosedEvent event) {
///     print("Shutting down context: ${event.getSource()}");
///   }
/// }
/// ```
///
/// Registered [ApplicationEventListener]s can listen for this event
/// to trigger disposal or teardown logic.
/// {@endtemplate}
class ContextClosedEvent extends ApplicationContextEvent {
  /// {@macro context_closed_event}
  ContextClosedEvent(super.source);

  /// {@macro context_closed_event}
  ContextClosedEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;
}

// ============================================= CONTEXT FAILED EVENT =======================================

/// {@template context_failed_event}
/// Event published when the [ApplicationContext] fails to start or refresh.
///
/// This typically occurs when the context fails to start or refresh. For example, in a long-running application, the context might
/// fail to start or refresh.
///
/// Listeners may use this event to perform cleanup, stop background processes,
/// or safely pause services that should not run during the failed state.
///
/// ---
///
/// ### Example:
/// ```dart
/// class ShutdownLogger implements ApplicationListener<ContextFailedEvent> {
///   @override
///   void onApplicationEvent(ContextFailedEvent event) {
///     print("Application context failed: ${event.getSource()}");
///   }
/// }
/// ```
///
/// The context can later be restarted by triggering a refresh or start event.
/// {@endtemplate}
class ContextFailedEvent extends ApplicationContextEvent {
  /// {@macro context_failed_event}
  ContextFailedEvent(super.source);

  /// {@macro context_failed_event}
  ContextFailedEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;
}

// ========================================= CONTEXT READY EVENT ===========================================

/// {@template context_ready_event}
/// Event published when the [ApplicationContext] is ready.
///
/// This typically occurs when the context is ready to be used. For example, in a long-running application, the context might
/// be ready to be used.
///
/// Listeners may use this event to perform cleanup, stop background processes,
/// or safely pause services that should not run during the ready state.
///
/// ---
///
/// ### Example:
/// ```dart
/// class ReadyLogger implements ApplicationListener<ContextReadyEvent> {
///   @override
///   void onApplicationEvent(ContextReadyEvent event) {
///     print("Application context ready: ${event.getSource()}");
///   }
/// }
/// ```
///
/// The context can later be restarted by triggering a refresh or start event.
/// {@endtemplate}
class ContextReadyEvent extends ApplicationContextEvent {
  /// {@macro context_ready_state}
  ContextReadyEvent(super.source);

  /// {@macro context_ready_state}
  ContextReadyEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;
}

// ======================================= CONTEXT REFRESHED EVENT ========================================

/// {@template context_refreshed_event}
/// Event published when the [ApplicationContext] is refreshed or initialized.
///
/// This event is emitted after the application context has been fully configured,
/// all singleton pods have been instantiated, and the context is ready for use.
///
/// Listeners may use this event to perform actions once the application
/// is fully bootstrapped, such as triggering cache population, running
/// scheduled tasks, or initializing external services.
///
/// ---
///
/// ### Example:
/// ```dart
/// class StartupInitializer implements ApplicationListener<ContextRefreshedEvent> {
///   @override
///   void onApplicationEvent(ContextRefreshedEvent event) {
///     print("Context has been refreshed: ${event.getSource()}");
///   }
/// }
/// ```
///
/// This is usually the first lifecycle event emitted by the framework during startup.
/// {@endtemplate}
class ContextSetupEvent extends ApplicationContextEvent {
  /// {@macro context_refreshed_event}
  ContextSetupEvent(super.source);

  /// {@macro context_refreshed_event}
  ContextSetupEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;
}

// ======================================== CONTEXT RESTARTED EVENT =========================================

/// {@template context_restarted_event}
/// Event published when the [ApplicationContext] is restarted.
///
/// This event is typically fired when the context is stopped and then started
/// again, signaling a full lifecycle reset rather than just a refresh.
///
/// It can be useful for components that need to release and reacquire resources,
/// reinitialize internal state, or log restart-specific metadata.
///
/// ---
///
/// ### Example:
/// ```dart
/// class RestartMonitor implements ApplicationListener<ContextRestartedEvent> {
///   @override
///   void onApplicationEvent(ContextRestartedEvent event) {
///     print("Application context restarted: ${event.getSource()}");
///   }
/// }
/// ```
///
/// {@endtemplate}
class ContextRestartedEvent extends ApplicationContextEvent {
  /// {@macro context_restarted_event}
  ContextRestartedEvent(super.source);

  /// {@macro context_restarted_event}
  ContextRestartedEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;
}

// ====================================== CONTEXT STARTED EVENT ===========================================

/// {@template context_started_event}
/// Event published when the [ApplicationContext] is started or restarted.
///
/// This event indicates that the context is now active and ready to process
/// requests, initialize pods, or resume tasks that may have been paused or
/// stopped.
///
/// It is typically used after a call to `start()` or when a previously stopped
/// context is reactivated.
///
/// ---
///
/// ### Example:
/// ```dart
/// class StartupLogger implements ApplicationListener<ContextStartedEvent> {
///   @override
///   void onApplicationEvent(ContextStartedEvent event) {
///     print("Application context started: ${event.getSource()}");
///   }
/// }
/// ```
///
/// {@endtemplate}
class ContextStartedEvent extends ApplicationContextEvent {
  /// {@macro context_started_event}
  ContextStartedEvent(super.source);

  /// {@macro context_started_event}
  ContextStartedEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;
}

// ============================================ CONTEXT STOPPED EVENT =======================================

/// {@template context_stopped_event}
/// Event published when the [ApplicationContext] is explicitly stopped.
///
/// This typically occurs when the context is paused without being closed or
/// destroyed. For example, in a long-running application, the context might
/// be stopped temporarily to conserve resources or halt scheduled tasks.
///
/// Listeners may use this event to perform cleanup, stop background processes,
/// or safely pause services that should not run during the stopped state.
///
/// ---
///
/// ### Example:
/// ```dart
/// class ShutdownLogger implements ApplicationListener<ContextStoppedEvent> {
///   @override
///   void onApplicationEvent(ContextStoppedEvent event) {
///     print("Application context stopped: ${event.getSource()}");
///   }
/// }
/// ```
///
/// The context can later be restarted by triggering a refresh or start event.
/// {@endtemplate}
class ContextStoppedEvent extends ApplicationContextEvent {
  /// {@macro context_stopped_event}
  ContextStoppedEvent(super.source);

  /// {@macro context_stopped_event}
  ContextStoppedEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;
}

// =================================== COMPLETED INITIALIZATION EVENT ====================================

/// {@template completed_initialization_event}
/// Event published when the [ApplicationContext] has completed its initialization phase.
///
/// This event indicates that the context has finished setting up all necessary
/// configurations, pod registrations, and is now fully operational.
///
/// It is typically fired after the context has been refreshed and all singleton
/// pods have been instantiated.
///
/// Listeners may use this event to trigger actions that should only occur
/// once the application is fully initialized, such as starting background tasks,
/// initializing caches, or logging startup metrics.
///
/// ---
//// ### Example:
/// ```dart
/// class InitializationLogger implements ApplicationListener<CompletedInitializationEvent> {
///   @override
///   void onApplicationEvent(CompletedInitializationEvent event) {
///     print("Application context initialization completed: ${event.getSource()}");
///   }
/// }
/// ```
/// 
/// {@endtemplate}
class CompletedInitializationEvent extends ApplicationContextEvent {
  /// {@macro completed_initialization_event}
  CompletedInitializationEvent(super.source);

  /// {@macro completed_initialization_event}
  CompletedInitializationEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => PackageNames.CORE;
}

// ======================================== APPLICATION EVENT MULTICASTER =====================================

/// {@template application_event_multicaster}
/// Defines the contract for an event multicaster that manages the registration,
/// removal, and dispatching of `ApplicationEvent`s to `ApplicationListener`s.
///
/// Implementations of this interface are responsible for:
/// - Keeping track of registered listeners and listener pods (by name).
/// - Notifying the appropriate listeners when an event is published.
/// - Supporting listener removal by predicate or name.
///
/// ### Example Usage
/// ```dart
/// final multicaster = MyApplicationEventMulticaster();
/// 
/// multicaster.addApplicationListener(MyCustomListener());
/// multicaster.addApplicationListenerPod('loggingListener');
///
/// multicaster.multicastEvent(SomeCustomEvent());
/// multicaster.removeApplicationListeners((listener) => listener is MyCustomListener);
/// ```
///
/// This interface is typically implemented within the JetLeaf application context
/// to provide event publication support across the system.
///
/// {@endtemplate}
abstract class ApplicationEventBus {
  /// {@macro application_event_multicaster}
  ApplicationEventBus();

  /// Adds an `ApplicationListener` instance to the event multicaster or use podName to let Jetleaf
  /// lazily resolve the listener by pod name and fetch its instance.
  ///
  /// This listener will be notified of all published events unless filtered
  /// explicitly by the implementation.
  ///
  /// ```dart
  /// multicaster.addApplicationListener(listener: MyListener(), podName: 'metricsListener');
  /// ```
  Future<void> addApplicationListener({ApplicationEventListener<ApplicationEvent>? listener, String? podName}) async {}

  /// Removes a previously registered `ApplicationListener` instance or use podName to let Jetleaf
  /// lazily resolve the listener by pod name and remove its instance.
  ///
  /// ```dart
  /// multicaster.removeApplicationListener(listener: MyListener(), podName: 'metricsListener');
  /// ```
  Future<void> removeApplicationListener({ApplicationEventListener<ApplicationEvent>? listener, String? podName}) async {}

  /// Removes all registered `ApplicationListener` instances that match
  /// the provided [listener] or pods by name that match the provided [podName].
  ///
  /// ```dart
  /// multicaster.removeApplicationListeners(
  ///  listener: (listener) => listener.runtimeType.toString().contains('Audit'),
  ///  podName: (podName) => podName.startsWith('deprecated')
  /// );
  /// ```
  Future<void> removeApplicationListeners({Predicate<ApplicationEventListener<ApplicationEvent>>? listener, Predicate<String>? podName}) async {}

  /// Removes all listeners, both instances and pods, from the multicaster.
  ///
  /// After this, no events will be dispatched until new listeners are added.
  ///
  /// ```dart
  /// multicaster.removeAllListeners();
  /// ```
  Future<void> removeAllListeners() async {}

  /// Broadcasts the given [event] to all appropriate listeners.
  ///
  /// If the listener supports async execution, it may be executed
  /// asynchronously depending on implementation.
  ///
  /// ```dart
  /// multicaster.multicastEvent(MyAppStartedEvent());
  /// ```
  Future<void> onEvent(ApplicationEvent event) async {}
}