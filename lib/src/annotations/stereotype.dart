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

import '../context/type_filters/type_filter.dart';
import '../scope/scope_metadata_resolver.dart';

// ----------------------------------------------------------------------------------------------------------
// COMPONENT
// ----------------------------------------------------------------------------------------------------------

/// {@template component}
/// Component annotation for generic Jet components
/// 
/// This is the most generic stereotype annotation.
/// Other annotations like @Service, @Repository are specializations of @Component.
/// 
/// Example Usage:
/// ```dart
/// @Component()
/// class EmailService {
///   final EmailProvider emailProvider;
///   
///   EmailService(this.emailProvider);
///   
///   Future<void> sendWelcomeEmail(String email) async {
///     await emailProvider.send(
///       to: email,
///       subject: 'Welcome!',
///       body: 'Welcome to our application!',
///     );
///   }
/// }
/// 
/// @Component('customValidator')
/// class CustomValidator implements Validator<String> {
///   @override
///   List<ValidationError> validate(String value, String fieldName) {
///     final errors = <ValidationError>[];
///     
///     if (value.contains('forbidden')) {
///       errors.add(ValidationError(
///         field: fieldName,
///         message: 'Value contains forbidden content',
///         rejectedValue: value,
///         validationType: 'CustomValidator',
///       ));
///     }
///     
///     return errors;
///   }
///   
///   @override
///   bool supports(Type type) => type == String;
/// }
/// ```
/// Declares a class as a **component** to be automatically detected, instantiated,
/// and managed by the dependency injection (DI) container.
///
/// The `@Component` annotation is the most **generic stereotype** used to register
/// a class as a candidate for DI. It serves as a foundational annotation from which
/// more specialized stereotypes like `@Service`, `@Repository`, and `@Controller` may derive.
///
/// ---
///
/// ## 🧩 Purpose:
/// - Enables automatic scanning and registration of classes at build or runtime.
/// - Indicates that the annotated class is a **singleton**-like pod managed by the framework.
/// - Promotes modular design and reusability by decoupling instantiation logic from usage.
///
/// ---
///
/// ## 📦 Typical Use Cases:
/// - Utility classes
/// - Service classes that do not fit under more specific roles
/// - Infrastructure or middleware components
/// - Shared helpers
///
/// ---
///
/// ## 🧪 Example:
/// ```dart
/// @Component()
/// class MyHelper {
///   void assist() => print("Helping...");
/// }
/// ```
///
/// This class will be automatically instantiated and injected wherever it’s needed.
///
/// ---
///
/// ## 🔧 Usage Notes:
/// - Components are **singleton by default**, unless otherwise scoped.
/// - Use `@Component` for generic roles; for business logic, prefer `@Service`, and
///   for data access, prefer `@Repository`, if available.
/// - Constructor injection is recommended for dependent classes:
///
/// ```dart
/// @Component()
/// class Processor {
///   final MyHelper helper;
///
///   Processor(this.helper);
///
///   void process() {
///     helper.assist();
///   }
/// }
/// ```
///
/// ---
///
/// ## 🔁 Lifecycle:
/// ```text
/// - During DI container bootstrap:
///   1. The framework scans for @Component-annotated classes.
///   2. Each is instantiated, respecting its constructor dependencies.
///   3. The instance is cached in the container.
///   4. Other pods can declare dependencies on this class.
/// ```
///
/// ---
///
/// ## 🏷️ Specializations:
/// While `@Component` is fully functional on its own, frameworks may define
/// more semantically meaningful subtypes like:
///
/// - `@Service` – for business logic and application services
/// - `@Repository` – for data access layers
/// - `@Controller` – for routing or API layers
///
/// These may provide additional behavior (e.g., AOP, transactions, naming) while still
/// inheriting core `@Component` capabilities.
///
/// ---
///
/// ## 🧱 Related Annotations:
/// - `@Service`
/// - `@Repository`
/// - `@Inject` / `@Autowired`
/// - `@Pod` / `@Configuration`
///
/// ---
///
/// ## 🎯 Target:
/// This annotation must be applied to **class declarations** only.
///
/// ```dart
/// @Component()
/// class NotificationDispatcher { ... }
/// ```
///
/// ---
///
/// ## ✅ Best Practices:
/// - Keep component responsibilities focused (single responsibility principle).
/// - Favor constructor injection over field/method injection.
/// - Combine with configuration and module patterns to enable composable application design.
///
/// ---
///
/// ## 📚 See Also:
/// - [Dependency Injection (DI)](https://en.wikipedia.org/wiki/Dependency_injection)
/// - [Inversion of Control (IoC)](https://en.wikipedia.org/wiki/Inversion_of_control)
///
/// ---
/// 
/// {@endtemplate}
@Target({TargetKind.classType})
class Component extends ReflectableAnnotation with EqualsAndHashCode {
  /// Optional component name
  /// 
  /// ### Example:
  /// ```dart
  /// @Component('customValidator')
  /// class CustomValidator implements Validator<String> {
  ///   @override
  ///   List<ValidationError> validate(String value, String fieldName) {
  ///     final errors = <ValidationError>[];
  ///     
  ///     if (value.contains('forbidden')) {
  ///       errors.add(ValidationError(
  ///         field: fieldName,
  ///         message: 'Value contains forbidden content',
  ///         rejectedValue: value,
  ///         validationType: 'CustomValidator',
  ///       ));
  ///     }
  ///     
  ///     return errors;
  ///   }
  ///   
  ///   @override
  ///   bool supports(Type type) => type == String;
  /// }
  /// ```
  final String? value;
  
  /// {@macro component}
  const Component([this.value]);
  
  @override
  String toString() => 'Component(value: $value)';

  @override
  Type get annotationType => Component;

  @override
  List<Object?> equalizedProperties() => [value];
}

// ----------------------------------------------------------------------------------------------------------
// SERVICE
// ----------------------------------------------------------------------------------------------------------

/// {@template service}
/// Service annotation for service layer components
/// 
/// This annotation marks a class as a service component.
/// It's a specialization of @Component for the service layer.
/// 
/// Example Usage:
/// ```dart
/// @Service()
/// class UserService {
///   final UserRepository userRepository;
///   final EmailService emailService;
///   
///   UserService(this.userRepository, this.emailService);
///   
///   Future<List<User>> findAll() async {
///     return userRepository.findAll();
///   }
///   
///   Future<User> findById(String id) async {
///     final user = await userRepository.findById(id);
///     if (user == null) {
///       throw NotFoundException('User not found: $id');
///     }
///     return user;
///   }
///   
///   @Transactional()
///   Future<User> create(CreateUserRequest request) async {
///     final user = User(
///       id: generateId(),
///       name: request.name,
///       email: request.email,
///       createdAt: DateTime.now(),
///     );
///     
///     final savedUser = await userRepository.save(user);
///     await emailService.sendWelcomeEmail(savedUser.email);
///     
///     return savedUser;
///   }
///   
///   @Transactional()
///   Future<User> update(String id, UpdateUserRequest request) async {
///     final existingUser = await findById(id);
///     
///     final updatedUser = existingUser.copyWith(
///       name: request.name,
///       email: request.email,
///       updatedAt: DateTime.now(),
///     );
///     
///     return userRepository.save(updatedUser);
///   }
///   
///   @Transactional()
///   Future<void> delete(String id) async {
///     final user = await findById(id);
///     await userRepository.delete(user.id);
///     await emailService.sendGoodbyeEmail(user.email);
///   }
/// }
/// ```
/// Marks a class as a **Service Component** within the dependency injection (DI) container.
///
/// The `@Service` annotation designates a class as a **singleton**, typically containing
/// **business logic**, **application use cases**, or **domain services**. These classes
/// are automatically detected, instantiated once, and injected wherever required.
///
/// It is semantically equivalent to `@Component`, but helps communicate the **role**
/// of the class more explicitly (in the spirit of Domain-Driven Design).
///
/// ---
///
/// ## 🧩 Purpose:
/// - Declare stateless, reusable business logic components
/// - Promote separation of concerns between services, repositories, and controllers
/// - Automatically register the service in the DI container
///
/// ---
///
/// ## 🧪 Example:
/// ```dart
/// @Service()
/// class UserService {
///   final UserRepository _repo;
///
///   UserService(this._repo);
///
///   User? findById(String id) => _repo.findById(id);
/// }
/// ```
///
/// The above service can now be injected:
///
/// ```dart
/// class UserController {
///   final UserService _userService;
///
///   UserController(this._userService);
/// }
/// ```
///
/// ---
///
/// ## 📦 Typical Use Cases:
/// | Type                     | Role                                                             |
/// |--------------------------|------------------------------------------------------------------|
/// | `UserService`            | Business logic for user management                              |
/// | `PaymentProcessorService`| Coordinates payment workflows                                    |
/// | `AuthService`            | Authentication/authorization utilities                          |
///
/// ---
///
/// ## 🧠 Characteristics:
/// - **Singleton Scope**: A single instance is shared across the application.
/// - **Dependency-Aware**: Can depend on other components like repositories, configurations, etc.
/// - **No side effects in constructor**: Avoid non-trivial logic in the constructor.
///
/// ---
///
/// ## 🔧 Usage Notes:
/// - You can inject this class into other services, controllers, or components.
/// - Use `@Service()` when your class contains core business logic and requires clear separation from lower-level infrastructure (like `@Repository()`).
///
/// ---
///
/// ## 🎯 Target:
/// This annotation can only be applied to **class declarations**:
///
/// ```dart
/// @Service()
/// class EmailSender {
///   void send(String email) => print('Sending to $email');
/// }
/// ```
///
/// ---
///
/// ## 🧩 Related Annotations:
/// - `@Component` – Generic DI component base
/// - `@Repository` – Specializes in persistence/data access
/// - `@Configuration` – Declares pod-producing configuration classes
/// - `@Controller` – (Optional) Marks HTTP/web-facing logic
///
/// ---
///
/// ## ✅ Best Practices:
/// - Keep `@Service` classes stateless or minimally stateful
/// - Inject required dependencies through constructor
/// - Avoid tight coupling with frameworks for better testability
///
/// ---
///
/// ## 💡 Tip:
/// If you're building your own DI container, treat `@Service()` as a specialization of `@Component()` with singleton semantics.
///
/// ---
/// 
/// {@endtemplate}
@Target({TargetKind.classType})
class Service extends ReflectableAnnotation with EqualsAndHashCode {
  /// Optional service name
  /// 
  /// ### Example:
  /// ```dart
  /// @Service('userService')
  /// class UserService {
  ///   final UserRepository _repo;
  ///
  ///   UserService(this._repo);
  ///
  ///   User? findById(String id) => _repo.findById(id);
  /// }
  /// ```
  final String? value;
  
  /// {@macro service}
  const Service([this.value]);
  
  @override
  String toString() => 'Service(value: $value)';

  @override
  Type get annotationType => Service;

  @override
  List<Object?> equalizedProperties() => [value];
}

/// {@template jetleaf_component_scan}
/// Annotation for **Jetleaf component scanning**.
///
/// `@ComponentScan` is used to instruct Jetleaf to scan specific packages
/// or classes for annotated components (e.g., `@Component`, `@Service`,
/// `@Repository`, `@Controller`) and automatically register them in the
/// application context.
///
/// ### Key Features
/// - Scans for annotated components in specified base packages or classes.
/// - Allows inclusion or exclusion of classes using filters.
/// - Supports default filters (e.g., built-in Jetleaf stereotypes).
/// - Allows customizing name generation and scope resolution.
///
/// ### Usage
/// Developers apply this annotation at the configuration class level:
///
/// ```dart
/// @ComponentScan(
///   basePackages: ['package:example/test.dart.Services', 'package:example/test.dart.Repository'],
///   includeFilters: [
///     ComponentScanFilter(
///       type: FilterType.ANNOTATION,
///       classes: [SpecialComponent],
///     )
///   ],
///   excludeFilters: [
///     ComponentScanFilter(
///       type: FilterType.REGEX,
///       pattern: '.*Internal.*'
///     )
///   ],
///   useDefaultFilters: true,
/// )
/// class MyAppConfiguration {}
/// ```
///
/// ### Notes
/// - `basePackages` and `basePackageClasses` are mutually supportive:
///   either specify string-based packages or anchor by class references.
/// - Default filters include stereotypes like `@Component`, `@Service`, etc.
/// - Advanced users can override `scopeResolver` and `nameGenerator`
///   to plug in custom resolution or naming strategies.
/// {@endtemplate}
final class ComponentScan extends ReflectableAnnotation with EqualsAndHashCode {
  /// {@macro jetleaf_component_scan}
  final List<String> basePackages;
  
  /// Base package classes (alternative to specifying string packages).
  ///
  /// This allows type-safe anchoring of base packages instead of using strings.
  final List<ClassType<Object>> basePackageClasses;
  
  /// Include filters for component scanning.
  ///
  /// These filters allow explicitly including classes that match the rules,
  /// even if they would normally be excluded.
  final List<ComponentScanFilter> includeFilters;
  
  /// Exclude filters for component scanning.
  ///
  /// These filters allow explicitly excluding classes that match the rules,
  /// even if they would normally be included.
  final List<ComponentScanFilter> excludeFilters;
  
  /// Whether to use default filters (`@Component`, `@Service`, etc.).
  ///
  /// By default, Jetleaf recognizes its core stereotypes. Setting this to `false`
  /// disables auto-detection of these annotations.
  final bool useDefaultFilters;
  
  /// Custom scope resolver class.
  ///
  /// Provides a mechanism to determine the lifecycle scope of discovered components.
  final ScopeMetadataResolver? scopeResolver;
  
  /// Custom name generator class.
  ///
  /// Provides a mechanism to assign unique names to discovered components.
  final PodNameGenerator? nameGenerator;

  /// {@macro jetleaf_component_scan}
  const ComponentScan({
    this.basePackages = const [],
    this.basePackageClasses = const [],
    this.includeFilters = const [],
    this.excludeFilters = const [],
    this.useDefaultFilters = true,
    this.scopeResolver,
    this.nameGenerator,
  });

  @override
  Type get annotationType => ComponentScan;

  @override
  List<Object?> equalizedProperties() => [
    basePackages,
    basePackageClasses,
    includeFilters,
    excludeFilters,
    useDefaultFilters,
    scopeResolver,
    nameGenerator,
  ];
}

/// {@template jetleaf_component_scan_filter}
/// Represents a filter definition for component scanning.
///
/// `ComponentScanFilter` provides fine-grained control over which
/// classes should be included or excluded during the scanning process.
///
/// ### Filter Types
/// - `FilterType.ANNOTATION` → Matches classes annotated with specific annotations.
/// - `FilterType.ASSIGNABLE` → Matches classes assignable to given types.
/// - `FilterType.REGEX` → Matches classes based on regex patterns.
/// - `FilterType.CUSTOM` → Uses a custom [`TypeFilter`] implementation.
///
/// ### Usage
/// ```dart
/// const myFilter = ComponentScanFilter(
///   type: FilterType.ANNOTATION,
///   classes: [MyCustomAnnotation],
/// );
/// ```
///
/// ### Notes
/// - Multiple filters can be combined in `includeFilters` and `excludeFilters`.
/// - For complex logic, use `FilterType.CUSTOM` with a custom `TypeFilter`.
/// {@endtemplate}
class ComponentScanFilter with EqualsAndHashCode {
  /// The type of filter to apply during scanning.
  final FilterType type;

  /// Classes associated with the filter.
  ///
  /// Used for annotation-based or assignable-type filters.
  final List<ClassType<Object>> classes;

  /// Optional regex pattern for matching class names.
  final String? pattern;

  /// Custom filter implementation when `FilterType.CUSTOM` is used.
  final TypeFilter? typeFilter;
  
  /// {@macro jetleaf_component_scan_filter}
  const ComponentScanFilter(this.type, {this.classes = const [], this.pattern, this.typeFilter});

  @override
  List<Object?> equalizedProperties() => [
    type,
    classes,
    pattern,
    typeFilter,
  ];
}

/// {@template jetleaf_filter_type}
/// Enumeration of supported filter types for component scanning.
///
/// ### Values
/// - `ANNOTATION`: Matches classes annotated with given annotations.
/// - `ASSIGNABLE`: Matches classes assignable to given types.
/// - `REGEX`: Matches classes whose names match a regex pattern.
/// - `CUSTOM`: Uses a custom `TypeFilter` implementation.
/// {@endtemplate}
enum FilterType {
  /// Matches classes annotated with given annotations.
  ANNOTATION,

  /// Matches classes assignable to given types.
  ASSIGNABLE,

  /// Matches classes whose names match a regex pattern.
  REGEX,

  /// Uses a custom `TypeFilter` implementation.
  CUSTOM;
}