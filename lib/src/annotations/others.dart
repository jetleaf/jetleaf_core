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

/// {@template qualifier}
/// A Jetleaf annotation used to disambiguate injection targets
/// when multiple candidate pods of the same type exist.
///
/// By default, Jetleaf performs **type-based autowiring**. When more than
/// one pod matches the required type, you can use `@Qualifier` to select
/// the correct one by:
/// 
/// - **Name** → using [name] with the registered pod name.
///
/// ### When to Use
/// - Multiple implementations of the same interface exist.
/// - A pod must inject a *specific instance*.
/// - You want to inject by name instead of type.
///
/// ### Example — Field Injection
/// ```dart
/// abstract class Notifier {
///   Future<void> send(String message);
/// }
///
/// @Service()
/// class NotificationService {
///   @Autowired()
///   @Qualifier("emailNotifier")
///   late final Notifier emailNotifier;
///
///   @Autowired()
///   @Qualifier("smsNotifier")
///   late final Notifier smsNotifier;
///
///   Future<void> sendNotification(String message, NotificationType type) async {
///     switch (type) {
///       case NotificationType.email:
///         await emailNotifier.send(message);
///         break;
///       case NotificationType.sms:
///         await smsNotifier.send(message);
///         break;
///     }
///   }
/// }
///
/// @Service("smsNotifier")
/// class SmsNotifier implements Notifier {
///   @override
///   Future<void> send(String message) async {
///     // send SMS logic
///   }
/// }
///
/// class EmailNotifier implements Notifier {
///   @override
///   Future<void> send(String message) async {
///     // send email logic
///   }
/// }
/// ```
///
/// ### Example — Constructor Parameter
/// ```dart
/// @Service()
/// class UserService {
///   @Qualifier("emailNotifier") 
///   final Notifier notifier;
///
///   UserService(this.notifier);
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.field, TargetKind.parameter})
class Qualifier extends ReflectableAnnotation with EqualsAndHashCode {
  /// The pod name to qualify the injection target.
  ///
  /// Prefer this when you want to inject a specific **named pod**.
  ///
  /// Example:
  /// ```dart
  /// @Qualifier("smsNotifier")
  /// ```
  final String value;

  /// {@macro qualifier}
  const Qualifier([this.value = '']);

  @override
  String toString() => 'Qualifier(value: $value)';

  @override
  Type get annotationType => Qualifier;

  @override
  List<Object?> equalizedProperties() => [value];
}

// ----------------------------------------------------------------------------------------------------------
// LAZY
// ----------------------------------------------------------------------------------------------------------

/// {@template lazy}
/// Indicates that a pod should be lazily initialized.
///
/// By default, pods are created eagerly at context startup.
/// Applying `@Lazy()` will delay pod creation until it is first requested,
/// improving startup performance or avoiding unnecessary initialization.
///
/// ### Example
/// ```dart
/// @Lazy()
/// class ExpensiveService {}
///
/// @Lazy(false)
/// class AlwaysEagerService {}
/// ```
///
/// - Setting `value` to `true` enables lazy initialization (default).
/// - Setting `value` to `false` disables lazy initialization explicitly.
/// {@endtemplate}
@Target({TargetKind.classType})
class Lazy extends ReflectableAnnotation with EqualsAndHashCode {
  /// Whether the pod should be lazy
  /// 
  /// ### Example:
  /// ```dart
  /// @Lazy()
  /// class ExpensiveService {}
  /// 
  /// @Lazy(false)
  /// class AlwaysEagerService {}
  /// ```
  final bool value;
  
  /// {@macro lazy}
  const Lazy([this.value = true]);
  
  @override
  String toString() => 'Lazy(value: $value)';

  @override
  Type get annotationType => Lazy;

  @override
  List<Object?> equalizedProperties() => [value];
}

// ----------------------------------------------------------------------------------------------------------
// ORDER
// ----------------------------------------------------------------------------------------------------------

/// {@template order}
/// Specifies the **order of precedence** for a class when processed by
/// the framework or runtime system.
///
/// The `@Order` annotation provides deterministic ordering for components such as:
/// - Middleware
/// - Interceptors
/// - Initializers
/// - Filters
/// - Event handlers
///
/// The **lower the value**, the **higher the priority**. That is, `@Order(0)` runs
/// before `@Order(1)`, and so on.
///
/// ---
///
/// ## 🔁 Execution Order Rules:
/// - **Ascending Order**: Lower `value` means earlier execution.
/// - If two components have the same `@Order`, their relative order is undefined
///   unless explicitly handled by the framework.
/// - Classes without `@Order` may be given a **default priority**, e.g., `@Order(1000)`
///   or treated as "last".
///
/// ---
///
/// ## 🧪 Example:
/// ```dart
/// @Order(1)
/// class FirstMiddleware {}
/// 
/// @Order(2)
/// class SecondMiddleware {}
/// 
/// @Order(0)
/// class HighestPriority {}
/// ```
///
/// In this example, the order of invocation would be:
/// 1. `HighestPriority`
/// 2. `FirstMiddleware`
/// 3. `SecondMiddleware`
///
/// ---
///
/// ## 🧱 Common Use Cases:
/// | Use Case              | Why `@Order` Helps                        |
/// |-----------------------|--------------------------------------------|
/// | Middleware Chains     | Defines filter/interceptor execution flow |
/// | Plugin Systems        | Ensures predictable hook registration      |
/// | Application Phases    | Orders startup or shutdown hooks          |
/// | Event Listeners       | Prioritizes listeners in a dispatch tree   |
///
/// ---
///
/// ## 🔧 Usage Notes:
/// - `@Order` must be placed on **class declarations only**.
/// - Typically interpreted by the **container**, **registry**, or **dispatcher** at runtime or compile-time.
/// - It is framework-agnostic, but effective only if the underlying system respects the ordering logic.
///
/// ---
///
/// ## 🎯 Target:
/// This annotation applies to **classes only**:
///
/// ```dart
/// @Order(10)
/// class AuditLoggerInterceptor {}
/// ```
///
/// ---
///
/// ## 🧩 Related Patterns:
/// - Chain of Responsibility
/// - Interceptor / Middleware
/// - Application lifecycle hooks (e.g., startup, shutdown)
///
/// ---
///
/// ## 🔄 Integration Tip:
/// Frameworks can use this annotation to sort registered components:
///
/// ```dart
/// final List<Object> ordered = components
///     .whereType<HasOrder>()
///     .toList()
///   ..sort((a, b) => a.order.compareTo(b.order));
/// ```
///
/// Consider defining a common interface like `HasOrder` to extract the `value`:
///
/// ```dart
/// abstract class HasOrder {
///   int get order;
/// }
/// ```
///
/// ---
///
/// ## ✅ Best Practices:
/// - Use low values (`0–10`) for essential/core logic.
/// - Use mid-range values (`50–100`) for application-level logic.
/// - Avoid overusing `@Order` — prefer natural dependency ordering when possible.
/// - Combine with composition or configuration patterns for more flexibility.
///
/// ---
/// 
/// {@endtemplate}
@Target({TargetKind.classType})
class Order extends ReflectableAnnotation with EqualsAndHashCode {
  /// The precedence value.
  /// Classes with lower values are executed first.
  /// 
  /// ### Example:
  /// ```dart
  /// @Order(1)
  /// class FirstMiddleware {}
  /// 
  /// @Order(2)
  /// class SecondMiddleware {}
  /// 
  /// @Order(0)
  /// class HighestPriority {}
  /// ```
  final int value;

  /// {@macro order}
  const Order(this.value);

  @override
  Type get annotationType => Order;

  @override
  List<Object?> equalizedProperties() => [value];
}

// ----------------------------------------------------------------------------------------------------------
// PRIMARY
// ----------------------------------------------------------------------------------------------------------

/// {@template primary}
/// Primary annotation for marking a primary pod
/// 
/// This annotation marks a pod as primary when multiple pods of the same type exist.
/// 
/// Example Usage:
/// ```dart
/// @Configuration()
/// class PaymentConfig {
///   @Pod()
///   @Primary()
///   PaymentProcessor primaryPaymentProcessor() {
///     return StripePaymentProcessor();
///   }
///   
///   @Pod('paypalProcessor')
///   PaymentProcessor paypalPaymentProcessor() {
///     return PayPalPaymentProcessor();
///   }
/// }
/// ```
/// 
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class Primary extends ReflectableAnnotation {
  /// {@macro primary}
  const Primary();
  
  @override
  String toString() => 'Primary()';

  @override
  Type get annotationType => Primary;
}

// ----------------------------------------------------------------------------------------------------------
// PROFILE
// ----------------------------------------------------------------------------------------------------------

/// {@template profile}
/// Profile annotation for profile-specific pods
/// 
/// This annotation indicates that a component is only eligible
/// for registration when specific profiles are active.
/// 
/// Example Usage:
/// ```dart
/// @Component()
/// @Profile(['development'])
/// class DevDatabaseService implements DatabaseService {
///   // Only active in development profile
/// }
/// 
/// @Component()
/// @Profile(['production'])
/// class ProdDatabaseService implements DatabaseService {
///   // Only active in production profile
/// }
/// 
/// @Configuration()
/// @Profile(['test', 'integration'])
/// class TestConfig {
///   // Configuration only for test or integration profiles
///   
///   @Pod()
///   MockService mockService() {
///     return MockService();
///   }
/// }
/// 
/// @Component()
/// @Profile(['!production']) // Not in production
/// class DebugService {
///   // Active in all profiles except production
/// }
/// ```
/// 
/// {@endtemplate}
@Target({TargetKind.classType})
class Profile extends ReflectableAnnotation with EqualsAndHashCode {
  /// Profile expressions
  /// 
  /// ### Example:
  /// ```dart
  /// @Component()
  /// @Profile(['development'])
  /// class DevDatabaseService implements DatabaseService {
  ///   // Only active in development profile
  /// }
  /// ```
  final List<String> profiles;

  /// Whether to negate the profile expression
  /// 
  /// ### Example:
  /// ```dart
  /// @Component()
  /// @Profile(['!production']) // Not in production
  /// class DebugService {
  ///   // Active in all profiles except production
  /// }
  /// ```
  final bool negate;
  
  /// {@macro profile}
  const Profile(this.profiles, {this.negate = false});
  
  /// Create a profile annotation that excludes certain profiles
  /// 
  /// ## 🎯 Target:
  /// Can only be applied to classes:
  /// 
  /// ### Example:
  /// ```dart
  /// @Component()
  /// @Profile.not(['production'])
  /// class DebugService {
  ///   // Active in all profiles except production
  /// }
  /// ```
  const Profile.not(List<String> profiles) : this(profiles, negate: true);
  
  @override
  String toString() => 'Profile(profiles: $profiles)';

  @override
  Type get annotationType => Profile;

  @override
  List<Object?> equalizedProperties() => [profiles, negate];
}

// ----------------------------------------------------------------------------------------------------------
// SCOPE
// ----------------------------------------------------------------------------------------------------------

/// {@template scope}
/// Annotation that specifies the scope of a pod within the JetLeaf container.
///
/// Use this to indicate whether a new instance should be created for each injection
/// (`'prototype'`) or a single shared instance should be used (`'singleton'`).
///
/// ### Example:
/// ```dart
/// @Component()
/// @Scope('singleton')
/// class SingletonService {
///   // This service is shared across all injections
/// }
///
/// @Component()
/// @Scope('prototype')
/// class PrototypeService {
///   // A new instance is created for each injection point
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class Scope extends ReflectableAnnotation with EqualsAndHashCode {
  /// Scope name
  final String value;
  
  /// {macro scope}
  const Scope(this.value);
  
  @override
  String toString() => 'Scope(value: $value)';

  @override
  Type get annotationType => Scope;

  @override
  List<Object?> equalizedProperties() => [value];
}

// ----------------------------------------------------------------------------------------------------------
// PRE DESTROY
// ----------------------------------------------------------------------------------------------------------

/// {@template predestroy}
/// Marks a method to be invoked **before a pod is destroyed**.
///
/// Jetleaf automatically detects methods annotated with `@PreDestroy`
/// and calls them during **pod shutdown** or **context close**.  
///
/// This is typically used for:
/// - Releasing resources (database connections, sockets, file handles).
/// - Stopping background workers.
/// - Flushing in-memory caches.
///
/// ### Rules
/// - Must be a **no-arg method**.
/// - Return type should be `void` or `Future<void>`.
/// - Only applied to methods (not classes or fields).
///
/// ### Example — Synchronous Cleanup
/// ```dart
/// @Service()
/// class CacheManager {
///   final _cache = <String, String>{};
///
///   void put(String key, String value) => _cache[key] = value;
///
///   @PreDestroy()
///   void clearCache() {
///     print("Clearing cache before shutdown...");
///     _cache.clear();
///   }
/// }
/// ```
///
/// ### Example — Asynchronous Cleanup
/// ```dart
/// @Service()
/// class WorkerPool {
///   final _workers = <Worker>[];
///
///   @PreDestroy()
///   Future<void> shutdownWorkers() async {
///     for (final worker in _workers) {
///       await worker.stop();
///     }
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
class PreDestroy extends ReflectableAnnotation {
  /// {@macro predestroy}
  const PreDestroy();

  @override
  Type get annotationType => PreDestroy;
}

// ----------------------------------------------------------------------------------------------------------
// CLEAN UP
// ----------------------------------------------------------------------------------------------------------

/// {@template cleanup}
/// Marks a method to be invoked **after a pod is destroyed**.
///
/// Jetleaf automatically detects methods annotated with `@Cleanup`
/// and calls them after **pod shutdown** or **context close**.  
///
/// This is typically used for:
/// - Releasing resources (database connections, sockets, file handles).
/// - Stopping background workers.
/// - Flushing in-memory caches.
///
/// ### Rules
/// - Must be a **no-arg method**.
/// - Return type should be `void` or `Future<void>`.
/// - Only applied to methods (not classes or fields).
///
/// ### Example — Synchronous Cleanup
/// ```dart
/// @Service()
/// class CacheManager {
///   final _cache = <String, String>{};
///
///   void put(String key, String value) => _cache[key] = value;
///
///   @Cleanup()
///   void clearCache() {
///     print("Clearing cache after shutdown...");
///     _cache.clear();
///   }
/// }
/// ```
///
/// ### Example — Asynchronous Cleanup
/// ```dart
/// @Service()
/// class WorkerPool {
///   final _workers = <Worker>[];
///
///   @Cleanup()
///   Future<void> shutdownWorkers() async {
///     for (final worker in _workers) {
///       await worker.stop();
///     }
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
class Cleanup extends ReflectableAnnotation {
  /// {@macro cleanup}
  const Cleanup();

  @override
  Type get annotationType => Cleanup;
}

// ----------------------------------------------------------------------------------------------------------
// PRE CONSTRUCT
// ----------------------------------------------------------------------------------------------------------

/// {@template preconstruct}
/// Marks a method to be invoked **before a pod has been fully constructed
/// and its dependencies injected**, but **before it is made available
/// for use in the context**.
///
/// This is typically used for:
/// - Initialization logic that depends on injected fields.
/// - Validating configuration.
/// - Opening resources (like database connections).
///
/// ### Rules
/// - Must be a **no-arg method**.
/// - Return type should be `void` or `Future<void>`.
/// - Only applied to methods (not classes or fields).
///
/// ### Example — Synchronous Initialization
/// ```dart
/// @Service()
/// class CacheManager {
///   final _cache = <String, String>{};
///
///   void put(String key, String value) => _cache[key] = value;
///
///   @PreConstruct()
///   void init() {
///     print("Initializing cache from database...");
///     _cache = Cache.loadFrom(dataSource);
///   }
/// }
/// ```
///
/// ### Example — Asynchronous Initialization
/// ```dart
/// @Service()
/// class WorkerPool {
///   final _workers = <Worker>[];
///
///   @PreConstruct()
///   Future<void> initWorkers() async {
///     for (final worker in _workers) {
///       await worker.start();
///     }
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
class PreConstruct extends ReflectableAnnotation {
  /// {@macro preconstruct}
  const PreConstruct();

  @override
  Type get annotationType => PreConstruct;
}

// ----------------------------------------------------------------------------------------------------------
// POST CONSTRUCT
// ----------------------------------------------------------------------------------------------------------

/// {@template postconstruct}
/// Marks a method to be invoked **after a pod has been fully constructed
/// and its dependencies injected**, but **before it is made available
/// for use in the context**.
///
/// This is typically used for:
/// - Initialization logic that depends on injected fields.
/// - Validating configuration.
/// - Opening resources (like database connections).
///
/// ### Rules
/// - Must be a **no-arg method**.
/// - Return type should be `void` or `Future<void>`.
/// - Only applied to methods (not classes or fields).
///
/// ### Example — Synchronous Initialization
/// ```dart
/// @Service()
/// class CacheManager {
///   late final Cache _cache;
///
///   @Autowired()
///   late final DataSource dataSource;
///
///   @PostConstruct()
///   void init() {
///     print("Initializing cache from database...");
///     _cache = Cache.loadFrom(dataSource);
///   }
/// }
/// ```
///
/// ### Example — Asynchronous Initialization
/// ```dart
/// @Service()
/// class WorkerPool {
///   final _workers = <Worker>[];
///
///   @PostConstruct()
///   Future<void> startWorkers() async {
///     for (var i = 0; i < 4; i++) {
///       final worker = Worker();
///       await worker.start();
///       _workers.add(worker);
///     }
///   }
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.method})
class PostConstruct extends ReflectableAnnotation {
  /// {@macro postconstruct}
  const PostConstruct();

  @override
  Type get annotationType => PostConstruct;
}

/// {@template dependson}
/// A Jetleaf annotation that declares **explicit dependencies**
/// between pods.
///
/// By default, Jetleaf resolves dependencies automatically based on
/// injection points. Use `@DependsOn` when you need to enforce
/// **initialization order** or guarantee that certain infrastructure pods
/// are created before the annotated pod.
///
/// ### Key Features:
/// - Ensures initialization order in complex graphs.
/// - Can declare multiple dependencies.
/// - Works on both classes and methods.
///
/// ### Example:
/// ```dart
/// @Component()
/// @DependsOn("emailNotifier", "databaseService"])
/// class ApplicationService {
///   // This service will be initialized after DatabaseService and CacheService
/// }
/// ```
///
/// ### Method-level Example:
/// ```dart
/// class ConfigCombined {
///   @Pod()
///   @DependsOn("connectionPool", ClassType<ConnectionPool>()])
///   DatabaseClient databaseClient() => DatabaseClient();
/// }
/// ```
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class DependsOn extends ReflectableAnnotation with EqualsAndHashCode {
  /// The list of [Object] pods/[ClassType] that must be created first.
  final List<Object> names;

  /// {@macro dependson}
  const DependsOn(this.names);

  @override
  String toString() => 'DependsOn(value: $names)';

  @override
  Type get annotationType => DependsOn;

  @override
  List<Object?> equalizedProperties() => [names];
}

/// {@template role}
/// Declares the **design role** of a class or method within a Jetleaf
/// application.
///
/// This annotation is intended for **design-time metadata** and
/// architectural documentation. It can also be used by tooling
/// (e.g., code generators, analyzers) to enforce architectural rules.
///
/// ### Example
/// ```dart
/// @Role(DesignRole.APPLICATION)
/// class UserService {
///   Future<User> findById(String id) {
///     // business logic here
///   }
/// }
///
/// @Role(DesignRole.APPLICATION)
/// class UserController {
///   final UserService service;
///
///   UserController(this.service);
///
///   @Get('/users/:id')
///   Future<User> getUser(String id) => service.findById(id);
/// }
/// ```
///
/// > **Note:** `@Role` is not required for Jetleaf runtime behavior,
/// but it is highly recommended for clarity and tooling support.
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class Role extends ReflectableAnnotation with EqualsAndHashCode {
  /// {@macro design_role}
  final DesignRole value;

  /// {@macro role}
  const Role(this.value);

  @override
  String toString() => 'Role(value: $value)';

  @override
  Type get annotationType => Role;

  @override
  List<Object?> equalizedProperties() => [value];
}

/// {@template description}
/// Provides a **human-readable description** of a class or method.
///
/// This annotation is often paired with `@Role` to give additional
/// context to maintainers, API documentation tools, or automated
/// diagram generators.
///
/// ### Example
/// ```dart
/// @Role(DesignRole.service)
/// @Description('Handles user-related business operations')
/// class UserService {
///   Future<User> findById(String id) {
///     // business logic here
///   }
/// }
///
/// @Role(DesignRole.controller)
/// @Description('REST API endpoint for user management')
/// class UserController {
///   final UserService service;
///
///   UserController(this.service);
///
///   @Get('/users/:id')
///   @Description('Fetches a user by its unique identifier')
///   Future<User> getUser(String id) => service.findById(id);
/// }
/// ```
///
/// > **Tip:** Use `@Description` to generate structured documentation
/// or to improve readability in IDE tooling.
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class Description extends ReflectableAnnotation with EqualsAndHashCode {
  /// {@macro description}
  final String value;

  /// {@macro description}
  const Description(this.value);

  @override
  String toString() => 'Description(value: $value)';

  @override
  Type get annotationType => Description;

  @override
  List<Object?> equalizedProperties() => [value];
}

/// {@template jetleaf_named_annotation}
/// Explicitly specifies a name for a Pod (Dependency Injection component) that overrides
/// all other naming mechanisms in the Jetleaf framework.
///
/// This annotation provides the highest precedence for Pod naming and can be
/// applied to both classes and methods to explicitly define how they should
/// be registered and referenced in the application context.
///
/// ### Naming Precedence Hierarchy
/// When multiple naming mechanisms are available, `@Named` takes precedence in this order:
/// 1. **@Named** (highest precedence - explicit override)
/// 2. **@Component.name** and related stereotype annotations
/// 3. **@Pod.name** for configuration methods
///
/// ### Usage Scenarios
/// - **Explicit Pod Identification**: When you need specific, predictable Pod names
/// - **Disambiguation**: When multiple Pods of the same type exist and need distinct names
/// - **Configuration Override**: When you want to override default naming conventions
/// - **Integration**: When integrating with systems that require specific Pod identifiers
///
/// ### Target Support
/// This annotation can be applied to:
/// - **Classes**: To name the Pod created from the class instance
/// - **Methods**: To name the Pod returned by a configuration method
///
/// ### Example
/// ```dart
/// // Class-level usage - names the UserService Pod as 'userService'
/// @Named('userService')
/// @Service()
/// class UserService {
///   // Implementation...
/// }
///
/// // Method-level usage - names the DataSource Pod as 'primaryDataSource'
/// @Configuration()
/// class DataSourceConfig {
///   @Named('primaryDataSource')
///   @Pod()
///   DataSource createDataSource() {
///     return DataSource();
///   }
/// }
/// ```
///
/// ### Framework Behavior
/// - **Registration**: Pods annotated with `@Named` are registered with the specified name
/// - **Lookup**: Dependency injection uses the explicit name for resolution
/// - **Validation**: Duplicate Pod names will cause application startup failures
/// - **Reflection**: The name is available via reflection for framework components
///
/// ### Best Practices
/// - Use descriptive, meaningful names that indicate the Pod's purpose
/// - Follow consistent naming conventions across your application
/// - Consider using constants for Pod names to avoid typos
/// - Document why explicit naming is needed when used
///
/// ### Related Annotations
/// - [@Pod] - Declares a method as producing a Pod
/// - [@Service] - Stereotype annotation for service layer Pods
/// - [@Repository] - Stereotype annotation for data access layer Pods
/// - [@Component] - Generic stereotype annotation for any Pod
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class Named extends ReflectableAnnotation with EqualsAndHashCode {
  /// The explicit name to use for this Pod in the application context.
  ///
  /// This name must be unique within the application context and will be used
  /// for all Pod registration, lookup, and dependency resolution operations.
  ///
  /// ### Naming Guidelines
  /// - Use camelCase convention (e.g., 'userService', 'dataSource')
  /// - Be descriptive but concise
  /// - Avoid special characters and spaces
  /// - Consider the Pod's role and responsibility
  ///
  /// ### Example
  /// ```dart
  /// @Named('userRepository')  // Good - clear and descriptive
  /// @Named('usrRepo')         // Less ideal - abbreviated and unclear
  /// @Named('user-repository') // Invalid - contains hyphen
  /// ```
  final String name;

  /// Creates a `@Named` annotation with the specified Pod name.
  ///
  /// ### Parameters
  /// - [name]: The unique name to assign to this Pod in the application context
  ///
  /// ### Example
  /// ```dart
  /// @Named('emailService')
  /// class EmailService {
  ///   // This Pod will be registered as 'emailService'
  /// }
  /// ```
  /// 
  /// {@macro jetleaf_named_annotation}
  const Named(this.name);

  @override
  Type get annotationType => Named;

  @override
  List<Object?> equalizedProperties() => [name];

  @override
  String toString() => "Named($name)";
}