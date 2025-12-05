import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import 'exception_diagnoser.dart';

/// {@template abstract_exception_diagnoser}
/// Base class for creating typed exception diagnosers that target a
/// specific exception type [E].
///
/// This abstract diagnoser:
/// - Filters the exception chain to find a cause of type [E]  
/// - Delegates actual diagnosis to the subclass via [doDiagnose]  
/// - Implements [ExceptionDiagnoser] and [ClassGettable] for type reflection
///
/// Subclasses must implement [doDiagnose] to provide meaningful
/// [`ExceptionDiagnosis`] for the matched exception type.
///
/// ### Example
/// ```dart
/// class FormatExceptionDiagnoser extends AbstractExceptionDiagnoser<FormatException> {
///   @override
///   ExceptionDiagnosis? doDiagnose(Exception exception, FormatException cause) {
///     return ExceptionDiagnosis(
///       cause: cause,
///       description: "Invalid format encountered",
///       action: "Check input data or configuration",
///     );
///   }
/// }
/// ```
/// {@endtemplate}
abstract class AbstractExceptionDiagnoser<E extends Exception> implements ExceptionDiagnoser, ClassGettable {
  @override
  ExceptionDiagnosis? diagnose(Exception exception) {
    final cause = getCause(exception, toClass());
    return cause != null ? doDiagnose(exception, cause) : null;
  }

  /// Searches the exception chain for a cause of type `Cause`.
  ///
  /// This method works in two steps:
  ///
  /// 1. **If the exception is a `Throwable`**  
  ///    - Walk its cause chain using `getCause()`  
  ///    - Return the first cause where `type.isInstance()` is true
  ///
  /// 2. **If not a Throwable**  
  ///    - Check if the exception itself is of type `Cause`
  ///
  /// If no matching cause is found, returns `null`.
  ///
  /// This allows diagnosers to match not only the thrown exception but
  /// also nested/underlying exceptions.
  @protected
  Cause? getCause<Cause extends Exception>(Exception exception, Class<Cause> type) {
    if (exception is Throwable) {
      Object? cause = exception;
      while (cause != null) {
        if (type.isInstance(cause)) {
          return cause as Cause;
        }

        cause = exception.getCause();
      }
    }

    if (exception is Cause) {
      return exception;
    }

    return null;
  }

  /// Performs the actual diagnosis for the matched cause.
  ///
  /// [exception] is the *original* thrown exception.
  /// [cause] is the matched underlying exception of type `E`.
  ///
  /// Subclasses implement this method to return a useful
  /// [`ExceptionDiagnosis`] describing:
  ///   - What happened (description)
  ///   - Why it happened (optional cause analysis)
  ///   - What the user can do (action steps)
  ///
  /// Return `null` only if the diagnoser decides it cannot provide
  /// a meaningful diagnosis.
  @protected
  ExceptionDiagnosis? doDiagnose(Exception exception, E cause);

  @override
  Class<E> toClass() => Class<E>();
}