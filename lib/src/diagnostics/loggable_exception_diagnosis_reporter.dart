import 'package:jetleaf_logging/logging.dart';

import 'exception_diagnoser.dart';

/// {@template loggable_exception_diagnosis_reporter}
/// An implementation of [ExceptionDiagnosisReporter] that outputs
/// structured exception diagnosis information using the JetLeaf logging system.
///
/// This reporter is designed to be used during application startup and other
/// critical phases where exceptions must be clearly visible and actionable.
/// It automatically logs diagnostic output at:
///
/// - **DEBUG** level — includes the raw exception (`diagnosis.cause`)
/// - **ERROR** level — includes a formatted diagnostic report with description
///   and optional recommended action
///
/// The output is intentionally verbose and uses clear formatting blocks to
/// improve readability within console logs, log files, or remote aggregators.
///
/// ### Example
/// ```dart
/// final reporter = LoggableExceptionDiagnosisReporter();
/// final diagnosis = ExceptionDiagnosis(
///   cause: Exception("Database connection failed"),
///   description: "The application could not connect to the database.",
///   action: "Check connection settings and ensure the database is running."
/// );
///
/// reporter.report(diagnosis);
/// ```
///
/// This will emit a diagnostic block similar to:
///
/// ```text
/// *********************************************************************************
/// APPLICATION ERROR DIAGNOSED
/// *********************************************************************************
///
/// Description:
///
/// The application could not connect to the database.
///
/// Action:
///
/// Check connection settings and ensure the database is running.
/// ```
/// {@endtemplate}
final class LoggableExceptionDiagnosisReporter implements ExceptionDiagnosisReporter {
  /// Logger instance specific to this reporter.
  final Log _logger = LogFactory.getLog(LoggableExceptionDiagnosisReporter);

  /// {@macro loggable_exception_diagnosis_reporter}
  LoggableExceptionDiagnosisReporter();

  @override
  void report(ExceptionDiagnosis diagnosis) {
    if (_logger.getIsDebugEnabled()) {
      _logger.debug("Failed to start application due to an exception", error: diagnosis.cause);
    }

    if (_logger.getIsErrorEnabled()) {
      _logger.error(_buildMessage(diagnosis));
    }
  }

  /// Builds a formatted multi-line diagnostic message for error-level output.
  ///
  /// The message includes:
  /// - A banner block  
  /// - The diagnosis description  
  /// - An optional *Action* block when provided  
  ///
  /// This output is intended for human readability and may be captured
  /// by log aggregators or monitoring dashboards.
  String _buildMessage(ExceptionDiagnosis diagnosis) {
    final buffer = StringBuffer();

    buffer.writeln();
    buffer.writeln("*********************************************************************************");
    buffer.writeln("APPLICATION ERROR DIAGNOSED");
    buffer.writeln("*********************************************************************************");
    buffer.writeln();

    // Description
    buffer.writeln("Description:");
    buffer.writeln();
    buffer.writeln(diagnosis.getDescription());

    // Action (if present)
    if (diagnosis.action != null && diagnosis.action!.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln("Action:");
      buffer.writeln();
      buffer.writeln(diagnosis.action);
    }

    return buffer.toString();
  }
}