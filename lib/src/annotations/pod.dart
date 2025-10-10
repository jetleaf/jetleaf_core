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
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta_meta.dart';

/// {@template pod}
/// Marks a method as a **pod provider**, enabling it to participate in the
/// dependency injection (DI) lifecycle of the application.
///
/// The method annotated with `@Pod` should return an instance of a component,
/// service, or configuration object. This returned value is automatically
/// registered in the application’s DI container and, by default, managed
/// as a **singleton**.
///
/// ---
///
/// ## 🔧 How It Works:
/// - The enclosing class is typically annotated with `@Configuration` or `@AutoConfiguration`.
/// - During application startup, all methods annotated with `@Pod` are executed,
///   and their return values are registered in the application context.
/// - These pods are then available for **injection into other classes** via
///   constructor injection, factory injection, or field injection (depending on the framework).
///
/// ---
///
/// ## 📌 Features:
/// - Default lifecycle is **singleton** (created once and reused).
/// - Supports **lazy initialization** depending on the framework’s DI engine.
/// - May support pod naming or conditional creation in extended versions.
///
/// ---
///
/// ## 🧪 Example:
/// ```dart
/// @Configuration()
/// class AppConfig {
///
///   @Pod()
///   Logger createLogger() {
///     return Logger('AppLogger');
///   }
///
///   @Pod()
///   HttpClient httpClient(Logger logger) {
///     return HttpClient(logger: logger);
///   }
/// }
/// ```
///
/// In the example above:
/// - `createLogger()` returns a `Logger` instance registered as a pod.
/// - `httpClient()` depends on `Logger`, which is automatically injected by the container.
///
/// ---
///
/// ## 🔄 Pod Lifecycle (Simplified):
/// ```text
/// - Framework initializes configuration class
/// - All @Pod methods are executed
/// - Results are cached as singleton pods
/// - Pods are injected into constructors or other pods as needed
/// ```
///
/// ---
///
/// ## 🔥 Advanced Use Cases (Possible Extensions):
/// - Conditional pods: `@ConditionalOnMissingPod`, `@Profile('dev')`
/// - Scoped pods: e.g., per request, per session (via `@Scope`)
/// - Named pods: `@Pod(name: 'myLogger')`
///
/// These can be added through optional parameters or decorators in future.
///
/// ---
///
/// ## ❗ Constraints:
/// - The method must be **non-private**.
/// - The method must **return a value**; `void` is not allowed.
/// - Must be defined within a class marked with `@Configuration`, `@AutoConfiguration`, etc.
/// - Cyclic dependencies must be handled explicitly or avoided.
///
/// ---
///
/// ## ✅ Usage Recommendations:
/// - Prefer pod methods over manual instantiation in app code.
/// - Keep logic inside pod methods minimal — do initialization but not business logic.
/// - Group related pods in separate configuration classes for clarity.
///
/// ---
///
/// ## 🧱 Related Annotations:
/// - `@Configuration` – Marks the containing class as a source of pod definitions.
/// - `@AutoConfiguration` – Similar but auto-discovered.
/// - `@Aspect` – Used for cross-cutting concerns.
/// - `@Inject`, `@Autowired` – For consuming/injecting defined pods.
///
/// ---
///
/// ## 🎯 Target:
/// Can only be applied to methods:
/// ```dart
/// @Pod()
/// MyService myService() => MyService();
/// ```
///
/// ---
/// Pod annotation for pod definition methods
/// 
/// This annotation marks a method as a pod producer.
/// 
/// Example Usage:
/// ```dart
/// @Configuration()
/// class DatabaseConfig {
///   @Pod()
///   @Scope('singleton')
///   DatabaseConnection primaryDatabase() {
///     return DatabaseConnection(
///       url: 'postgresql://localhost:5432/primary',
///       maxConnections: 20,
///     );
///   }
///   
///   @Pod('readOnlyDatabase')
///   @Scope('prototype')
///   DatabaseConnection readOnlyDatabase() {
///     return DatabaseConnection(
///       url: 'postgresql://localhost:5432/readonly',
///       readOnly: true,
///     );
///   }
/// }
/// ```
/// 
/// {@endtemplate}
@Target({TargetKind.method})
class Pod extends ReflectableAnnotation with EqualsAndHashCode {
  /// Optional pod name.
  ///
  /// If not provided, Jetleaf will infer a name from the method.
  ///
  /// ### Example:
  /// ```dart
  /// @Pod('customLogger')
  /// Logger createLogger() => Logger('CustomLogger');
  /// ```
  final String? value;

  /// List of initialization methods to invoke on the created pod.
  ///
  /// These methods must exist on the returned object.
  ///
  /// ### Example:
  /// ```dart
  /// @Pod(initMethods: ['init'])
  /// Cache createCache() => Cache();
  /// ```
  final List<String> initMethods;

  /// List of destruction methods to invoke when the pod is destroyed.
  ///
  /// These methods should clean up resources like file handles or connections.
  ///
  /// ### Example:
  /// ```dart
  /// @Pod(destroyMethods: ['dispose'])
  /// Connection createConnection() => Connection();
  /// ```
  final List<String> destroyMethods;

  /// Whether to enforce declared init methods.
  ///
  /// If `true`, Jetleaf will throw an error if an `initMethod` does not exist
  /// on the produced object.
  final bool enforceInitMethods;

  /// Whether to enforce declared destroy methods.
  ///
  /// If `true`, Jetleaf will throw an error if a `destroyMethod` does not exist
  /// on the produced object.
  final bool enforceDestroyMethods;

  /// Autowire mode for dependency injection.
  ///
  /// Controls how Jetleaf should resolve dependencies for the method parameters.
  ///
  /// ### Example:
  /// ```dart
  /// @Pod(
  ///   value: 'servicePod',
  ///   autowireMode: AutowireMode.BY_TYPE,
  /// )
  /// Service createService(Repository repo) => Service(repo);
  /// ```
  final AutowireMode autowireMode;
  
  /// {@macro pod}
  const Pod({
    this.value,
    this.autowireMode = AutowireMode.NO,
    this.initMethods = const [],
    this.destroyMethods = const [],
    this.enforceInitMethods = false,
    this.enforceDestroyMethods = false
  });
  
  @override
  String toString() => 'Pod(value: $value)';

  @override
  Type get annotationType => Pod;

  @override
  List<Object?> equalizedProperties() => [value, initMethods, destroyMethods, enforceInitMethods, enforceDestroyMethods, autowireMode];
}