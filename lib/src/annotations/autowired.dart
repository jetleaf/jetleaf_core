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

/// {@template autowired}
/// Autowired annotation for dependency injection
/// 
/// This annotation marks a field, setter, or constructor for automatic dependency injection.
/// 
/// Example Usage:
/// ```dart
/// @Service()
/// class OrderService {
///   @Autowired()
///   late UserService userService;
///   
///   @Autowired()
///   late PaymentService paymentService;
///   
///   @Autowired()
///   late InventoryService? inventoryService;
///   
///   // Constructor injection (preferred)
///   OrderService();
///   
///   Future<Order> createOrder(CreateOrderRequest request) async {
///     final user = await userService.findById(request.userId);
///     await inventoryService.reserveItems(request.items);
///     final payment = await paymentService.processPayment(request.payment);
///     
///     return Order(
///       id: generateId(),
///       userId: user.id,
///       items: request.items,
///       payment: payment,
///       createdAt: DateTime.now(),
///     );
///   }
/// }
/// ```
/// 
/// {@endtemplate}
@Target({TargetKind.field})
class Autowired extends ReflectableAnnotation {
  /// {@macro autowired}
  const Autowired();
  
  @override
  Type get annotationType => Autowired;
}


/// {@template autoinject}
/// An annotation used for dependency injection that automatically
/// injects all eligible fields into a class.
///
/// This annotation is applied at the **class level**. It tells the
/// dependency injection container to inject all non-ignored fields,
/// without requiring individual `@Autowired` annotations.
///
/// - Fields that are **non-primitive types** (classes, services, etc.)
///   are automatically injected.  
/// - Fields that are **nullable** are treated as optional.  
/// - Primitive types like `String`, `int`, or `bool` are **not**
///   automatically injected unless explicitly configured.  
///
/// ### Example
/// ```dart
/// @Service()
/// @RequiredAll()
/// class OrderService {
///   late UserService userService;       // auto-injected
///   late PaymentService paymentService; // auto-injected
///   String config;                      // not injectable (primitive)
///
///   OrderService();
/// }
///
/// void main() {
///   print(orderService.userService);       // Injected instance
///   print(orderService.paymentService);    // Injected instance
/// }
/// ```
///
/// By default, **all fields are required** unless marked as nullable.
/// This ensures strict correctness in service wiring.
/// {@endtemplate}
@Target({TargetKind.classType})
class RequiredAll extends ReflectableAnnotation {
  /// {@macro autoinject}
  ///
  /// Creates a [RequiredAll] annotation that, when applied to a class,
  /// signals the container to automatically inject all eligible fields.
  ///
  /// ### Example
  /// ```dart
  /// @Service()
  /// @RequiredAll()
  /// class EmailService {
  ///   late SmtpClient smtpClient; // Auto-injected
  ///
  ///   EmailService();
  /// }
  /// ```
  const RequiredAll();

  @override
  Type get annotationType => RequiredAll;
}

/// {@template value}
/// Value annotation for property injection
/// 
/// This annotation injects property values into fields and parameters.
/// 
/// Example Usage:
/// ```dart
/// PodExpression<String> expr = (context) {
///   return StandardPodCache("Hello, ${context.getPod("userName")}", "dart.core.String");
/// };
/// 
/// @Component()
/// class DatabaseService {
///   @Value('#{database.url}')
///   late final String databaseUrl;
///   
///   @Value('#{database.timeout:30}') // Default value 30
///   late final int timeout;
/// 
///   @Value('#{database}')
///   late final String database;
///   
///   @Value('#{database.enabled:true}')
///   late final bool enabled;
/// 
///   @Value('@{lifecycleProcessor}') // Reference to a pod
///   late final LifecycleProcessor lifecycleProcessor;
///   
///   @Value("&{systemProperties['user.home']}") // Pod expression
///   late final String userHome;
/// 
///   @Value(CustomPodExpression<String>()) // Custom pod expression
///   late final String customValue;
/// }
/// 
/// @Configuration()
/// class AppConfig {
///   @Pod()
///   DataSource dataSource(
///     @Value('#{database.url}') String url,
///     @Value('#{database.username}') String username,
///     @Value('#{database.password}') String password
///   ) {
///     return DataSource(url: url, username: username, password: password);
///   }
/// }
/// ```
/// 
/// {@endtemplate}
@Target({TargetKind.field, TargetKind.parameter})
class Value extends ReflectableAnnotation {
  /// Property expression
  final Object value;
  
  /// {@macro value}
  const Value(this.value);
  
  @override
  String toString() => 'Value(value: $value)';

  @override
  Type get annotationType => Value;
}

/// {@template target_type}
/// **TargetType Annotation**
///
/// A reflectable annotation used to declare and resolve a target class
/// type, optionally constrained by a package name.
///
/// # Purpose
/// - Acts as a metadata marker on beans, fields, or parameters to indicate
///   a specific type target.
/// - Useful for frameworks that need to resolve generic or inferred types
///   at runtime (e.g., injection points).
///
/// # Behavior
/// - Stores an optional [packageName].
/// - Provides a [get] method that constructs a [Class<T>] reference.
///   - If [packageName] is specified, the class is resolved within that
///     package.
///   - Otherwise, a generic [Class<T>] reference is created.
///
/// # Example
/// ```dart
/// @TargetType("com.example.services")
/// final TargetType<Service> serviceType = TargetType();
///
/// final clazz = serviceType.get();
/// print(clazz.getQualifiedName()); // com.example.services.Service
/// ```
///
/// # Notes
/// - The annotation type is self-describing via [annotationType].
/// - Works in tandem with reflective class loaders to identify targets.
/// {@endtemplate}
@Generic(TargetType)
@Target({TargetKind.field})
final class TargetType<T> extends ReflectableAnnotation {
  /// The optional package name for resolving the target type.
  final String? packageName;

  /// {@macro target_type}
  const TargetType([this.packageName]);

  @override
  Type get annotationType => TargetType;

  /// Resolves the target type into a [Class<T>] representation.
  Class<T> get() {
    if (packageName != null) {
      return Class<T>(null, packageName!);
    }
    return Class<T>();
  }
}

/// {@template key_value_of}
/// **KeyValueOf Annotation**
///
/// A reflectable annotation used to declare a key-value type relationship,
/// such as for maps, configuration entries, or type-safe dictionaries.
///
/// # Purpose
/// - Provides explicit metadata about both key and value types.
/// - Supports optional package scoping for each type.
/// - Used by dependency resolution or serialization frameworks where
///   generic type information is erased at runtime.
///
/// # Behavior
/// - Stores optional [kPkg] and [vPkg] (package names for key and value).
/// - Exposes [getKey] and [getValue] to resolve [Class<K>] and [Class<V>].
///
/// # Example
/// ```dart
/// @KeyValueOf("com.example.keys", "com.example.values")
/// final KeyValueOf<String, User> userMapping = KeyValueOf();
///
/// final keyClass = userMapping.getKey();
/// final valueClass = userMapping.getValue();
/// print(keyClass.getQualifiedName());   // com.example.keys.String
/// print(valueClass.getQualifiedName()); // com.example.values.User
/// ```
///
/// # Notes
/// - Provides strong typing for frameworks handling generic maps.
/// - Useful for reflection-based object factories and parsers.
/// {@endtemplate}
@Generic(KeyValueOf)
@Target({TargetKind.field})
final class KeyValueOf<K, V> extends ReflectableAnnotation {
  /// Optional package name for the key type.
  final String? kPkg;

  /// Optional package name for the value type.
  final String? vPkg;

  /// {@macro key_value_of}
  const KeyValueOf([this.kPkg, this.vPkg]);

  @override
  Type get annotationType => KeyValueOf;

  /// Resolves the key type into a [Class<K>] representation.
  Class<K> getKey() {
    if (kPkg != null) {
      return Class<K>(null, kPkg!);
    }
    return Class<K>();
  }

  /// Resolves the value type into a [Class<V>] representation.
  Class<V> getValue() {
    if (vPkg != null) {
      return Class<V>(null, vPkg!);
    }
    return Class<V>();
  }
}