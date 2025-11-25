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

/// 🏷 **JetLeaf Core Annotations**
///
/// This library provides a comprehensive set of annotations for
/// JetLeaf applications, enabling declarative configuration of:
/// - Lifecycle management
/// - Dependency injection
/// - Configuration classes
/// - Conditional bean/pod registration
/// - Interception and cross-cutting concerns
/// - Component roles and stereotypes
///
/// Annotations simplify object management and support
/// compile-time and runtime processing for JetLeaf’s IoC and AOP
/// capabilities.
///
/// ## 🔑 Core Annotation Categories
///
/// ### 🔄 Lifecycle Annotations
/// - `lifecycle.dart` — annotations to define initialization,
///   destruction, or other lifecycle callbacks for pods/beans.
///
/// ### ⚡ Dependency Injection Annotations
/// - `autowired.dart` — annotations for automatic injection of
///   dependencies and qualifiers to resolve ambiguities.
///
/// ### ⚙ Configuration Annotations
/// - `configuration.dart` — annotations for marking configuration
///   classes and defining configuration behaviors.
/// - Excludes `CommonConfiguration` to avoid conflicts with base
///   configurations.
///
/// ### 🌱 Conditional Annotations
/// - `conditional.dart` — annotations for environment-based or
///   condition-based pod/bean registration.
///
/// ### 🔧 Utility Annotations
/// - `others.dart` — miscellaneous annotations for various purposes,
///   such as marking optional elements or helper metadata.
///
/// ### 🏛 Pod and Scope Annotations
/// - `pod.dart` — annotations for defining pods, their lifecycles,
///   scopes, and dependencies.
///
/// ### 🎭 Component Stereotype Annotations
/// - `stereotype.dart` — annotations to classify components by
///   architectural role, such as service, repository, or controller.
///
/// ### 🔄 Interception Annotations
/// - `intercept.dart` — annotations for method-level interception
///   and cross-cutting behavior (e.g., logging, metrics)
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to use annotations for declarative
/// configuration and management of JetLeaf application components:
///
/// ```dart
/// import 'package:jetleaf_core/annotation.dart';
///
/// @Service()
/// class UserService {
///   @Autowired()
///   late UserRepository repository;
///
///   @PostConstruct()
///   void init() {
///     // Initialization logic
///   }
/// }
/// ```
///
/// Provides a foundation for IoC, dependency injection, AOP,
/// and modular application design in JetLeaf.
///
/// {@category Annotations}
library;

/// Lifecycle management annotations for object initialization and destruction.
export 'src/annotations/lifecycle.dart';

/// Dependency injection annotations for autowiring and qualifiers.
export 'src/annotations/autowired.dart';

/// Configuration annotations for configuration classes.
export 'src/annotations/configuration.dart' hide CommonConfiguration;

/// Conditional annotations for environment-based pod registration.
export 'src/annotations/conditional.dart';

/// Miscellaneous utility annotations for various purposes.
export 'src/annotations/others.dart';

/// Pod/pod definition and scoping annotations.
export 'src/annotations/pod.dart';

/// Component stereotype annotations for architectural roles.
export 'src/annotations/stereotype.dart';

/// Intercept annotations
export 'src/annotations/intercept.dart';