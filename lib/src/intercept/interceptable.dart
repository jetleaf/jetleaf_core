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

import 'dart:async';

import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import 'method_interceptor.dart';

/// {@template method_invocator}
/// Represents a deferred executable function that performs a method invocation.
///
/// A [AsyncMethodInvocator] acts as a callable reference that, when executed,
/// performs the actual underlying method call associated with a
/// [MethodInvocation].  
///
/// This allows interceptors and advices to:
/// - Defer the original method execution.
/// - Wrap it with additional behavior (e.g., logging, caching, transactions).
/// - Replace or short-circuit the invocation entirely.
///
/// ## Example
/// ```dart
/// Future<String> invokeOriginal = () async => "Hello, there!";
///
/// final MethodInvocator<String> invocator = invokeOriginal;
///
/// final result = await invocator(); // Executes the original logic
/// print(result); // -> Hello, there!
/// ```
///
/// ## Usage
/// Typically provided to interceptors through a [MethodInvocation] context,
/// enabling dynamic control of when (or if) the target method executes.
///
/// @param T The expected return type of the method being invoked.
/// @return A [Future] result of type [T].
/// {@endtemplate}
typedef AsyncMethodInvocator<T> = Future<T> Function();

/// {@template interceptable_mixin}
/// Provides runtime interception support for method invocations within
/// JetLeaf-managed components.
///
/// The [Interceptable] mixin allows framework subsystems (such as
/// dependency injection, AOP, or lifecycle registries) to attach a
/// [MethodInterceptorDispatcher] to an object instance. This enables
/// conditional interception, augmentation, or cancellation of method
/// invocations at runtime.
///
/// ### Overview
/// When a class mixes in [Interceptable], it gains the ability to route
/// its asynchronous method calls through an interceptor pipeline before
/// execution. This is particularly useful for:
///
/// - **Cross-cutting concerns** (e.g., logging, metrics, authorization)
/// - **Aspect-oriented programming (AOP)** patterns
/// - **Dynamic proxies** and **pod wrappers**
/// - **Context-aware method dispatch** (e.g., tracing or retry policies)
///
/// The mixin does not automatically register itself with an interceptor.
/// It must be paired with a framework component.
///
/// ### How It Works
/// 1. When `when()` is called, the method checks whether `support`
///    (a [MethodInterceptorDispatcher]) has been assigned.
/// 2. If present, it delegates the call to
///    [MethodInterceptorDispatcher.when], passing:
///    - The target function
///    - The calling instance (`this`)
///    - The method name and optional [MethodArguments]
/// 3. If no interceptor is registered, it directly executes the provided
///    function, ensuring zero overhead in non-intercepted contexts.
///
/// ### Example
/// ```dart
/// class ExampleService with Interceptable {
///   Future<String> getData(String id) {
///     // Interceptable invocation
///     return when(() async {
///       return 'Fetched data for $id';
///     }, 'getData', MethodArguments([id]));
///   }
/// }
///
/// void main() async {
///   final service = ExampleService();
///
///   // Without an interceptor
///   print(await service.getData('A42')); // → Fetched data for A42
///
///   // With interceptor (e.g., injected by DefaultInterceptorRegistry)
///   service.support = LoggingMethodInterceptorDispatcher();
///   await service.getData('A42');
///   // Logs: "Intercepted call: getData([A42])"
/// }
/// ```
///
/// ### Notes
/// - Interception is **opt-in** — if `support` is `null`, `when()` behaves
///   like a direct method call.
/// - Interceptors can be **nested** or **chained** through composite
///   dispatchers.
/// - Intended primarily for **asynchronous** method interception
///   (`Future<T>` return type).
///
/// ### References
/// - [MethodInterceptorDispatcher] — Core dispatcher responsible for
///   orchestrating interceptor chains.
/// - [MethodArguments] — Container for method parameters used in
///   interception context.
/// - [AsyncMethodInvocator] — Function type signature representing
///   asynchronous method calls that can be intercepted.
/// {@endtemplate}
mixin class Interceptable implements MethodInterceptorDispatcher {
  /// Optional support for a [MethodInterceptorDispatcher].
  ///
  /// This property is typically initialized by a registry  during the component post-processing
  /// phase. When non-null, it enables interception of method calls made
  /// through the [when] method.
  @internal
  MethodInterceptorDispatcher? support;

  @override
  Future<T> when<T>(AsyncMethodInvocator<T> function, Object target, String methodName, [ExecutableArgument? arguments, Class? targetClass]) async {
    if (support != null) {
      return support!.when(function, this, methodName, arguments, targetClass);
    }

    return function();
  }
}