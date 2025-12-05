/// {@template exception_diagnosis}
/// Represents a **structured diagnostic report** for an exception, providing
/// human-readable context, optional recommended actions, and the originating
/// exception itself.
///
/// `ExceptionDiagnosis` is typically produced by diagnostic or error-handling
/// components to enrich exceptions with:
///
/// - A descriptive explanation of what went wrong  
/// - A suggested action or remediation step  
/// - The underlying cause (the original [Exception])  
///
/// This class is immutable and safe to share across threads or async flows.
///
/// ### Example
/// ```dart
/// try {
///   throw FormatException("Invalid configuration file");
/// } catch (e) {
///   final diagnosis = ExceptionDiagnosis(
///     cause: e,
///     description: "The provided configuration file could not be parsed.",
///     action: "Verify the file format or restore a valid configuration.",
///   );
///
///   print(diagnosis.getDescription());
/// }
/// ```
/// {@endtemplate}
final class ExceptionDiagnosis {
  /// A human-readable description explaining the nature of the problem.
  ///
  /// This field is stored privately and exposed through [getDescription] to
  /// preserve immutability semantics and prevent accidental mutations.
  final String _description;

  /// An optional recommended action or remediation guidance for resolving the
  /// diagnosed issue.
  ///
  /// This may be shown to operators, logged, or used by automated tooling.
  final String? action;

  /// The underlying exception that triggered this diagnosis.
  ///
  /// This is always present and represents the original cause.
  final Exception cause;

  /// {@macro exception_diagnosis}
  ///
  /// Creates a new [ExceptionDiagnosis] instance.
  ///
  /// ### Parameters
  /// - **cause**: The original exception that is being diagnosed. *(required)*
  /// - **action**: Optional guidance or recommended corrective steps.
  /// - **description**: Optional textual explanation of the problem.
  ///   - Defaults to an empty string if omitted.
  ExceptionDiagnosis({required this.cause, this.action, String? description}) : _description = description ?? "";

  /// Returns the human-readable diagnostic description.
  ///
  /// This is equivalent to the `description` parameter passed to the
  /// constructor, or an empty string if none was provided.
  String getDescription() => _description;
}

/// {@template exception_diagnoser}
/// Defines the contract for components capable of **analyzing exceptions** and
/// producing structured diagnostic information.
///
/// Implementations of `ExceptionDiagnoser` inspect an [Exception] and return an
/// [ExceptionDiagnosis] that may include:
///
/// - A human-readable explanation of the failure  
/// - A recommended action or remediation step  
/// - The original exception as the underlying cause  
///
/// This interface enables pluggable, extensible, and testable diagnostic
/// mechanisms. It is commonly used in systems where exceptions must be
/// enriched with contextual metadata before being logged, displayed, or
/// forwarded.
///
/// ### Example
/// ```dart
/// class SimpleDiagnoser implements ExceptionDiagnoser {
///   @override
///   ExceptionDiagnosis diagnose(Exception exception) {
///     return ExceptionDiagnosis(
///       cause: exception,
///       description: "An unexpected error occurred.",
///       action: "Check logs for more details.",
///     );
///   }
/// }
/// ```
/// 
/// Accepts no-arg constructor or a constructor with any of these parameter types:
/// - [ApplicationContext]
/// - [PodFactory]
/// - [Environment]
/// 
/// {@endtemplate}
abstract interface class ExceptionDiagnoser {
  /// Produces an [ExceptionDiagnosis] describing the given exception.
  ///
  /// Implementations may perform:
  /// - Pattern matching on exception types  
  /// - Inspection of message content  
  /// - Contextual enrichment (e.g., environment, state snapshots)  
  ///
  /// Always returns a non-null [ExceptionDiagnosis] instance.
  ///
  /// ### Parameters
  /// - **exception**: The original exception needing diagnosis.
  ///
  /// ### Returns
  /// A structured [ExceptionDiagnosis] containing explanation, optional
  /// remediation steps, and the original exception as the cause.
  ExceptionDiagnosis? diagnose(Exception exception);
}

/// {@template exception_diagnosis_reporter}
/// Defines the contract for components responsible for **handling and reporting**
/// structured exception diagnoses.
///
/// An `ExceptionDiagnosisReporter` receives an [ExceptionDiagnosis] produced by an
/// [`ExceptionDiagnoser`](../exception_diagnoser.dart) and performs some form of
/// reporting, such as:
///
/// - Logging the diagnosis to a console or file  
/// - Sending the diagnosis to an external monitoring or alerting service  
/// - Persisting it for later analysis  
/// - Triggering automated remediation workflows  
///
/// This interface separates *diagnosis* from *reporting*, allowing the reporting
/// mechanism to be swapped or extended without altering the diagnostic logic.
///
/// ### Example
/// ```dart
/// class ConsoleReporter implements ExceptionDiagnosisReporter {
///   @override
///   void report(ExceptionDiagnosis diagnosis) {
///     print("Exception: ${diagnosis.cause}");
///     print("Description: ${diagnosis.getDescription()}");
///     if (diagnosis.action != null) {
///       print("Recommended Action: ${diagnosis.action}");
///     }
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class ExceptionDiagnosisReporter {
  /// Reports the given [ExceptionDiagnosis] using the reporter’s output mechanism.
  ///
  /// Implementations should ensure the diagnosis is properly recorded, transmitted,
  /// or displayed depending on system requirements. This method should never throw;
  /// reporters are expected to fail gracefully.
  ///
  /// ### Parameters
  /// - **diagnosis**: The structured diagnostic information to be reported.
  void report(ExceptionDiagnosis diagnosis);
}