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

/// {@template exit_code_generator}
/// Strategy interface for determining the exit code returned from a JetLeaf
/// application or a process.
///
/// This is typically used when the application is shutting down due to an error,
/// and a custom exit code should be returned to the operating system.
///
/// Classes implementing this interface can be plugged into the JetLeaf runtime,
/// allowing them to determine a meaningful exit code based on the state of the
/// application or the error encountered.
///
/// ### Example:
/// ```dart
/// class MyExitCodeGenerator implements ExitCodeGenerator {
///   @override
///   int getExitCode() {
///     // Return 1 to indicate error
///     return 1;
///   }
/// 
///   @override
///   String getPackageName() => "test";
/// }
/// ```
///
/// You can register this generator during the application context setup or
/// inside an error-handling pipeline.
///
/// See also: `ApplicationExitHandler`, `SystemExit`
/// {@endtemplate}
abstract interface class ExitCodeGenerator implements PackageIdentifier {
  /// Returns the exit code that should be used to terminate the application.
  ///
  /// This will typically be returned from the main process when calling
  /// `exit(code)`.
  int getExitCode();
}

// ========================================= EXIT CODE EXCEPTION HANDLER ======================================

/// {@template exit_code_exception_handler}
/// A strategy interface for mapping a specific [Exception] to a process
/// exit code.
///
/// This interface allows you to define custom logic to translate different
/// types of exceptions into meaningful exit codes for your application.
/// It's especially useful for CLI tools, server applications, or embedded
/// systems where specific exit codes are used to signal different kinds
/// of failure conditions.
///
/// ### Example:
/// ```dart
/// class CustomExitCodeMapper implements ExitCodeExceptionMapper {
///   @override
///   int getExitCode(Exception exception) {
///     if (exception is FormatException) return 2;
///     if (exception is FileSystemException) return 3;
///     return 1; // generic failure
///   }
/// }
/// ```
///
/// You can combine multiple mappers or use this in a centralized shutdown
/// strategy to ensure all errors are properly classified with standardized
/// codes.
///
/// {@endtemplate}
abstract interface class ExitCodeExceptionHandler {
  /// Returns an integer exit code based on the given [exception].
  ///
  /// This method should implement logic to inspect the exception type,
  /// message, or other properties to determine which code to return.
  int getExitCode(Exception exception);
}