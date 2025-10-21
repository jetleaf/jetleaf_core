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

import 'application_context.dart';

/// {@template jetleaf_class_ApplicationModule}
/// An **interface** in Jetleaf that defines a configurable application module.
///
/// Application modules encapsulate a set of services, listeners, and
/// processors that can be registered with an [ApplicationContext].
/// This provides a modular and extensible way to assemble applications.
///
/// ### Responsibilities
/// - Encapsulate related services and components.
/// - Register pods, event listeners, and lifecycle processors.
/// - Keep application configuration modular and reusable.
///
/// ### Usage
/// Implementations of [ApplicationModule] should override [configure]
/// and register their required components into the provided
/// [ApplicationContext].
///
/// ### Example
/// ```dart
/// class SecurityModule implements ApplicationModule {
///   @override
///   void configure(ApplicationContext context) {
///     // Register core services
///     context.getPodFactory().registerSingleton('authService', AuthService());
///
///     // Register event listeners
///     context.getPodFactory().registerSingleton(
///       'securityListener',
///       SecurityEventListener(),
///     );
///
///     // Register lifecycle processors
///     context.addLifecycleProcessor(SecurityLifecycleProcessor());
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class ApplicationModule with EqualsAndHashCode {
  /// {@template jetleaf_method_ApplicationModule_configure}
  /// Configure the module with the given [ApplicationContext].
  ///
  /// This method is invoked during application initialization. Implementations
  /// should use the provided context to:
  ///
  /// - Register pods or singletons with the [PodFactory].
  /// - Attach application event listeners.
  /// - Add lifecycle processors to customize startup or shutdown behavior.
  /// 
  /// ### Example
  /// ```dart
  /// class LoggingModule implements ApplicationModule {
  ///   @override
  ///   void configure(ApplicationContext context) {
  ///     context.getPodFactory().registerSingleton('logger', Logger());
  ///     context.addLifecycleProcessor(LoggingLifecycleProcessor());
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  void configure(ApplicationContext context);
}

/// **Annotation-Based Configuration Registry**
///
/// Provides an abstraction for scanning packages and registering annotated
/// classes into an application context. This interface supports a typical
/// workflow for dependency injection or configuration-driven frameworks
/// where classes are discovered at runtime via annotations.
///
/// Implementors are responsible for:
/// - Resolving classes from package names.
/// - Handling lifecycle management of registered pods.
/// - Ensuring thread-safety and idempotence of registration.
abstract interface class AnnotationConfigRegistry {
  /// **Scans the given base packages for annotated components**
  ///
  /// # Parameters
  /// - [basePackages]: List of package names to scan. Only classes in
  ///   these packages will be considered for registration.
  ///
  /// # Behavior
  /// - Recursively inspects subpackages of each base package.
  /// - Filters classes according to annotations recognized by the
  ///   application context (e.g., `@Component`, `@Service`).
  /// - Does not automatically register the classes; scanning is for discovery.
  ///
  /// # Example
  /// ```dart
  /// registry.scan(['package:example/test.dart.service', 'package:example/test.dart.repository']);
  /// ```
  ///
  /// # Notes
  /// - Implementations may cache scan results for performance.
  /// - Can be called multiple times to scan additional packages.
  Future<void> scan(List<String> basePackages);

  /// {@macro application_context_register}
  ///
  /// # Behavior
  /// - Registers the provided classes with the application context.
  /// - If [mainClass] is provided, it can serve as the primary configuration
  ///   entry point (e.g., for bootstrapping or scanning dependent classes).
  /// - Returns a [Future] that completes when registration is finished.
  ///
  /// # Parameters
  /// - [classes]: Optional list of classes to register. If omitted, the
  ///   method may rely on previously scanned classes or [mainClass].
  /// - [mainClass]: Optional single class to register, often used as the
  ///   main configuration class for the context.
  ///
  /// # Example
  /// ```dart
  /// await context.register(
  ///   classes: [MyService, MyRepository],
  ///   mainClass: ApplicationMain,
  /// );
  /// ```
  ///
  /// # Notes
  /// - Registration is typically idempotent; calling multiple times should
  ///   not create duplicate instances.
  /// - Implementations may throw exceptions if class conflicts or invalid
  ///   annotations are detected.
  Future<void> registerClass({List<Class<Object>>? classes, Class<Object>? mainClass});
}