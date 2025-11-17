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

import 'interceptable.dart';
import 'method_argument.dart';

/// {@template method_invocation}
/// Represents a reflective method invocation within the interception pipeline.
///
/// The [MethodInvocation] interface abstracts the context of a method call,
/// encapsulating the target object, method metadata, arguments, and the
/// executable request itself. It serves as the central contract between
/// JetLeaf’s intercept framework and its interceptors.
///
/// Each method call intercepted by the framework is represented as a
/// [MethodInvocation] instance, allowing interceptors and advices to:
/// - Inspect or modify arguments before invocation
/// - Execute pre- or post-invocation logic
/// - Replace or short-circuit the method call entirely
///
/// ## Example
/// ```dart
/// class LoggingInterceptor implements MethodInterceptor {
///   @override
///   Future<Object?> invoke(MethodInvocation invocation) async {
///     print('Invoking: ${invocation.getMethod().getName()}');
///     final result = await invocation.getOriginalRequest()();
///     print('Completed: ${invocation.getMethod().getName()}');
///     return result;
///   }
/// }
/// ```
///
/// @see [MethodArgument]
/// @see [AsyncMethodInvocator]
/// {@endtemplate}
abstract interface class MethodInvocation<T> implements Flushable {
  /// {@template MethodInvocation_getTarget}
  /// Retrieves the target object on which the method is being invoked.
  ///
  /// For instance methods, this returns the actual object instance.
  /// For static methods or constructors, this may return a class-level
  /// target or a context object representing the invocation origin.
  ///
  /// @return The invocation target object
  /// {@endtemplate}
  Object getTarget();

  /// {@template MethodInvocation_getTargetClass}
  /// Retrieves the reflective class metadata of the target object.
  ///
  /// This provides access to the [Class] abstraction, which includes
  /// annotations, superclass hierarchy, interfaces, and modifiers.
  /// Useful for making class-level decisions in interceptors.
  ///
  /// @return The [Class] metadata of the invocation target
  /// {@endtemplate}
  Class getTargetClass();

  /// {@template MethodInvocation_getMethod}
  /// Retrieves the method metadata for the current invocation.
  ///
  /// Provides access to the method's name, return type, parameters,
  /// annotations, and modifiers, enabling introspection and
  /// fine-grained interception control.
  ///
  /// @return The [Method] metadata of the invoked method
  /// {@endtemplate}
  Method getMethod();

  /// {@template MethodInvocation_getArgument}
  /// Retrieves the structured arguments for the method invocation.
  ///
  /// Returns a [MethodArgument] instance containing both positional
  /// and named arguments. Interceptors can read or modify these
  /// arguments before invoking the original method.
  ///
  /// @return The [MethodArgument] instance or null if none are present
  /// {@endtemplate}
  MethodArgument? getArgument();

  /// Indicates whether the target method has already been invoked
  /// within the current operation context.
  ///
  /// ### Returns
  /// `true` if [proceed()] has been called and the method execution
  /// has started or completed; `false` otherwise.
  ///
  /// ### Usage
  /// ```dart
  /// if (!context.isInvoked()) {
  ///   await context.proceed();
  /// }
  /// ```
  ///
  /// ### Notes
  /// - This can be used to prevent multiple invocations of the same
  ///   method within a single interception context.
  /// - Useful in caching or rate-limiting interceptors to ensure
  ///   the original method is only executed once per context.
  bool isInvoked();

  /// {@template invocation_proceed}
  /// Proceeds with the execution of the target method or operation.
  ///
  /// This method invokes the actual method that the current interception
  /// context is wrapping (e.g., a method annotated for caching, rate-limiting,
  /// or logging). It should be called **after all pre-processing** steps,
  /// such as validation, condition checks, or key generation, have completed.
  ///
  /// ### Parameters
  /// - [retry]: Optional flag indicating whether this invocation is a retry
  ///   attempt. Default is `false`.
  ///
  /// ### Returns
  /// A [Future] that resolves to the result of the target method invocation.
  /// The generic type [T] corresponds to the return type of the intercepted method.
  ///
  /// ### Usage
  /// ```dart
  /// final result = await invocation.proceed();
  /// context.setResult(result);
  /// ```
  ///
  /// ### Notes
  /// - This method should only be called **once per invocation context** unless
  ///   explicitly retried.
  /// - Exceptions thrown by the target method propagate through the returned
  ///   [Future] unless caught or handled.
  /// - When [retry] is `true`, the method may be invoked again with the same
  ///   context after a reset.
  /// {@endtemplate}
  Future<T> proceed([bool retry = false]);

  /// {@template invocation_hijack}
  /// Immediately short‑circuits the invocation pipeline by supplying a custom
  /// return value.
  ///
  /// The `hijack` method allows an interceptor, advice, or wrapper to **bypass
  /// the execution of the target method entirely**. When invoked, the
  /// interception context is considered completed, and the provided [value] is
  /// treated as the final result of the method invocation.
  ///
  /// This is commonly used in scenarios such as:
  /// - Returning cached results without calling the underlying method
  /// - Enforcing access controls by preventing method execution
  /// - Providing fallback responses
  /// - Halting execution due to validation failures or preconditions
  ///
  /// ### Parameters
  /// - [value]: The value that should be treated as the official return value
  ///   of the intercepted method.  
  ///   Must match the generic type [T], the method’s declared return type.
  ///
  /// ### Behavior
  /// - Once `hijack` is called:
  ///   - The method **will not be executed**, even if `proceed()` has not yet been called.
  ///   - Any remaining interceptors in the chain are skipped.
  ///   - The invocation is marked as completed.
  /// - Any attempt to call `proceed()` after `hijack()` is considered invalid,
  ///   and may throw depending on the invocation engine.
  ///
  /// ### Usage Example
  /// ```dart
  /// if (cache.contains(key)) {
  ///   return invocation.hijack(cache.get(key));
  /// }
  ///
  /// final result = await invocation.proceed();
  /// cache.put(key, result);
  /// return result;
  /// ```
  ///
  /// ### Notes
  /// - Unlike `proceed`, this method does **not** invoke the target method.
  /// - Use cautiously—hijacking changes normal control flow and may suppress
  ///   side effects the method would otherwise produce.
  /// - This method completes the invocation context immediately; no further
  ///   processing should occur after calling it.
  /// {@endtemplate}
  Future<void> hijack(T value);
}

/// {@template simple_method_invocation}
/// Represents a reflective invocation of a method on a target object,
/// forming the core join point within JetLeaf’s interception system.
///
/// A [SimpleMethodInvocation] captures all essential contextual information
/// about a method invocation, including:
///
/// - The **target** object instance on which the method is invoked.
/// - The **method metadata** (via [Method]) describing the reflective call.
/// - The **arguments** passed to the method (positional and/or named).
/// - The **invocable request**, a callable function that executes the
///   original method logic when invoked.
///
/// Interceptors and advisors use [SimpleMethodInvocation] instances to:
/// - Inspect and modify invocation arguments.
/// - Decide whether to proceed with the actual method call.
/// - Inject additional behaviors before, after, or around the invocation.
///
/// ## Example
/// ```dart
/// final invocation = SimpleMethodInvocation(
///   target,
///   targetClass,
///   method,
///   arguments,
///   (args) => method.invoke(target, args),
/// );
///
/// // Proceed with the invocation (possibly wrapped by interceptors)
/// final result = invocation.proceed();
/// ```
///
/// ## Lifecycle
/// Each [SimpleMethodInvocation] represents a single logical method call.
/// When combined with [ConditionalMethodInterceptor] chains, it forms
/// the execution backbone for dynamic proxy-based AOP in JetLeaf.
///
/// @typeParam T The return type of the method being invoked.
/// {@endtemplate}
final class SimpleMethodInvocation<T> implements MethodInvocation<T> {
  /// The target object instance on which the method is being invoked.
  /// 
  /// This represents the actual object that contains the method being
  /// intercepted. For instance methods, this is the object instance.
  /// For static methods or constructors, appropriate target representations
  /// are used.
  final Object _target;

  /// The class metadata of the target object.
  /// 
  /// Provides reflective access to the target's class information including
  /// annotations, inheritance hierarchy, and class-level metadata that
  /// might be relevant for interception decisions.
  final Class _targetClass;

  /// The method being invoked, with comprehensive metadata.
  /// 
  /// Contains all relevant information about the method including its name,
  /// parameter types, return type, modifiers, and annotations. This enables
  /// interceptors to make method-specific decisions.
  final Method _method;

  /// The arguments being passed to the method invocation.
  /// 
  /// Contains both positional and named arguments that will be passed to
  /// the target method. Interceptors can inspect and modify these arguments
  /// before the original method is executed.
  final MethodArgument? _arguments;

  /// The original invocable request representing the method call.
  /// 
  /// This function, when called, will execute the original method with
  /// the original arguments. Interceptors can choose to call this directly,
  /// modify it, wrap it, or replace it entirely with custom logic.
  final AsyncMethodInvocator<T> _request;

  /// Tracks whether the target method has been invoked in the current context.
  ///
  /// This internal flag is set to `true` once [proceed()] is called,
  /// preventing multiple invocations of the same method within a single
  /// operation context.
  ///
  /// ### Usage
  /// ```dart
  /// if (!_executed) {
  ///   await proceed();
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Typically private to the context implementation.
  /// - Helps manage caching, rate-limiting, or interception logic.
  bool _executed = false;

  /// Tracks whether this invocation has been **hijacked**.
  ///
  /// Set to `true` when [hijack] is called. A hijacked invocation allows
  /// interceptors or external code to override the normal method execution
  /// and provide a custom result instead of proceeding with the original
  /// target method.
  ///
  /// ### Behavior
  /// - When `_hijacked` is `true`, calling [proceed] may return the hijacked
  ///   result instead of executing the underlying method.
  /// - Ensures that hijacking occurs only once per invocation unless reset
  ///   via [flush].
  /// - Works alongside [_invoked] to manage interception lifecycle and
  ///   prevent multiple conflicting executions.
  bool _hijacked = false;

  /// Caches the result of the target method execution or a hijacked value.
  ///
  /// This internal field stores the return value once it is determined, either
  /// by executing the original method via [proceed] or by short-circuiting
  /// the invocation via [hijack].  
  /// 
  /// ### Behavior
  /// - After [proceed] is called, `_cachedResult` holds the method’s output.
  /// - After [hijack] is called, `_cachedResult` holds the supplied hijacked value.
  /// - Used to prevent multiple executions and to return consistent values.
  /// 
  /// ### Example
  /// ```dart
  /// await invocation.proceed(); // caches the result
  /// print(invocation._cachedResult); // access cached value
  /// ```
  T? _cachedResult;

  /// {@macro simple_method_invocation}
  SimpleMethodInvocation(this._target, this._targetClass, this._method, this._arguments, this._request);

  @override
  MethodArgument? getArgument() => _arguments;

  @override
  Method getMethod() => _method;

  @override
  Object getTarget() => _target;

  @override
  Class getTargetClass() => _targetClass;

  @override
  bool isInvoked() => _executed;

  @override
  Future<void> hijack(T value) async {
    _executed = true;
    _hijacked = true;
    _cachedResult = value;
  }

  @override
  Future<T> proceed([bool retry = false]) async {
    // Already executed or hijacked, no need to re-run
    if (_executed && (!retry || _hijacked)) {
      return _cachedResult as T;
    }

    // Reset state for retry only if not hijacked
    if (retry && !_hijacked) {
      await flush();
    }

    _executed = true;

    // If hijacked during retry, return hijack value
    if (_hijacked) {
      return _cachedResult as T;
    }

    final result = await _request();
    _cachedResult = result;
    return result;
  }

  @override
  Future<void> flush() async {
    _executed = false;
    _hijacked = false;
    _cachedResult = null;
  }
}