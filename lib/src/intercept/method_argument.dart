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

/// {@template method_argument}
/// Represents the arguments passed to a method invocation within JetLeaf’s interception system.
///
/// A [MethodArgument] encapsulates both **positional** and **named**
/// arguments for reflective method calls, enabling interceptors and advisors
/// to inspect, modify, or forward arguments dynamically.
///
/// This abstraction provides a unified interface for accessing and
/// manipulating arguments in a type-safe, reflection-friendly manner,
/// regardless of the original invocation context.
///
/// ## Example
/// ```dart
/// void logInvocation(MethodArgument args) {
///   print('Positional: ${args.getPositionalArguments()}');
///   print('Named: ${args.getNamedArguments()}');
/// }
/// ```
///
/// ## Responsibilities
/// - Provides ordered access to **positional arguments**.
/// - Provides key-based access to **named arguments**.
/// - Enables intercept interceptors to modify or forward method inputs.
///
/// Used primarily by:
/// - [MethodInvocation]
/// - [SimpleMethodInvocation]
/// - [ConditionalMethodInterceptor]
///
/// {@endtemplate}
abstract interface class MethodArgument with EqualsAndHashCode {
  /// {@template MethodArgument_getPositionalArguments}
  /// Retrieves the positional arguments for the method invocation.
  ///
  /// Returns an ordered list of positional arguments that will be passed
  /// to the target method. The order matches the parameter declaration
  /// order in the method signature.
  ///
  /// This enables reflective inspection or modification of argument values
  /// prior to invocation, often used in advice logic.
  ///
  /// @return List of positional arguments in declaration order
  /// {@endtemplate}
  List<Object?> getPositionalArguments();

  /// {@template MethodArgument_getNamedArguments}
  /// Retrieves the named arguments for the method invocation.
  ///
  /// Returns a map of named arguments where keys are parameter names
  /// and values are the argument values. This enables access to
  /// optional named parameters in Dart method invocations.
  ///
  /// Useful for interceptors that need to log or adjust named parameters
  /// before the target method executes.
  ///
  /// @return Map of named arguments keyed by parameter name
  /// {@endtemplate}
  Map<String, Object?> getNamedArguments();
}

/// {@template method_arguments}
/// Immutable container for method invocation arguments.
///
/// The [MethodArguments] class provides a structured representation of both
/// positional and named arguments passed to a method during an invocation.
/// It serves as the concrete implementation of [MethodArgument] used within
/// JetLeaf's intercept and reflection subsystems.
///
/// This abstraction allows interceptors, advices, and reflection utilities
/// to inspect or modify method arguments in a uniform way, regardless of
/// whether they are positional or named.
///
/// ## Example
/// ```dart
/// final args = MethodArguments(
///   positionalArgs: [1, 'data'],
///   namedArgs: {'flag': true},
/// );
///
/// print(args.getPositionalArguments()); // [1, 'data']
/// print(args.getNamedArguments()); // {flag: true}
/// ```
///
/// ## Usage in intercept
/// When a [MethodInvocation] occurs, the framework wraps the original
/// call’s arguments inside a [MethodArguments] instance, making them
/// available to interceptors and advices for inspection or modification.
///
/// @see [MethodArgument] for the base interface.
/// {@endtemplate}
final class MethodArguments implements MethodArgument {
  /// The positional arguments for the method invocation.
  ///
  /// Represents arguments that are passed in order according to the
  /// method's parameter declaration sequence.
  final List<Object?> positionalArgs;

  /// The named arguments for the method invocation.
  ///
  /// Represents arguments passed by name. Keys correspond to parameter names,
  /// and values represent the actual argument values.
  final Map<String, Object?> namedArgs;

  /// {@macro method_arguments}
  ///
  /// Creates a new immutable [MethodArguments] instance with the given
  /// [positionalArgs] and [namedArgs].
  ///
  /// Both arguments default to empty collections when not provided.
  const MethodArguments({this.positionalArgs = const [], this.namedArgs = const {}});

  @override
  Map<String, Object?> getNamedArguments() => namedArgs;

  @override
  List<Object?> getPositionalArguments() => positionalArgs;

  @override
  List<Object?> equalizedProperties() => [namedArgs, positionalArgs];
}