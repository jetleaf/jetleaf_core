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

import 'interceptable.dart';
import 'method_argument.dart';
import 'method_invocation.dart';

/// {@template method_interceptor_dispatcher}
/// Defines an advanced interception dispatcher that coordinates multiple method interceptors.
///
/// A [MethodInterceptorDispatcher] extends the standard [MethodInterceptor] contract
/// by adding a conditional dispatch mechanism. It allows interceptors to be applied
/// selectively based on dynamic context such as method hierarchy, invocation metadata,
/// or specific runtime conditions.
///
/// This interface serves as the central orchestration layer in JetLeaf’s
/// interception pipeline. It determines which interceptors should apply to a given
/// invocation and in what order, ensuring correct and predictable execution flow.
///
/// ## Responsibilities
/// - Manage ordered interceptor chains
/// - Perform conditional matching and routing
/// - Dispatch intercepted function calls with contextual control
///
/// ## Example
/// ```dart
/// class DefaultInterceptorDispatcher implements MethodInterceptorDispatcher {
///   final List<MethodInterceptor> _interceptors;
///
///   DefaultInterceptorDispatcher(this._interceptors);
///
///   @override
///   Future<T?> intercept<T>(MethodInvocation<T> invocation) {
///     return when(
///       invocation.getOriginalRequest(),
///       invocation.getTarget(),
///       0,
///       arguments: invocation.getArgument(),
///       methodName: invocation.getMethod().getName(),
///     );
///   }
///
///   @override
///   Future<T> when<T>(
///     MethodInvocator<T> function,
///     Object target,
///     int hierarchy, {
///     MethodArgument? arguments,
///     String? methodName,
///     bool? failIfNotFound = false,
///   }) async {
///     // Dispatch logic: apply interceptors conditionally based on metadata
///     for (final interceptor in _interceptors) {
///       if (interceptor.supports(target, methodName)) {
///         return await interceptor.interceptInvocation(
///           target, function, arguments, hierarchy,
///         );
///       }
///     }
///
///     if (failIfNotFound == true) {
///       throw StateError('No matching interceptor found for $methodName');
///     }
///
///     return await function();
///   }
/// }
/// ```
///
/// @see [MethodInterceptor]
/// @see [MethodInvocation]
/// {@endtemplate}
abstract interface class MethodInterceptorDispatcher {
  /// {@template MethodInterceptorDispatcher_when}
  /// Executes a function with interception support and conditional routing.
  ///
  /// This method acts as the central dispatcher that controls whether and how
  /// interceptors are applied to a particular function call. It can manage
  /// ordered chains, invoke nested interceptors, or delegate directly to the
  /// underlying function when no applicable interceptors exist.
  ///
  /// ## Parameters
  /// - [function]: The function to execute, typically the original method or a wrapped invocator.
  /// - [target]: The target object or class for which the function is being invoked.
  /// - [arguments]: (Optional) The method arguments to be passed during invocation.
  /// - [methodName]: (Optional) The name of the method being invoked, for matching or diagnostics.
  /// - [targetClass]: (Optional) The target class where the method can be found on.
  ///
  /// @return The result of the function execution, potentially modified by interceptors.
  /// {@endtemplate}
  Future<T> when<T>(AsyncMethodInvocator<T> function, Object target, String methodName, [MethodArgument? arguments, Class? targetClass]);
}

/// {@template jetleaf_method_interceptor}
/// Defines the **core interception contract** for JetLeaf’s AOP (Aspect-Oriented Programming)
/// framework, allowing runtime interception and augmentation of method invocations.
///
/// Implementations of [MethodInterceptor] can selectively intercept method calls based
/// on metadata, annotations, or execution context.  
/// Each interceptor determines its applicability via [canIntercept], enabling fine-grained
/// interception pipelines.
///
/// ### Interception Lifecycle
/// 1. JetLeaf identifies candidate interceptors for a given [Method].
/// 2. Each interceptor’s [canIntercept] is evaluated.
/// 3. Interceptors returning `true` are added to the execution chain.
/// 4. Depending on their subtype, they may act **before**, **after**, or **around**
///    the method invocation.
///
/// ### Example
/// ```dart
/// final interceptor = TransactionInterceptor();
/// if (interceptor.canIntercept(method)) {
///   await interceptor.beforeInvocation(invocation);
/// }
/// ```
///
/// ### Typical Implementations
/// - [MethodBeforeInterceptor] — execute logic before invocation.
/// - [AfterReturningInterceptor] — execute logic after successful return.
/// - [AfterThrowingInterceptor] — handle exceptions.
/// - [AfterInvocationInterceptor] — always invoked at the end.
/// - [AroundMethodInterceptor] — fully wraps invocation for total control.
///
/// ### See Also
/// - [MethodInvocation]
/// - [Class]
/// - [Method]
/// - [InterceptorChain]
/// {@endtemplate}
abstract interface class MethodInterceptor with EqualsAndHashCode {
  /// Determines whether this interceptor can intercept the specified [method].
  ///
  /// This method is invoked **before** any interception occurs to decide
  /// if the interceptor should be applied to the given method.
  ///
  /// Common filters may include:
  /// - Checking for specific annotations (e.g. `@Transactional`, `@Secured`)
  /// - Evaluating return types (`Future`, `Stream`, `void`, etc.)
  /// - Matching declaring classes or interfaces
  /// - Method visibility or naming conventions
  ///
  /// ### Parameters
  /// - [method]: The reflective metadata of the target method.
  ///
  /// ### Returns
  /// `true` if this interceptor should be applied; `false` otherwise.
  bool canIntercept(Method method);
}

/// {@template jetleaf_method_before_interceptor}
/// Defines an **interceptor** that executes logic *before* the target method
/// invocation begins.
///
/// Implementations of this interface can perform pre-processing steps such as:
/// - Security and authorization checks
/// - Logging or auditing
/// - Context or transaction initialization
///
/// ### Invocation Order
/// 1. The interceptor’s [beforeInvocation] is executed.
/// 2. If successful, the target method (or next interceptor) is invoked.
/// 3. If [beforeInvocation] throws an exception, invocation halts.
///
/// ### Example
/// ```dart
/// class LoggingInterceptor implements MethodBeforeInterceptor {
///   @override
///   bool canIntercept(Method method) => true;
///
///   @override
///   Future<void> beforeInvocation<T>(MethodInvocation<T> invocation) async {
///     print("Calling method: ${invocation.method.getName()}");
///   }
/// }
/// ```
///
/// ### See Also
/// - [MethodInterceptor]
/// - [MethodInvocation]
/// - [AroundMethodInterceptor]
/// {@endtemplate}
abstract interface class MethodBeforeInterceptor implements MethodInterceptor {
  /// Executed immediately **before** the target method invocation.
  ///
  /// May perform any synchronous or asynchronous operation.
  ///
  /// ### Parameters
  /// - [invocation]: The current [MethodInvocation] representing the call context.
  ///
  /// ### Returns
  /// A `FutureOr<void>` indicating completion of pre-invocation tasks.
  FutureOr<void> beforeInvocation<T>(MethodInvocation<T> invocation);
}

/// {@template jetleaf_after_returning_interceptor}
/// An interceptor that executes **after a method successfully returns** a value,
/// without throwing an exception.
///
/// Ideal for use cases such as:
/// - Post-processing returned data
/// - Resource cleanup after successful operations
/// - Result caching or transformation
///
/// ### Invocation Order
/// 1. The target method executes successfully.
/// 2. [afterReturning] is called with the returned value and its [Class].
///
/// ### Example
/// ```dart
/// class MetricsInterceptor implements AfterReturningInterceptor {
///   @override
///   bool canIntercept(Method method) => true;
///
///   @override
///   void afterReturning<T>(
///     MethodInvocation<T> invocation,
///     Object? returnValue,
///     Class? returnClass,
///   ) {
///     print("Method returned: $returnValue");
///   }
/// }
/// ```
///
/// ### See Also
/// - [AfterThrowingInterceptor]
/// - [AfterInvocationInterceptor]
/// - [MethodInvocation]
/// {@endtemplate}
abstract interface class AfterReturningInterceptor implements MethodInterceptor {
  /// Invoked after a successful method execution.
  ///
  /// ### Parameters
  /// - [invocation]: The current [MethodInvocation] context.
  /// - [returnValue]: The value returned by the method.
  /// - [returnClass]: The reflective type of the return value.
  /// 
  /// ### Returns
  /// A `FutureOr<void>` representing completion of post-processing.
  FutureOr<void> afterReturning<T>(MethodInvocation<T> invocation, Object? returnValue, Class? returnClass);
}

/// {@template jetleaf_after_throwing_interceptor}
/// An interceptor triggered when a target method **throws an exception**.
///
/// Used primarily for:
/// - Centralized error handling
/// - Logging and diagnostics
/// - Transaction rollback or cleanup
///
/// ### Invocation Order
/// 1. The target method throws an exception.
/// 2. [afterThrowing] is invoked with the error and its [StackTrace].
///
/// ### Example
/// ```dart
/// class ErrorLoggerInterceptor implements AfterThrowingInterceptor {
///   @override
///   bool canIntercept(Method method) => true;
///
///   @override
///   void afterThrowing<T>(
///     MethodInvocation<T> invocation,
///     Object exception,
///     Class exceptionClass,
///     StackTrace stackTrace,
///   ) {
///     print("Error in ${invocation.method.getName()}: $exception");
///   }
/// }
/// ```
///
/// ### See Also
/// - [AfterReturningInterceptor]
/// - [AfterInvocationInterceptor]
/// - [AroundMethodInterceptor]
/// {@endtemplate}
abstract interface class AfterThrowingInterceptor implements MethodInterceptor {
  /// Executed when a target method throws an exception.
  ///
  /// ### Parameters
  /// - [invocation]: The invocation context at the time of failure.
  /// - [exception]: The thrown exception.
  /// - [exceptionClass]: The reflective class of the exception.
  /// - [stackTrace]: The stack trace associated with the failure.
  ///
  /// ### Returns
  /// A `FutureOr<void>` to allow for asynchronous error handling.
  FutureOr<void> afterThrowing<T>(
    MethodInvocation<T> invocation,
    Object exception,
    Class exceptionClass,
    StackTrace stackTrace,
  );
}

/// {@template jetleaf_after_invocation_interceptor}
/// Defines an interceptor that executes **after method completion**,
/// regardless of whether the invocation succeeded or failed.
///
/// This interceptor is guaranteed to run at the end of the call chain and
/// is suitable for performing **cleanup**, **context restoration**, or
/// **finalization logic**.
///
/// ### Example
/// ```dart
/// class CleanupInterceptor implements AfterInvocationInterceptor {
///   @override
///   bool canIntercept(Method method) => true;
///
///   @override
///   Future<void> afterInvocation<T>(MethodInvocation<T> invocation) async {
///     print("Finished invoking ${invocation.method.getName()}");
///   }
/// }
/// ```
///
/// ### Execution Guarantee
/// Always executed — even if [afterReturning] or [afterThrowing] is triggered.
///
/// ### See Also
/// - [AfterReturningInterceptor]
/// - [AfterThrowingInterceptor]
/// - [AroundMethodInterceptor]
/// {@endtemplate}
abstract interface class AfterInvocationInterceptor implements MethodInterceptor {
  /// Invoked **after** the method execution completes, whether it succeeded or failed.
  ///
  /// ### Parameters
  /// - [invocation]: The [MethodInvocation] context associated with this call.
  ///
  /// ### Returns
  /// A `FutureOr<void>` indicating completion of finalization logic.
  FutureOr<void> afterInvocation<T>(MethodInvocation<T> invocation);
}

/// {@template jetleaf_around_method_interceptor}
/// A **comprehensive interceptor** that wraps the entire method invocation process,
/// allowing developers to control **when and how** the target method executes.
///
/// This is the most powerful interceptor type, capable of replacing, augmenting,
/// or conditionally bypassing method execution entirely.
///
/// ### Common Use Cases
/// - Transaction boundaries
/// - Retry mechanisms
/// - Execution time measurement
/// - Security or context wrapping
///
/// ### Example
/// ```dart
/// class TimingInterceptor implements AroundMethodInterceptor {
///   @override
///   bool canIntercept(Method method) => true;
///
///   @override
///   Future<T?> aroundInvoke<T>(MethodInvocation<T> invocation) async {
///     final start = DateTime.now();
///     final result = await invocation.proceed();
///     final end = DateTime.now();
///     print("Execution time: ${end.difference(start).inMilliseconds} ms");
///     return result;
///   }
/// }
/// ```
///
/// ### Invocation Lifecycle
/// 1. [aroundInvocation] is invoked before method execution.
/// 2. Interceptor decides whether to call `invocation.proceed()`.
/// 3. Can optionally modify the return value or handle exceptions.
///
/// ### See Also
/// - [MethodInvocation]
/// - [MethodBeforeInterceptor]
/// - [AfterReturningInterceptor]
/// - [AfterThrowingInterceptor]
/// - [AfterInvocationInterceptor]
/// {@endtemplate}
abstract interface class AroundMethodInterceptor implements MethodInterceptor {
  /// Invoked **around** the target method execution, allowing interception
  /// both before and after invocation.
  ///
  /// Implementations can fully control the invocation pipeline, including
  /// conditional execution or return substitution.
  ///
  /// ### Parameters
  /// - [invocation]: The current [MethodInvocation] representing the call context.
  ///
  /// ### Returns
  /// The method’s result, optionally modified or replaced.
  Future<T?> aroundInvocation<T>(MethodInvocation<T> invocation);
}