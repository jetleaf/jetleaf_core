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
import 'package:meta/meta_meta.dart';

import '../context/event/application_event.dart';

/// {@template event_listener}
/// Annotation to mark a method that should run when the application is
/// **listening** to a specific type of [ApplicationEvent].
///
/// This is typically used to register event listeners in the application
/// context, allowing them to receive and process events published by the
/// framework or custom domain events.
///
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `ApplicationEvent`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @EventListener()
///   void handleEvent(ApplicationEvent event) {
///     print("Event received: $event");
///   }
/// 
///   @EventListener(EventType<ContextRefreshedEvent>('user_package'))
///   void handleContextRefreshedEvent() {
///     print("Context refreshed");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class EventListener extends ReflectableAnnotation with EqualsAndHashCode {
  /// The type of [ApplicationEvent] to listen to.
  final EventType? event;
  
  /// {@macro event_listener}
  const EventListener([this.event]);

  @override
  Type get annotationType => EventListener;

  @override
  List<Object?> equalizedProperties() => [event];
}

/// {@template event_type}
/// 🫘 Represents a typed application event associated with a specific package.
///
/// The [EventType] class is a simple container that binds an [ApplicationEvent]
/// instance with the name of the package that produced it. This allows events
/// to be categorized, filtered, or routed based on their originating package.
///
/// ## Type Parameter
///
/// - [T] – The concrete type of [ApplicationEvent] this [EventType] holds.
///
/// ## Example
///
/// ```dart
/// class UserCreatedEvent extends ApplicationEvent {
///   final String userId;
///   const UserCreatedEvent(this.userId);
/// }
/// 
/// @EventListener(EventType<UserCreatedEvent>('user_package'))
/// void handleUserCreatedEvent(UserCreatedEvent event) {
///   print("User created: ${event.userId}");
/// }
///
/// void main() {
///   final event = UserCreatedEvent('12345');
///   final eventType = EventType(event, 'user_package');
///
///   print('Event: ${eventType.event}, Package: ${eventType.packageName}');
/// }
/// ```
///
/// ## Use Cases
///
/// - Event-driven application architectures.
/// - Associating events with their defining package/module.
/// - Passing typed event metadata through the JetLeaf lifecycle.
///
/// See also:
/// - [ApplicationEvent] 🫘 the base class for application events.
/// 
/// {@endtemplate}
@Generic(EventType)
final class EventType<T extends ApplicationEvent> {
  /// The name of the package where this event originated.
  final String? _packageName;

  /// Creates a new [EventType] with the given [event] and [_packageName].
  /// 
  /// {@macro event_type}
  const EventType([this._packageName]);

  /// Returns the type of [ApplicationEvent] this [EventType] holds.
  Class<T> getType() {
    String? packageName = _packageName;
    if (packageName == null) {
      if (T is ContextClosedEvent || T is ContextRefreshedEvent || T is ContextStartedEvent || T is ContextStoppedEvent || T is ContextRestartedEvent || T is ContextFailedEvent || T is ContextReadyEvent) {
        packageName = PackageNames.CORE;
      }
    }

    return Class<T>(null, packageName);
  }
}

// -------------------------------------------------------------------------------------------------------
// ON APPLICATION STARTING
// -------------------------------------------------------------------------------------------------------

/// {@template on_application_starting}
/// Annotation to mark a method that should run when the application is
/// **starting**, before the context refresh occurs.
///
/// This is typically used to prepare resources, validate configuration,
/// or perform setup tasks that need to run at the very beginning of
/// the application lifecycle.
/// 
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `ConfigurableBootstrapContext` or `Class<Object>`.
/// - Two-Args: The method should accept two arguments of types `ConfigurableBootstrapContext` and `Class<Object>`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnApplicationStarting()
///   void initResources() {
///     print("Initializing resources before context refresh...");
///   }
/// 
///   @OnApplicationStarting()
///   void initResourcesWithContext(ConfigurableBootstrapContext context) {
///     print("Initializing resources before context refresh...");
///   }
/// 
///   @OnApplicationStarting()
///   void initResourcesWithContextAndClass(ConfigurableBootstrapContext context, Class<Object> mainClass) {
///     print("Initializing resources before context refresh...");
///   }
/// 
///   @OnApplicationStarting()
///   void initResourcesWithClass(Class<Object> mainClass) {
///     print("Initializing resources before context refresh...");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnApplicationStarting extends ReflectableAnnotation {
  /// {@macro on_application_starting}
  const OnApplicationStarting();

  @override
  Type get annotationType => OnApplicationStarting;
}

// -------------------------------------------------------------------------------------------------------
// ON APPLICATION STARTED
// -------------------------------------------------------------------------------------------------------

/// {@template on_application_started}
/// Annotation to mark a method that should run when the application has
/// **started**, meaning the context is refreshed but the app is not yet
/// fully ready.
///
/// This is commonly used to register services, trigger warm-up tasks,
/// or perform actions that depend on the refreshed context.
/// 
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `ConfigurableApplicationContext` or `Duration`.
/// - Two-Args: The method should accept two arguments of types `ConfigurableApplicationContext` and `Duration`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnApplicationStarted()
///   void afterStart() {
///     print("Application context has started, initializing caches...");
///   }
/// 
///   @OnApplicationStarted()
///   void afterStartWithContext(ConfigurableApplicationContext context) {
///     print("Application context has started, initializing caches...");
///   }
/// 
///   @OnApplicationStarted()
///   void afterStartWithContextAndTime(ConfigurableApplicationContext context, Duration timeTaken) {
///     print("Application context has started, initializing caches...");
///   }
/// 
///   @OnApplicationStarted()
///   void afterStartWithTime(Duration timeTaken) {
///     print("Application context has started, initializing caches...");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnApplicationStarted extends ReflectableAnnotation {
  /// {@macro on_application_started}
  const OnApplicationStarted();

  @override
  Type get annotationType => OnApplicationStarted;
}

// -------------------------------------------------------------------------------------------------------
// ON APPLICATION READY
// -------------------------------------------------------------------------------------------------------

/// {@template on_application_ready}
/// Annotation to mark a method that should run when the application is
/// **fully ready** to serve requests.
///
/// Use this to start background tasks, open connections, or notify
/// external systems that the application is live.
/// 
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `ConfigurableApplicationContext` or `Duration`.
/// - Two-Args: The method should accept two arguments of types `ConfigurableApplicationContext` and `Duration`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnApplicationReady()
///   void notifyReady() {
///     print("Application is fully ready!");
///   }
/// 
///   @OnApplicationReady()
///   void notifyReadyWithContext(ConfigurableApplicationContext context) {
///     print("Application is fully ready!");
///   }
/// 
///   @OnApplicationReady()
///   void notifyReadyWithContextAndTime(ConfigurableApplicationContext context, Duration timeTaken) {
///     print("Application is fully ready!");
///   }
/// 
///   @OnApplicationReady()
///   void notifyReadyWithTime(Duration timeTaken) {
///     print("Application is fully ready!");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnApplicationReady extends ReflectableAnnotation {
  /// {@macro on_application_ready}
  const OnApplicationReady();

  @override
  Type get annotationType => OnApplicationReady;
}

// -------------------------------------------------------------------------------------------------------
// ON APPLICATION STOPPING
// -------------------------------------------------------------------------------------------------------

/// {@template on_application_stopping}
/// Annotation to mark a method that should run when the application is
/// **stopping**.
///
/// This is useful for cleaning up resources, shutting down services,
/// and gracefully preparing for application exit.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnApplicationStopping()
///   void cleanup() {
///     print("Cleaning up resources before shutdown...");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnApplicationStopping extends ReflectableAnnotation {
  /// {@macro on_application_stopping}
  const OnApplicationStopping();

  @override
  Type get annotationType => OnApplicationStopping;
}

// -------------------------------------------------------------------------------------------------------
// ON APPLICATION STOPPED
// -------------------------------------------------------------------------------------------------------

/// {@template on_application_stopped}
/// Annotation to mark a method that should run when the application has
/// **fully stopped**.
///
/// This can be used for final cleanup tasks, notifications, or logging
/// that happens after all resources have been released.
/// 
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `ApplicationContext`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnApplicationStopped()
///   void afterStop() {
///     print("Application has stopped completely.");
///   }
/// 
///   @OnApplicationStopped()
///   void afterStopWithContext(ApplicationContext context) {
///     print("Application has stopped completely.");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnApplicationStopped extends ReflectableAnnotation {
  /// {@macro on_application_stopped}
  const OnApplicationStopped();

  @override
  Type get annotationType => OnApplicationStopped;
}

// -------------------------------------------------------------------------------------------------------
// ON APPLICATION FAILED
// -------------------------------------------------------------------------------------------------------

/// {@template on_application_failed}
/// Annotation to mark a method that should run when the application
/// **fails to start or refresh**.
///
/// This is typically used to log errors, notify monitoring systems,
/// or attempt recovery steps.
/// 
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `Object` which will be an exception or optional `ConfigurableApplicationContext`.
/// - Two-Args: The method should accept two arguments of types `Object` which will be an exception and optional `ConfigurableApplicationContext`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnApplicationFailed()
///   void handleFailure() {
///     print("Application failed to start!");
///   }
/// 
///   @OnApplicationFailed()
///   void handleFailureWithContext(ConfigurableApplicationContext? context) {
///     print("Application failed to start!");
///   }
/// 
///   @OnApplicationFailed()
///   void handleFailureWithContextAndException(ConfigurableApplicationContext? context, Object exception) {
///     print("Application failed to start!");
///   }
/// 
///   @OnApplicationFailed()
///   void handleFailureWithException(Object exception) {
///     print("Application failed to start!");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnApplicationFailed extends ReflectableAnnotation {
  /// {@macro on_application_failed}
  const OnApplicationFailed();

  @override
  Type get annotationType => OnApplicationFailed;
}

// -------------------------------------------------------------------------------------------------------
// ON CONTEXT LOADED
// -------------------------------------------------------------------------------------------------------

/// {@template on_context_loaded}
/// Annotation to mark a method that should run when the application
/// **context has been loaded**, but before it is fully refreshed.
///
/// This lifecycle hook is useful for modifying or inspecting the
/// context immediately after it has been constructed, but before
/// pods/services are refreshed and initialized.
/// 
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `ConfigurableApplicationContext`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnContextLoaded()
///   void inspectContext() {
///     print("Context has been loaded, inspecting pods...");
///   }
/// 
///   @OnContextLoaded()
///   void inspectContextWithContext(ConfigurableApplicationContext context) {
///     print("Context has been loaded, inspecting pods...");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnContextLoaded extends ReflectableAnnotation {
  /// {@macro on_context_loaded}
  const OnContextLoaded();

  @override
  Type get annotationType => OnContextLoaded;
}

// -------------------------------------------------------------------------------------------------------
// ON CONTEXT PREPARED
// -------------------------------------------------------------------------------------------------------

/// {@template on_context_prepared}
/// Annotation to mark a method that should run when the application
/// **context has been prepared**.
///
/// This lifecycle event occurs after the environment is set up and
/// configuration has been applied, but before the context is refreshed
/// and pods are fully initialized.  
///
/// Use this for adjusting configuration, registering additional pods,
/// or overriding defaults.
/// 
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `ConfigurableApplicationContext`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnContextPrepared()
///   void prepareContext() {
///     print("Context prepared, applying additional configuration...");
///   }
/// 
///   @OnContextPrepared()
///   void prepareContextWithContext(ConfigurableApplicationContext context) {
///     print("Context prepared, applying additional configuration...");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnContextPrepared extends ReflectableAnnotation {
  /// {@macro on_context_prepared}
  const OnContextPrepared();

  @override
  Type get annotationType => OnContextPrepared;
}

// -------------------------------------------------------------------------------------------------------
// ON ENVIRONMENT PREPARED
// -------------------------------------------------------------------------------------------------------

/// {@template on_environment_prepared}
/// Annotation to mark a method that should run when the application
/// **environment has been prepared**, but before the context is loaded.
///
/// This is the earliest lifecycle hook in the startup sequence. It
/// allows you to inspect or modify environment properties, configure
/// logging, or validate profiles before the context is created.
/// 
/// The only acceptable method signatures are:
/// - No-Arg: The method should not accept any arguments.
/// - One-Arg: The method should accept a single argument of type `ConfigurableEnvironment` or `ConfigurableBootstrapContext`.
/// - Two-Args: The method should accept two arguments of types `ConfigurableEnvironment` and `ConfigurableBootstrapContext`.
///
/// ### Example
/// ```dart
/// class MyApp {
///   @OnEnvironmentPrepared()
///   void setupEnvironment() {
///     print("Environment prepared, validating configuration...");
///   }
/// 
///   @OnEnvironmentPrepared()
///   void setupEnvironmentWithEnvironment(ConfigurableEnvironment environment) {
///     print("Environment prepared, validating configuration...");
///   }
/// 
///   @OnEnvironmentPrepared()
///   void setupEnvironmentWithEnvironmentAndBootstrapContext(ConfigurableEnvironment environment, ConfigurableBootstrapContext bootstrapContext) {
///     print("Environment prepared, validating configuration...");
///   }
/// 
///   @OnEnvironmentPrepared()
///   void setupEnvironmentWithBootstrapContext(ConfigurableBootstrapContext bootstrapContext) {
///     print("Environment prepared, validating configuration...");
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
final class OnEnvironmentPrepared extends ReflectableAnnotation {
  /// {@macro on_environment_prepared}
  const OnEnvironmentPrepared();

  @override
  Type get annotationType => OnEnvironmentPrepared;
}