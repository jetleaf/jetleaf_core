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

/// JetLeaf Interception Core Library
///
/// This library provides the foundational components for JetLeaf’s
/// **Aspect-Oriented Programming (AOP)** and **method interception** system.
/// It enables dynamic interception of method calls, allowing developers to
/// apply cross-cutting concerns such as caching, transactions, validation,
/// or logging declaratively.
///
/// ## Overview
/// The interception mechanism in JetLeaf allows developers to wrap method
/// executions with custom logic using interceptor chains. This is particularly
/// useful for:
/// - Transparent caching or persistence
/// - Declarative validation and security
/// - Method-level profiling and logging
///
/// ## Key Exports
/// - **[AbstractMethodInterceptorDispatcher]** – Base class for orchestrating
///   method-level interception logic and interceptor chaining.
/// - **[ChainedMethodInterceptor]** – Utility for combining multiple
///   interceptors in a unified, ordered sequence.
/// - **[DefaultMethodInterceptor]** – Simple default implementation of a
///   method interceptor.
/// - **[Interceptable]** – Mixin that enables interception capabilities on
///   any class.
/// - **[SimpleMethodInvocation]** – Represents contextual data for a single
///   intercepted method invocation.
///
/// ## Example
/// ```dart
/// class UserService with Interceptable {
///   @LogExecution()
///   Future<String> greet(String name) async => when(() async {
///     return 'Hello, $name';
///   });
/// }
/// ```
///
/// This example shows how `Interceptable` allows JetLeaf to apply
/// method-level cross-cutting behaviors automatically.
///
/// {@category Interception}
library;

export 'src/intercept/abstract_method_dispatcher.dart';
export 'src/intercept/default_method_interceptor.dart';
export 'src/intercept/interceptable.dart';
export 'src/intercept/method_argument.dart';
export 'src/intercept/method_invocation.dart';
export 'src/intercept/method_interceptor.dart';
export 'src/intercept/intercept_registry.dart';