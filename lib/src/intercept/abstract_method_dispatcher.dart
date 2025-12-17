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

import '../annotation_aware_order_comparator.dart';
import 'interceptable.dart';
import 'method_interceptor.dart';
import 'method_invocation.dart';

/// {@template abstract_method_dispatcher}
/// A foundational implementation of [MethodInterceptorDispatcher] and [MethodInterceptor]
/// providing a unified interception pipeline for JetLeaf's runtime and AOP subsystems.
///
/// The [AbstractMethodDispatcher] acts as the **core interception orchestrator**
/// that coordinates method invocations, dynamic dispatching, and chained interceptor
/// execution for runtime-managed objects. It defines the general interception workflow
/// but delegates the actual interceptor configuration to concrete subclasses.
///
/// ### Responsibilities
/// 1. **Delegation:** If a custom dispatcher is configured (via
///    [getMethodInterceptorDispatcher]), it delegates all interception logic to it.
/// 2. **Resolution:** If no custom dispatcher exists, it locates the target
///    [Method] metadata from the reflected [target] type.
/// 3. **Invocation Management:** Wraps the call in a [SimpleMethodInvocation]
///    and triggers the interceptor chain created by [_ChainedMethodInterceptor].
/// 4. **Error Diagnostics:** Produces rich diagnostic feedback when the
///    requested method cannot be found, aiding in debugging reflection
///    and metadata issues.
///
/// ### Framework Context
/// This abstract class is part of JetLeaf’s **Aspect-Oriented Programming (AOP)**
/// engine. It provides the essential interception entry point for features like:
/// - Logging and tracing decorators
/// - Security or authorization guards
/// - Caching and transactional operations
/// - Cross-cutting concerns resolved via proxy mechanisms
///
/// ### Custom Implementation Example
/// ```dart
/// class MyServiceDispatcher extends AbstractMethodDispatcher {
///   final List<MethodInterceptor> _interceptors;
///
///   MyServiceDispatcher(this._interceptors);
///
///   @override
///   List<MethodInterceptor> getMethodInterceptors() => _interceptors;
///
///   @override
///   MethodInterceptorDispatcher? getMethodInterceptorDispatcher() => null;
/// }
/// ```
///
/// ### Invocation Flow
/// ```mermaid
/// sequenceDiagram
///   participant Client
///   participant Dispatcher as AbstractMethodDispatcher
///   participant Interceptor as _ChainedMethodInterceptor
///   participant Target as ServiceClass
///
///   Client->>Dispatcher: when(fn, target, methodName)
///   Dispatcher->>Interceptor: intercept(invocation)
///   Interceptor->>Target: invoke method or chain next interceptor
///   Target-->>Dispatcher: result or null
///   Dispatcher-->>Client: final result
/// ```
///
/// ### References
/// - [_ChainedMethodInterceptor] – For chained conditional interception handling.
/// - [MethodInterceptor] – Defines interceptor applicability.
/// - [SimpleMethodInvocation] – Wraps target method invocation metadata.
/// - [MethodInterceptorDispatcher] – Contract for dispatching and orchestrating method-level interceptors.
/// - [MethodInterceptor] – Base interface for any interceptor within the JetLeaf ecosystem.
/// {@endtemplate}
abstract class AbstractMethodDispatcher implements MethodInterceptorDispatcher {
  @override
  Future<T> when<T>(AsyncMethodInvocator<T> function, Object target, String methodName, [ExecutableArgument? arguments, Class? targetClass]) async {
    final customDispatcher = getMethodInterceptorDispatcher();

    if (customDispatcher != null) {
      return customDispatcher.when(function, target, methodName, arguments);
    }
    
    targetClass ??= target.getClass();

    if (ClassUtils.isProxyClass(targetClass)) {
      targetClass = ClassUtils.getProxiedClass(target.getClass(), target);
    }

    final method = targetClass.getMethod(methodName);

    // Before proceeding, we need to make sure that the method name actually lives in the target class.
    if (method != null) {
      MethodInvocation<T> invocation = SimpleMethodInvocation(target, targetClass, method, arguments, function);
      final result = await intercept<T>(invocation);

      if (result != null) {
        return result;
      }

      return invocation.proceed();
    } else if (method == null) {
      throw IllegalArgumentException('''
JetLeaf could not locate the method `$methodName` in class `${targetClass.getQualifiedName()}`.

Possible causes:
  • The method `$methodName` is not declared in `${targetClass.getName()}` or its superclasses.
  • The method belongs to a mixin or interface and is not directly implemented in the target class.

🔍 Diagnostic details:
  - Target class: ${targetClass.getQualifiedName()}
  - Requested method: $methodName
  - Available methods: ${targetClass.getMethods().map((m) => m.getName()).join(', ')}

💡 Recommended fixes:
  → Verify that `$methodName` exists and is declared in `${targetClass.getName()}`.
  → If using mixins or abstract classes, ensure the concrete implementation defines `$methodName`.
  → If reflection metadata is out of date, rebuild your project or regenerate proxy files.

Example:
```dart
final result = await when(
  () => createUser(user),
  service,
  'createUser',
  ExecutableArgument(positionalArgs: [user])
);
```
''');
    }

    return function();
  }

  /// Executes a method invocation through the configured interceptor chain.
  ///
  /// This serves as the primary entry point for applying cross-cutting behaviors
  /// such as logging, transaction management, validation, or authorization.
  ///
  /// Each registered [MethodInterceptor] can inspect, modify, or short-circuit
  /// the invocation before or after it reaches the actual method implementation.
  ///
  /// Example:
  /// ```dart
  /// final result = await intercept(MethodInvocation(() => service.save(entity)));
  /// ```
  ///
  /// Returns:
  /// - The final result of the method call after all interceptors have been applied.
  Future<T> intercept<T>(MethodInvocation<T> invocation) async {
    return _ChainedMethodInterceptor(getMethodInterceptors()).intercept(invocation);
  }

  /// Retrieves the list of method interceptors to be applied by this dispatcher.
  ///
  /// Concrete implementations must provide the list of interceptors that
  /// should be considered for method interception. The interceptors are
  /// evaluated in the order they are returned, and each interceptor's
  /// `canIntercept` method is called to determine if it should apply
  /// to the current method invocation.
  ///
  /// ## Example Implementation
  /// ```dart
  /// class MyDispatcher extends AbstractMethodDispatcher {
  ///   final List<MethodInterceptor> _interceptors;
  ///
  ///   MyDispatcher(this._interceptors);
  ///
  ///   @override
  ///   List<MethodInterceptor> getMethodInterceptors() {
  ///     return _interceptors;
  ///   }
  /// }
  /// ```
  ///
  /// @return The list of [MethodInterceptor] instances to apply.
  List<MethodInterceptor> getMethodInterceptors();

  /// {@template MethodInterceptorDispatcher_getMethodInterceptorDispatcher}
  /// Retrieves the active [MethodInterceptorDispatcher] responsible for
  /// managing method-level interception logic.
  ///
  /// The returned dispatcher orchestrates interceptor resolution, stack trace
  /// parsing, and invocation flow control for all method calls intercepted
  /// within the current context. Implementations may return `null` if
  /// interception is not enabled or no dispatcher has been configured.
  ///
  /// This method is typically used by framework internals to obtain the
  /// dispatcher that delegates to [MethodInterceptor] instances
  /// through an [_ChainedMethodInterceptor].
  ///
  /// @return The current [MethodInterceptorDispatcher], or `null` if unavailable.
  /// {@endtemplate}
  MethodInterceptorDispatcher? getMethodInterceptorDispatcher();
}

/// {@template chained_method_interceptor}
/// A composite [MethodInterceptor] that executes multiple
/// interceptors in a defined, deterministic order.
///
/// The [_ChainedMethodInterceptor] acts as a **delegating interceptor chain**
/// within the JetLeaf AOP (Aspect-Oriented Programming) subsystem. It allows
/// multiple [MethodInterceptor]s to be combined into a single
/// logical unit, while preserving the intended priority and ordering of
/// each contained interceptor.
///
/// ### Overview
/// When a method invocation occurs, this chain:
/// 1. Iterates through each registered interceptor in priority order.
/// 2. Delegates the interception to each interceptor that declares
///    itself applicable via [canIntercept].
/// 3. Stops and returns the first non-`null` result produced by an interceptor.
/// 4. If no interceptor handles the invocation, returns `null`.
///
/// This mechanism allows complex interception scenarios to be composed
/// — for example, combining security checks, caching, logging, and metrics
/// interceptors in a single invocation pipeline.
///
/// ### Ordering Strategy
/// Interceptors are sorted using [AnnotationAwareOrderComparator] according to
/// the following hierarchy:
///
/// | Priority Type | Interface | Description |
/// |---------------|------------|--------------|
/// | 1️⃣ Highest | [PriorityOrdered] | Always executed first, typically framework-level interceptors. |
/// | 2️⃣ Medium | [Ordered] | Executed after high-priority ones, often user-defined components. |
/// | 3️⃣ Lowest | *Default* | Interceptors with no ordering annotation. |
///
/// Within each group, annotation-based order metadata (e.g., `@Order`) is
/// respected to ensure deterministic sequencing.
///
/// ### Example
/// ```dart
/// final chain = _ChainedMethodInterceptor([
///   LoggingInterceptor(),
///   TransactionInterceptor(),
///   CachingInterceptor(),
/// ]);
///
/// final result = await chain.intercept(MyMethodInvocation());
/// ```
///
/// ### References
/// - [MethodInterceptor] — The contract for conditional interception.
/// - [AnnotationAwareOrderComparator] — Comparator responsible for ordering logic.
/// - [PriorityOrdered] and [Ordered] — Interfaces defining interceptor precedence.
/// - [MethodInterceptorDispatcher] — Typical consumer of chained interceptors.
/// {@endtemplate}
final class _ChainedMethodInterceptor implements MethodInterceptor {
  /// The ordered set of interceptors that will be executed in sequence.
  ///
  /// Maintains the interceptors in deterministic execution order, ensuring
  /// that high-priority interceptors execute before lower-priority ones, and
  /// that those within the same category are properly sorted using
  /// [AnnotationAwareOrderComparator].
  final Set<MethodInterceptor> _interceptors = {};

  /// {@macro chained_method_interceptor}
  ///
  /// Creates a new [_ChainedMethodInterceptor] with interceptors arranged in
  /// their computed priority order.
  ///
  /// The constructor performs a **three-stage sorting process**:
  /// 1. Categorizes interceptors into [PriorityOrdered], [Ordered], or default.
  /// 2. Sorts each category using [AnnotationAwareOrderComparator].
  /// 3. Merges the categories sequentially into the final execution set.
  ///
  /// This ensures a consistent and predictable execution sequence regardless
  /// of how the original interceptors were declared or discovered.
  ///
  /// ### Parameters
  /// - `interceptors`: The raw collection of interceptors to include in the chain.
  ///
  /// ### Example
  /// ```dart
  /// final chain = _ChainedMethodInterceptor([
  ///   SecurityInterceptor(),
  ///   MetricsInterceptor(),
  ///   LoggingInterceptor(),
  /// ]);
  /// ```
  _ChainedMethodInterceptor(Iterable<MethodInterceptor> interceptors) {
    _interceptors.addAll(AnnotationAwareOrderComparator.getOrderedItems(interceptors));
  }

  /// Determines whether any interceptor in this chain can handle
  /// the specified [method].
  ///
  /// Returns `true` if **at least one** interceptor in the chain reports
  /// that it can intercept the given method via [MethodInterceptor.canIntercept].
  ///
  /// ### Parameters
  /// - `method`: The [Method] metadata object representing the target invocation.
  ///
  /// ### Returns
  /// - `true` if interception is supported by at least one delegate.
  /// - `false` otherwise.
  @override
  bool canIntercept(Method method) => _interceptors.any((i) => i.canIntercept(method));

  @override
  List<Object?> equalizedProperties() => [_ChainedMethodInterceptor];

  /// Executes the interceptor chain for the provided [MethodInvocation].
  ///
  /// Each interceptor is given a chance to process the invocation in turn.
  /// The first interceptor that:
  /// - declares itself applicable (via [canIntercept]),
  /// - and returns a non-`null` result,
  /// will short-circuit the chain and produce the final outcome.
  ///
  /// For void methods, the chain continues execution even if an interceptor
  /// produces a value, ensuring that all applicable interceptors have a chance
  /// to execute.
  ///
  /// ### Parameters
  /// - `invocation`: The encapsulated invocation context containing the target
  ///   method and arguments.
  ///
  /// ### Returns
  /// A [Future] that completes with the first non-`null` result returned by
  /// an interceptor, or `null` if none apply.
  ///
  /// ### Example
  /// ```dart
  /// final result = await chain.intercept(MyInvocation());
  /// if (result == null) {
  ///   // proceed with default method execution
  /// }
  /// ```
  Future<T> intercept<T>(MethodInvocation<T> invocation) async {
    final method = invocation.getMethod();
    T result;

    try {
      // 1️⃣ Before advices
      for (final i in _interceptors.whereType<MethodBeforeInterceptor>()) {
        if (i.canIntercept(method)) {
          await i.beforeInvocation(invocation);
        }
      }

      // 2️⃣ Around advices (wrap proceed)
      final around = _interceptors.whereType<AroundMethodInterceptor>().where((i) => i.canIntercept(method));
      if (around.isNotEmpty) {
        // Nested around logic if multiple — can be recursive or pipeline-based
        result = await _invokeAroundChain(around.toList(), invocation);
      } else {
        result = await invocation.proceed();
      }

      // 3️⃣ AfterReturning advices
      for (final i in _interceptors.whereType<AfterReturningInterceptor>()) {
        if (i.canIntercept(method)) {
          await i.afterReturning(invocation, result, result?.getClass());
        }
      }
    } catch (e, st) {
      // 4️⃣ AfterThrowing advices
      for (final i in _interceptors.whereType<AfterThrowingInterceptor>()) {
        if (i.canIntercept(method)) {
          await i.afterThrowing(invocation, e, e.getClass(), st);
        }
      }

      rethrow;
    } finally {
      // 5️⃣ After (finally) advices
      for (final i in _interceptors.whereType<AfterInvocationInterceptor>()) {
        if (i.canIntercept(method)) {
          await i.afterInvocation(invocation);
        }
      }
    }

    return result;
  }

  /// Recursively invokes each [AroundMethodInterceptor] in the chain, preserving order.
  ///
  /// This function forms the core of JetLeaf’s *around-invocation* mechanism.
  /// Each interceptor wraps the next one in the chain, allowing before/after logic
  /// to be applied around the actual method execution.
  ///
  /// If the end of the chain is reached, [MethodInvocation.proceed] is called to
  /// execute the underlying target method.
  ///
  /// Example:
  /// ```dart
  /// final result = await _invokeAroundChain(interceptors, invocation);
  /// ```
  ///
  /// Parameters:
  /// - [chain]: The ordered list of [AroundMethodInterceptor]s to apply.
  /// - [invocation]: The [MethodInvocation] being executed.
  /// - [index]: The current interceptor index (used internally for recursion).
  ///
  /// Returns:
  /// - A [Future] containing the result of the invocation after all interceptors have run.
  Future<T> _invokeAroundChain<T>(List<AroundMethodInterceptor> chain, MethodInvocation<T> invocation, [int index = 0]) async {
    if (index >= chain.length) {
      // No interceptors left → call actual method
      return invocation.proceed();
    }

    // Define the next function for the next interceptor
    Future<T> next() async => await _invokeAroundChain(chain, invocation, index + 1);

    // Wrap the invocation
    final wrapper = _DelegatingInvocation(invocation, next);

    // Call the current interceptor
    final T? result = await chain[index].aroundInvocation(wrapper);

    // If this interceptor returned a non-null T, return it
    if (result != null) {
      return result;
    }

    // Otherwise, continue down the chain
    return next();
  }
}

/// {@template _delegating}
/// A delegating wrapper around another [MethodInvocation] used
/// internally by the interception engine to support nested
/// `AroundMethodInterceptor` chains.
///
/// Each `_DelegatingInvocation` wraps a downstream invocation
/// and a "next" continuation function, which may represent either:
/// - Another `AroundMethodInterceptor` in the chain, or
/// - The terminal call to the target method (`proceed()`).
///
/// This allows each `aroundInvoke()` call to execute custom logic
/// *before or after* calling the next layer in the chain.
///
/// ## Example
/// ```dart
/// Future<T?> aroundInvoke<T>(MethodInvocation<T> invocation) async {
///   print("Before: ${invocation.getMethod().getName()}");
///   final result = await invocation.proceed();
///   print("After: ${invocation.getMethod().getName()}");
///   return result;
/// }
/// ```
///
/// The engine constructs `_DelegatingInvocation` instances dynamically
/// for each interceptor in the chain.
/// 
/// {@endtemplate}
@Generic(_DelegatingInvocation)
final class _DelegatingInvocation<T> implements MethodInvocation<T> {
  /// The underlying method invocation that this class delegates to.
  ///
  /// All core metadata (target object, target class, method, arguments)
  /// are accessed through this delegate. Interceptors typically wrap
  /// or modify the behavior of this base invocation.
  final MethodInvocation<T> _delegate;

  /// The next function in the interception chain.
  ///
  /// Calling this executes the next interceptor or, if at the end
  /// of the chain, the original target method. This allows chaining
  /// multiple interceptors in a predictable sequence.
  final Future<T> Function() _next;

  /// Tracks whether this delegating invocation has been invoked.
  ///
  /// Set to `true` when either [proceed] or [hijack] is called. Used
  /// to prevent multiple executions in the same interception context
  /// unless explicitly retried.
  bool _invoked = false;

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

  /// Caches the result of the invocation or hijacked value.
  ///
  /// Stores the return value of either [_next] (via [proceed]) or
  /// a manually supplied value via [hijack]. Prevents re-execution
  /// and ensures consistent results across repeated calls.
  T? _result;

  /// {@macro _delegating}
  _DelegatingInvocation(this._delegate, this._next);

  @override
  Object getTarget() => _delegate.getTarget();

  @override
  Class getTargetClass() => _delegate.getTargetClass();

  @override
  Method getMethod() => _delegate.getMethod();

  @override
  ExecutableArgument? getArgument() => _delegate.getArgument();

  @override
  bool isInvoked() => _invoked;

  @override
  Future<void> hijack(T value) async {
    _invoked = true;
    _hijacked = true;
    _result = value;
  }

  @override
  Future<T> proceed([bool retry = false]) async {
    // If already executed or hijacked, return cached result
    if (_invoked && (!retry || _hijacked)) {
      return _result as T;
    }

    // On retry, flush only if not hijacked
    if (retry && !_hijacked) {
      await flush();
      await _delegate.flush();
    }

    _invoked = true;

    // If hijacked during retry, respect hijack value
    if (_hijacked) {
      return _result as T;
    }

    final res = await _next();
    _result = res;
    return res;
  }

  @override
  Future<void> flush() async {
    _invoked = false;
    _hijacked = false;
    _result = null;
  }
}