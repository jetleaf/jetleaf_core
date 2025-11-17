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

import 'method_interceptor.dart';

/// {@template MethodInterceptorRegistry}
/// Central registry for managing method-level interceptors and their dispatching.
///
/// The [MethodInterceptorRegistry] provides a unified interface for registering,
/// configuring, and retrieving method interceptors in JetLeaf’s intercept framework.
/// It ensures that interceptors are invoked in the correct order and under
/// the appropriate conditions.
///
/// Interceptors registered via this interface are typically instances of
/// [MethodInterceptor], which define whether a method can be intercepted
/// based on runtime metadata, annotations, or other criteria. The dispatcher
/// ([MethodInterceptorDispatcher]) coordinates execution of these interceptors,
/// allowing complex method interception workflows such as pre-processing,
/// post-processing, and exception handling.
///
/// The registry supports flexible ordering, allowing interceptors to be executed
/// in priority order, annotated order, or default registration order.
///
/// ## Example Usage
/// ```dart
/// final registry = DefaultMethodInterceptorRegistry();
///
/// // Add a logging interceptor that applies only to public methods
/// registry.addMethodInterceptor(LoggingInterceptor());
///
/// // Add a security interceptor with high priority
/// registry.addMethodInterceptor(SecurityInterceptor());
///
/// // Set the dispatcher responsible for executing interceptors
/// registry.setMethodInterceptorDispatcher(DefaultInterceptorDispatcher());
/// ```
/// {@endtemplate}
abstract interface class MethodInterceptorRegistry {
  /// {@template MethodInterceptorRegistry_addMethodInterceptor}
  /// Registers a [MethodInterceptor] with this registry.
  ///
  /// Interceptors define custom behavior that can be applied before, after,
  /// or around method executions. The registry ensures interceptors are invoked
  /// only for methods they are eligible to intercept, based on their
  /// [MethodInterceptor.canIntercept] implementation.
  ///
  /// The registration process may internally sort interceptors by:
  /// - Priority ([PriorityOrdered])
  /// - Explicit order ([Ordered])
  /// - Registration order (default)
  ///
  /// ## Example
  /// ```dart
  /// registry.addMethodInterceptor(MyLoggingInterceptor());
  /// registry.addMethodInterceptor(MySecurityInterceptor());
  /// registry.addMethodInterceptor(SecInterceptor(), "secInterceptor")
  /// ```
  ///
  /// @param interceptor The interceptor instance to register
  /// {@endtemplate}
  void addMethodInterceptor(MethodInterceptor interceptor, [String? podName]);

  /// {@template MethodInterceptorRegistry_setMethodInterceptorDispatcher}
  /// Sets the [MethodInterceptorDispatcher] that executes the registered interceptors.
  ///
  /// The dispatcher is responsible for:
  /// - Determining the call hierarchy for method invocations
  /// - Selecting the correct interceptors based on runtime conditions
  /// - Executing interceptors in proper order and collecting results
  ///
  /// Only one dispatcher should be associated with a registry at a time. Changing
  /// the dispatcher at runtime may affect ongoing method interception behavior.
  ///
  /// ## Example
  /// ```dart
  /// final dispatcher = DefaultInterceptorDispatcher();
  /// registry.setMethodInterceptorDispatcher(dispatcher);
  /// ```
  ///
  /// @param dispatcher The dispatcher instance that manages method interception
  /// {@endtemplate}
  void setMethodInterceptorDispatcher(MethodInterceptorDispatcher dispatcher);
}

/// {@template MethodInterceptorConfigurer}
/// Strategy interface for configuring method interceptors in JetLeaf intercept.
///
/// Implementations of [MethodInterceptorConfigurer] are responsible for registering
/// and configuring method-level interceptors within a given [MethodInterceptorRegistry].
/// This allows modular and declarative setup of intercept behavior across different
/// parts of an application.
///
/// Typical use cases include:
/// - Registering logging, security, or transaction interceptors
/// - Ordering interceptors based on priority or annotations
/// - Associating interceptors with specific classes or methods
///
/// This interface promotes separation of concerns: the configuration logic
/// is decoupled from the interceptor execution mechanics handled by
/// [MethodInterceptorDispatcher].
///
/// ## Example Usage
/// ```dart
/// class LoggingConfigurer implements MethodInterceptorConfigurer {
///   @override
///   void configure(MethodInterceptorRegistry registry) {
///     // Register a logging interceptor for all public methods
///     registry.addMethodInterceptor(LoggingInterceptor());
///
///     // Set the dispatcher to handle method invocation chains
///     registry.setMethodInterceptorDispatcher(DefaultInterceptorDispatcher());
///   }
/// }
///
/// // During application initialization
/// final registry = DefaultMethodInterceptorRegistry();
/// final configurer = LoggingConfigurer();
/// configurer.configure(registry);
/// ```
/// {@endtemplate}
abstract interface class MethodInterceptorConfigurer {
  /// {@template MethodInterceptorConfigurer_configure}
  /// Configures the given [registry] with interceptors and dispatcher settings.
  ///
  /// Implementations should register all necessary [MethodInterceptor]s
  /// and optionally set a [MethodInterceptorDispatcher] responsible for executing
  /// the interceptors.
  ///
  /// This method is typically called during application startup or module
  /// initialization to ensure that all interceptors are in place before any
  /// intercepted method is invoked.
  ///
  /// ## Example
  /// ```dart
  /// void configure(MethodInterceptorRegistry registry) {
  ///   registry.addMethodInterceptor(SecurityInterceptor());
  ///   registry.addMethodInterceptor(LoggingInterceptor());
  ///   registry.setMethodInterceptorDispatcher(DefaultInterceptorDispatcher());
  /// }
  /// ```
  ///
  /// @param registry The registry to configure with interceptors and dispatcher
  /// {@endtemplate}
  void configure(MethodInterceptorRegistry registry);
}