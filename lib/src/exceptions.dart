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

// ========================================= MESSAGE SOURCE EXCEPTION ========================================

/// {@template message_source_exception}
/// An exception that occurs when resolving messages from a [MessageSource].
///
/// This exception provides additional context beyond a simple error message:
/// - [code]: the message key that failed to resolve.
/// - [locale]: the locale that was requested when the error occurred.
/// - [resource]: the underlying resource (e.g., file, bundle, or database) involved.
/// - [cause]: the original exception that triggered this error, if any.
///
/// This is especially useful in internationalization (i18n) and configuration
/// systems where message lookup may fail due to missing keys, unsupported locales,
/// or inaccessible resources.
///
/// ### Example
/// ```dart
/// void loadMessage(String key, Locale locale) {
///   throw MessageSourceException(
///     "Message key not found",
///     code: key,
///     locale: locale,
///     resource: "messages_en.properties",
///   );
/// }
///
/// try {
///   loadMessage("missing.key", Locale("en"));
/// } catch (e) {
///   print(e);
///   // Output:
///   // MessageSourceException: Message key not found [code=missing.key] [locale=en] [resource=messages_en.properties]
/// }
/// ```
/// {@endtemplate}
class MessageSourceException extends RuntimeException {
  /// The message code (key) that failed to resolve.
  final String? code;

  /// The locale in which the message was being resolved.
  final Locale? locale;

  /// The resource (e.g., properties file, database, etc.)
  /// that was queried during resolution.
  final String? resource;

  /// {@macro message_source_exception}
  MessageSourceException(super.message, {this.code, this.locale, this.resource, super.cause});

  @override
  String toString() {
    final buf = StringBuffer('MessageSourceException: $message');
    if (code != null) buf.write(' [code=$code]');
    if (locale != null) buf.write(' [locale=$locale]');
    if (resource != null) buf.write(' [resource=$resource]');
    if (cause != null) buf.write(' (cause=$cause)');
    return buf.toString();
  }
}

/// {@template circular_dependency_exception}
/// Thrown when a **circular dependency** is detected within the framework's
/// dependency graph, interceptor ordering, or initialization process.
///
/// This exception indicates that two or more components depend on each other
/// in a way that prevents resolution — for example:
///
/// - **Interceptors** that declare conflicting `@RunBefore` / `@RunAfter`
///   relationships forming a cycle.
/// - **Dependency-injected services or pods** that recursively depend on
///   one another through constructors or factory methods.
///
///
/// ### Example
///
/// ```dart
/// // A depends on B, and B depends on A
/// class A {
///   A(B b);
/// }
///
/// class B {
///   B(A a);
/// }
///
/// // During dependency graph resolution:
/// throw CircularDependencyException(
///   'Circular reference detected between A and B',
/// );
/// ```
///
///
/// ### Typical Scenarios
///
/// - Interceptor or handler chains with circular `RunBefore` / `RunAfter` rules.
/// - Object graph creation in IoC containers or module initializers.
/// - Misconfigured plugin registration that references itself indirectly.
///
///
/// ### Debugging Tips
///
/// - Review stack traces for the last successfully resolved dependency.
/// - Check for circular annotation relationships in `@RunBefore` / `@RunAfter`.
/// - Use dependency graph visualizations or logs to identify cycles.
///
///
/// ### Design Notes
///
/// - Extends [RuntimeException], allowing it to represent an unrecoverable
///   framework-level configuration or initialization error.
/// - Should not be caught in user-space unless performing custom dependency
///   graph resolution or interceptor registration logic.
/// - Typically thrown by `InterceptorOrderingEngine` or dependency resolver
///   components during application startup.
///
///
/// ### See Also
/// - [RuntimeException] – Base type for framework runtime errors.
///
///
/// {@endtemplate}
class CircularDependencyException extends RuntimeException {
  /// {@macro circular_dependency_exception}
  CircularDependencyException(super.message, {super.cause, super.stackTrace});
}