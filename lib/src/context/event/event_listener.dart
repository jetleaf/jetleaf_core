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

import 'application_event.dart';

// ================================== APPLICATION EVENT LISTENER =====================================

/// {@template application_event_listener}
/// A listener for a specific type of [ApplicationEvent].
///
/// Implementations of this interface receive strongly typed application events
/// during the lifecycle of the application, such as context refresh, shutdown,
/// or domain-specific triggers.
///
/// This is a typed variant of [EventListener] and is automatically detected
/// by the JetLeaf event dispatch system when registered in the application context.
///
/// ### Key Features:
/// - **Type Safety**: Strongly typed event handling with generic parameter
/// - **Automatic Detection**: Automatically registered when defined as a pod
/// - **Lifecycle Integration**: Receives events during application lifecycle
/// - **Synchronous Dispatch**: Events are typically dispatched synchronously
///
/// ### Event Types:
/// Common application events include:
/// - [ApplicationStartedEvent] - Application context has been refreshed
/// - [ApplicationStoppedEvent] - Application context is being stopped
/// - [ApplicationFailedEvent] - Application context failed to refresh
/// - [CustomDomainEvent] - Application-specific domain events
///
/// ### Registration:
/// Listeners are automatically detected and registered when they are:
/// - Defined as pods in the application context
/// - Implement the [ApplicationEventListener] interface
/// - Specify the exact event type they wish to receive
///
/// ### Example Usage:
/// ```dart
/// class DatabaseReadyListener implements ApplicationListener<DatabaseReadyEvent> {
///   @override
///   void onApplicationEvent(DatabaseReadyEvent event) {
///     print('Database connection established: ${event.connectionId}');
///     // Perform initialization that requires database access
///   }
/// }
/// ```
///
/// ### Multiple Event Types:
/// To listen for multiple event types, implement multiple interfaces:
/// ```dart
/// class MultiEventListener implements 
///     ApplicationEventListener<ApplicationStartedEvent>,
///     ApplicationEventListener<ApplicationStoppedEvent> {
///   
///   @override
///   void onApplicationEvent(ApplicationStartedEvent event) {
///     print('Application started');
///   }
///   
///   @override
///   void onApplicationEvent(ApplicationStoppedEvent event) {
///     print('Application stopped');
///   }
///   
///   // Note: Dart doesn't support method overloading by return type,
///   // so you'll need to use different method names or type checking
/// }
/// ```
///
/// ### Ordering and Priority:
/// Listeners can implement [Ordered] or [PriorityOrdered] to control
/// the order in which they receive events:
/// ```dart
/// class HighPriorityListener implements 
///     ApplicationEventListener<CustomEvent>,
///     Ordered {
///   
///   @override
///   void onApplicationEvent(CustomEvent event) {
///     // Handle event
///   }
///   
///   @override
///   int getOrder() => Ordered.HIGHEST_PRECEDENCE;
/// }
/// ```
///
/// ### Error Handling:
/// Exceptions thrown in event listeners are caught and logged by the
/// event publisher but do not prevent other listeners from receiving the event.
///
/// ### Thread Safety:
/// Typically, listeners are invoked synchronously on the same thread that
/// publishes the event. Ensure thread-safe operations if events can be
/// published from multiple threads.
///
/// See also:
/// - [ApplicationEvent] for the base event class
/// - [ApplicationEventPublisher] for event publication
/// - [EventListener] for the non-typed variant
/// - [SmartApplicationListener] for conditional event handling
/// {@endtemplate}
@Generic(ApplicationEventListener)
abstract interface class ApplicationEventListener<E extends ApplicationEvent> {
  /// {@template application_event_listener.on_application_event}
  /// Handle an application event of type [E].
  ///
  /// This method will be called by the event publisher when an event of
  /// type [E] (or subtype) is dispatched. The method should process the
  /// event and return promptly to avoid blocking event dispatch to other
  /// listeners.
  ///
  /// ### Parameters:
  /// - [event]: The application event that occurred. This will always be
  ///   an instance of type [E] or one of its subtypes.
  ///
  /// ### Implementation Notes:
  /// - Keep event handling logic minimal and efficient
  /// - Consider offloading long-running operations to separate executors
  /// - Handle exceptions appropriately within the method
  /// - Avoid modifying the event object unless documented as safe
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void onApplicationEvent(UserRegisteredEvent event) {
  ///   final user = event.user;
  ///   logger.info('User registered: ${user.username}');
  ///   
  ///   // Send welcome email
  ///   emailService.sendWelcomeEmail(user.email);
  /// }
  /// ```
  ///
  /// ### Error Handling:
  /// If an exception is thrown during event processing:
  /// - The exception is caught and logged by the event publisher
  /// - Other listeners will still receive the event
  /// - The publishing code is not affected by the exception
  ///
  /// See also:
  /// - [supportsEventOf] for conditional event handling
  /// {@endtemplate}
  Future<void> onApplicationEvent(E event);

  /// {@template application_event_listener.supports_event_of}
  /// Returns true if the listener supports the given event.
  /// 
  /// This method is used by the event publisher to determine if the listener
  /// should be notified of the event. The default implementation checks if
  /// the event is an instance of the generic type [E].
  ///
  /// Override this method to provide custom event filtering logic when
  /// the listener should only handle specific instances of event type [E].
  ///
  /// ### Parameters:
  /// - [event]: The event to check for support
  ///
  /// ### Returns:
  /// `true` if this listener can handle the given event, `false` otherwise
  ///
  /// ### Default Behavior:
  /// The default implementation returns `event is E`, meaning the listener
  /// will receive all events that are instances of type [E] or its subtypes.
  ///
  /// ### Custom Filtering Example:
  /// ```dart
  /// class SpecificUserEventListener implements ApplicationEventListener<UserEvent> {
  ///   final String targetUsername;
  ///   
  ///   SpecificUserEventListener(this.targetUsername);
  ///   
  ///   @override
  ///   bool supportsEventOf(ApplicationEvent event) {
  ///     return event is UserEvent && event.user.username == targetUsername;
  ///   }
  ///   
  ///   @override
  ///   void onApplicationEvent(UserEvent event) {
  ///     // Only called for events matching the target username
  ///     print('Target user action: ${event.action}');
  ///   }
  /// }
  /// ```
  ///
  /// ### Performance Considerations:
  /// This method is called for every event dispatch, so keep the logic
  /// efficient. For complex filtering, consider using multiple specialized
  /// listener implementations instead.
  ///
  /// See also:
  /// - [onApplicationEvent] for the actual event handling
  /// - [GenericApplicationEventMulticaster] for the dispatch implementation
  /// {@endtemplate}
  bool supportsEventOf(ApplicationEvent event) => event is E;
}