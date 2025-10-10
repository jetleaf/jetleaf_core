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
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import '../scope/annotated_scope_metadata_resolver.dart';
import '../scope/scope_metadata_resolver.dart';
import 'stereotype.dart';

@internal
class CommonConfiguration {
  /// Specify whether @Pod methods should get proxied in order to enforce pod lifecycle behavior.
  /// 
  /// ### Example:
  /// ```dart
  /// @Configuration(false)
  /// class AppConfig {
  ///   @Pod()
  ///   Logger logger() => Logger();
  /// }
  /// ```
  final bool proxyPodMethods;

  /// Specify the scope metadata resolver to use for resolving scope metadata.
  /// 
  /// ### Example:
  /// ```dart
  /// @Configuration(const CustomScopeMetadataResolver())
  /// class AppConfig {
  ///   @Pod()
  ///   Logger logger() => Logger();
  /// }
  /// ```
  final ScopeMetadataResolver scopeResolver;

  const CommonConfiguration([this.proxyPodMethods = true, this.scopeResolver = const AnnotatedScopeMetadataResolver()]);
}

// ----------------------------------------------------------------------------------------------------------
// AUTO CONFIGURATION
// ----------------------------------------------------------------------------------------------------------

/// {@template autoConfiguration}
/// Declares a class as a source of **automatic configuration**.
///
/// This annotation marks a class that provides pods, services, or other
/// application components that should be automatically discovered and
/// registered by the framework during application startup.
///
/// ## 🚀 How it Works:
/// - The framework **automatically scans** all classes annotated with
///   `@AutoConfiguration` during bootstrap.
/// - Any methods within these classes annotated with `@Pod` are treated
///   as factory methods and their return values are registered as pods
///   in the application context.
/// - Typically, this is used for **library-level default configurations**
///   or framework-provided setups.
///
/// ## 🎯 Target Use Cases:
/// - Automatically register commonly used pods (e.g., `Logger`, `HttpClient`)
/// - Provide cross-cutting concerns (e.g., metrics, tracing)
/// - Reduce boilerplate in app-level configuration
///
/// ## 🔧 Requirements:
/// - The annotated class must have a public zero-argument constructor (if not using static methods).
/// - `@Pod` methods must return non-null values that will be added to the DI container.
///
/// ## 🧪 Example:
/// ```dart
/// @AutoConfiguration()
/// class DefaultInfrastructure {
///   @Pod()
///   Logger logger() => Logger();
///
///   @Pod()
///   HttpClient client() => HttpClient();
/// }
/// ```
///
/// ## ⚠️ Notes:
/// - If you don’t want a class to be automatically discovered,
///   use `@Configuration()` instead and import it manually.
/// - Avoid putting app-specific configuration in an `@AutoConfiguration`
///   class — it's meant for shared, reusable modules.
///
/// ## 🗂 Organization Tip:
/// Use this in reusable **package-level configurations**, such as:
/// - `logging_config.dart`
/// - `database_auto_config.dart`
/// - `http_auto_config.dart`
///
/// ---
///
/// ## 🔧 Related:
/// - `@Pod()` → Marks methods that return injectable components.
/// - `@Configuration()` → Similar, but not auto-scanned; must be imported.
///
/// ---
///
/// Applies to:
/// - `class` declarations only.
/// 
/// {@endtemplate}
@Target({TargetKind.classType})
final class AutoConfiguration extends CommonConfiguration with EqualsAndHashCode {
  /// {@macro autoConfiguration}
  const AutoConfiguration([super.proxyPodMethods, super.scopeResolver]);

  @override
  List<Object?> equalizedProperties() => [proxyPodMethods, scopeResolver];
}

// ----------------------------------------------------------------------------------------------------------
// CONFIGURATION
// ----------------------------------------------------------------------------------------------------------

/// {@template configuration}
/// Configuration annotation for configuration classes
/// 
/// This annotation marks a class as a source of pod definitions.
/// 
/// Example Usage:
/// ```dart
/// @Configuration()
/// class AppConfig {
///   @Pod()
///   DatabaseConnection databaseConnection() {
///     return DatabaseConnection(
///       host: 'localhost',
///       port: 5432,
///       database: 'myapp',
///     );
///   }
///   
///   @Pod()
///   @Primary()
///   EmailService emailService() {
///     return SmtpEmailService();
///   }
///   
///   @Pod('alternativeEmailService')
///   EmailService alternativeEmailService() {
///     return SendGridEmailService();
///   }
/// }
/// ```
/// Designates a class as a **manual configuration source** for defining pods.
///
/// The `@Configuration` annotation is used to explicitly declare a class
/// that provides pod definitions using annotated methods (e.g., with `@Pod()`).
/// These pods are registered into the application's DI container and can be injected
/// throughout the application.
///
/// Unlike `@AutoConfiguration`, which is discovered automatically (e.g., through scanning),
/// classes annotated with `@Configuration` **must be explicitly imported** and included in the application setup.
///
/// ---
///
/// ## 🧩 Purpose:
/// - Centralizes pod creation logic in a dedicated configuration class.
/// - Encourages clean separation between configuration and business logic.
/// - Supports advanced setup such as conditional pods, external parameters, etc.
///
/// ---
///
/// ## 📦 Typical Use Cases:
/// - Registering pods that require constructor parameters or factory logic
/// - Defining external service clients or adapters
/// - Grouping related configuration logic (e.g., security, database)
///
/// ---
///
/// ## 🧪 Example:
/// ```dart
/// @Configuration()
/// class AppConfig {
///   @Pod()
///   AppService appService() => AppService();
///
///   @Pod()
///   Logger logger() => Logger(level: 'debug');
/// }
/// ```
///
/// ---
///
/// ## 🧱 Pod Method Requirements:
/// - Must be annotated with `@Pod()`
/// - Must return the object to be registered in the container
/// - May return singletons or scoped instances depending on framework support
///
/// ---
///
/// ## 🔧 Usage Notes:
/// - Unlike `@Component`, the annotated class is **not the pod itself**, but a **pod provider**.
/// - `@Configuration` is itself a `@Component`, meaning it is also managed by the container.
/// - You may inject dependencies into the configuration class via its constructor.
///
/// ```dart
/// @Configuration()
/// class WebConfig {
///   final AppProperties props;
///
///   WebConfig(this.props);
///
///   @Pod()
///   Client httpClient() => Client(baseUrl: props.apiUrl);
/// }
/// ```
///
/// ---
///
/// ## 🆚 Configuration vs AutoConfiguration:
/// | Feature               | `@Configuration`     | `@AutoConfiguration`   |
/// |-----------------------|----------------------|-------------------------|
/// | Manual Import Needed  | ✅ Yes               | ❌ No (auto-scanned)    |
/// | Recommended Use       | App-specific config  | Library/framework setup |
/// | Lifecycle Control     | Full control         | Declarative             |
///
/// ---
///
/// ## 🛠️ Internals:
/// - Frameworks may scan `@Configuration` methods at bootstrap to build the pod graph.
/// - The class may also participate in lifecycle hooks (e.g., `@PostConstruct`, `@PreDestroy`)
///
/// ---
///
/// ## 🎯 Target:
/// - Can only be applied to **class declarations**
///
/// ```dart
/// @Configuration()
/// class CacheConfig {
///   @Pod()
///   CacheManager cache() => CacheManager();
/// }
/// ```
///
/// ---
///
/// ## 🧩 Related Annotations:
/// - `@Pod` – defines individual pods inside a configuration class
/// - `@Component` – base annotation for injectable classes
/// - `@AutoConfiguration` – auto-discovered configuration class
/// - `@Import` – (planned) to import other configuration classes
///
/// ---
/// 
/// {@endtemplate}
@Component()
@Target({TargetKind.classType})
final class Configuration extends CommonConfiguration with EqualsAndHashCode {
  /// Optional configuration name
  /// 
  /// ### Example:
  /// ```dart
  /// @Configuration('appConfig')
  /// class AppConfig {
  ///   @Pod()
  ///   Logger logger() => Logger();
  /// }
  /// ```
  final String? value;
  
  /// {@macro configuration}
  const Configuration([this.value, super.proxyPodMethods, super.scopeResolver]);
  
  @override
  String toString() => 'Configuration(value: $value, proxyPodMethods: $proxyPodMethods)';

  @override
  List<Object?> equalizedProperties() => [value, proxyPodMethods, scopeResolver];
}

// ----------------------------------------------------------------------------------------------------------
// IMPORT
// ----------------------------------------------------------------------------------------------------------

/// {@template import}
/// The `Import` annotation in **Jetleaf** is used to import other configuration classes.
/// 
/// ### Key Features:
/// - Import other configuration classes to reuse their pod definitions.
/// - Import by class type (recommended for type safety).
/// 
/// ### Usage Example (Import by ClassType):
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
/// 
/// @Configuration()
/// @Import([ClassType<DataSourceAutoConfiguration>()])
/// class AppConfig {
///   // Import DataSourceAutoConfiguration.
/// }
/// ```
/// 
/// In the example, the `Import` annotation tells Jetleaf to include the specified 
/// configuration classes, allowing you to reuse their pod definitions and 
/// configurations in your application.
/// {@endtemplate}
@Component()
@Target({TargetKind.classType})
class Import extends ReflectableAnnotation with EqualsAndHashCode {
  /// {@template import_classes}
  /// A list of configuration classes to import.
  /// 
  /// ### Example:
  /// ```dart
  /// @Configuration()
  /// @Import([ClassType<DataSourceAutoConfiguration>()])
  /// class AppConfig {
  ///   // Import DataSourceAutoConfiguration.
  /// }
  /// ```
  /// {@endtemplate}
  final List<ClassType<Object>> classes;
  
  /// {@macro import}
  const Import(this.classes);
  
  @override
  String toString() => 'Import(classes: $classes)';

  @override
  Type get annotationType => Import;

  @override
  List<Object?> equalizedProperties() => [classes];
}