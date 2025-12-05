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

/// {@template exception_reporter}
/// Provides an abstraction for **reporting, logging, or forwarding exceptions**
/// that occur within the application.
///
/// An implementation of [ExceptionReporter] may:
/// - Log exceptions to a local or remote logging system  
/// - Forward exceptions to monitoring providers  
/// - Trigger alerting or analytics events  
/// - Filter or process exceptions before reporting  
///
/// This interface offers a simple, unified way for the framework or user code
/// to submit exceptions without needing to know the underlying reporting
/// mechanism.
///
/// ### Example
/// ```dart
/// class ConsoleExceptionReporter implements ExceptionReporter {
///   @override
///   bool reportException(Exception exception) {
///     print("Exception captured: $exception");
///     return true;
///   }
/// }
/// ```
/// 
/// Takes a no-arg constructor or single arg constructor of type [ApplicationContext]
/// {@endtemplate}
abstract interface class ExceptionReporter {
  /// Reports the given [exception] to the underlying exception-handling system.
  ///
  /// Implementations should return:
  /// - `true` if the exception was successfully handled or reported  
  /// - `false` if reporting failed or the exception was ignored  
  ///
  /// ### Parameters
  /// - **exception**: The exception instance that should be reported.
  ///
  /// ### Returns
  /// A boolean indicating whether the exception was successfully reported.
  bool reportException(Exception exception);
}