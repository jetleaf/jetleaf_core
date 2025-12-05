import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta.dart';

import '../context/base/application_context.dart';
import 'exception_diagnoser.dart';
import 'exception_reporter.dart';

/// {@template application_diagnostics}
/// High-level diagnostics orchestrator combining both:
///
/// **1. Exception diagnoser discovery**  
/// **2. Exception diagnosis reporting**
///
/// This class acts as the *central diagnostics engine* of an application.
/// It automatically:
///
/// - Discovers all available [ExceptionDiagnoser]s  
/// - Discovers all available [ExceptionDiagnosisReporter]s  
/// - Delegates exception analysis to diagnosers  
/// - Forwards the resulting [ExceptionDiagnosis] to all reporters  
///
/// `ApplicationDiagnostics` is therefore the runtime component responsible for
/// transforming raw exceptions into structured diagnostics and ensuring the
/// results are delivered to all registered reporting mechanisms.
///
/// ---
/// ### 🔧 Construction
///
/// On instantiation, the constructor immediately:
///
/// - Calls `super.getDiagnosers()` to load diagnosers discovered via reflection  
/// - Calls `super.getReporters()` to load reporting sinks  
///
/// This makes the diagnostics pipeline fully operational with **zero manual
/// setup**.
///
/// ---
/// ### 🔍 Diagnosis Flow
///
/// The pipeline operates as follows:
///
/// 1. An exception is sent to [reportException]  
/// 2. Internally, [diagnose] iterates through all diagnosers  
/// 3. The *first diagnoser* that returns a non-null [ExceptionDiagnosis] wins  
/// 4. The diagnosis is then forwarded to all reporters via `report()`  
///
/// If:
/// - No diagnoser recognizes the exception, or  
/// - No reporters are available  
///
/// …then the exception is considered *unhandled by the diagnostics system* and
/// `false` is returned.
///
/// All internal errors are safely swallowed so that a faulty diagnoser or
/// reporter cannot break the diagnostics pipeline.
///
/// ---
/// ### Example
/// ```dart
/// final diagnostics = ApplicationDiagnostics(context);
///
/// try {
///   throw InvalidConfigurationException("Missing file");
/// } catch (e) {
///   diagnostics.reportException(e);
/// }
/// ```
///
/// This will automatically:
/// - Find a diagnoser capable of interpreting `InvalidConfigurationException`  
/// - Generate a structured diagnosis  
/// - Forward it to all registered reporters (file logs, telemetry, console, etc.)  
///
/// ---
/// {@endtemplate}
final class ApplicationDiagnostics extends ExceptionDiagnosticsManager implements ExceptionReporter {
  /// Cached list of discovered diagnosers.
  ///
  /// Populated during construction via [ExceptionDiagnosticsManager.getDiagnosers].
  List<ExceptionDiagnoser> _diagnosers = [];

  /// Cached list of discovered reporters.
  ///
  /// Populated during construction via [ExceptionDiagnosticsManager.getReporters].
  List<ExceptionDiagnosisReporter> _reporters = [];

  /// {@macro application_diagnostics}
  ///
  /// Calls the superclass constructor and immediately discovers all diagnosers
  /// and reporters for use throughout the lifetime of this instance.
  ApplicationDiagnostics(super.context) {
    _diagnosers = super.getDiagnosers();
    _reporters = super.getReporters();
  }

  @override
  bool reportException(Exception exception) {
    final diagnosis = diagnose(exception);

    if (diagnosis == null || _reporters.isEmpty) {
      return false;
    }

    for (final reporter in _reporters) {
      reporter.report(diagnosis);
    }

    return true;
  }

  /// Attempts to produce an [ExceptionDiagnosis] for the given [exception].
  ///
  /// Each loaded [ExceptionDiagnoser] is invoked in order. The first diagnoser
  /// returning a non-null diagnosis ends the search and becomes the result.
  ///
  /// ### Behavior
  /// - Diagnosers are invoked inside a `try` block to prevent misbehaving
  ///   diagnosers from disrupting the pipeline.
  /// - If no diagnoser recognizes the exception, `null` is returned.
  ///
  /// This method does *not* dispatch the diagnosis to reporters; it only
  /// performs the analysis.
  ExceptionDiagnosis? diagnose(Exception exception) {
    for (final diagnoser in _diagnosers) {
      try {
        final diagnosis = diagnoser.diagnose(exception);
        if (diagnosis != null) {
          return diagnosis;
        }
      } catch (_) {}
    }

    return null;
  }
}

/// {@template exception_diagnostics_manager}
/// Central orchestrator responsible for **discovering**, **instantiating**, and
/// **managing** all available implementations of:
///
/// - [ExceptionDiagnoser] — components that analyze an exception and produce
///   an [ExceptionDiagnosis]
/// - [ExceptionDiagnosisReporter] — components that consume and publish
///   diagnoses (e.g., to logs, monitoring systems, telemetry sinks)
///
/// This manager uses JetLeaf’s reflection system to automatically scan the
/// runtime classpath, identify all non-abstract subclasses of the relevant
/// interfaces, and construct them using dependency-aware resolution.  
///
/// The manager supports two independent discovery pipelines:
///
/// ---
/// ### 🔍 Diagnoser Discovery
/// Diagnosers may require varying levels of dependency injection.  
/// Construction is attempted using the following priority:
///
/// 1. **No-argument constructor**, if present  
/// 2. Otherwise the *best matching constructor* that accepts *any* of:  
///    - [ApplicationContext]  
///    - [Environment]  
///    - [PodFactory]  
///
/// Constructor arguments are resolved through [ExecutableArgumentResolver],
/// which inspects parameter types and injects compatible instances provided
/// by the application context.
///
/// If instantiation of a diagnoser fails, the error is **silently ignored**
/// so that other diagnosers can still load.
///
/// ---
/// ### 📝 Reporter Discovery
/// Reporters are simpler and must expose a **no-argument constructor**.  
/// If a class does not provide one, it is skipped and a warning is logged.
///
/// Instantiation errors are again ignored to ensure system stability.
///
/// ---
/// ### Logging Behavior
/// - **INFO** logs announce each instantiation attempt  
/// - **WARN** logs announce missing constructors  
/// - Errors are deliberately suppressed to avoid cascading failures  
///
/// ---
/// ### Example Usage
/// ```dart
/// final diagnosticsManager = ExceptionDiagnosticsManager(context);
///
/// final diagnosers = diagnosticsManager.getDiagnosers();
/// final reporters = diagnosticsManager.getReporters();
///
/// for (final diagnoser in diagnosers) {
///   final diagnosis = diagnoser.diagnose(Exception("Issue"));
///   for (final reporter in reporters) {
///     reporter.report(diagnosis);
///   }
/// }
/// ```
///
/// This enables automated multi-stage exception handling pipelines with zero
/// manual wiring.
/// {@endtemplate}
@internal
base class ExceptionDiagnosticsManager {
  /// Optional application context used for constructor injection when creating
  /// [ExceptionDiagnoser] instances.
  ///
  /// May be `null` when no dependency injection is desired. In that case,
  /// only diagnosers with a no-argument constructor will be instantiated.
  final ConfigurableApplicationContext? _context;

  /// Logger used to record information, warnings, and diagnostics during
  /// diagnoser and reporter discovery.
  final Log _logger = LogFactory.getLog(ExceptionDiagnosticsManager);

  /// {@macro exception_diagnostics_manager}
  ExceptionDiagnosticsManager(this._context);

  /// Discovers and instantiates all available non-abstract subclasses of
  /// [ExceptionDiagnoser].
  ///
  /// ### Constructor Resolution
  /// Instantiation is attempted in this order:
  /// 1. A no-argument constructor  
  /// 2. Otherwise, the “best” constructor matching any of:
  ///    - [ApplicationContext]
  ///    - [Environment]
  ///    - [PodFactory]
  ///
  /// These dependencies are injected via [ExecutableArgumentResolver].
  ///
  /// ### Error Handling
  /// - All instantiation errors are silently ignored.
  /// - Missing constructors result in a warning when logging is enabled.
  ///
  /// Returns a list of all successfully constructed diagnosers.
  List<ExceptionDiagnoser> getDiagnosers() {
    final cac = Class<ExceptionDiagnoser>(null, PackageNames.CORE);
    final sources = <ExceptionDiagnoser>[];
    final classes = cac.getSubClasses().where((cl) => !cl.isAbstract());

    for(final cls in classes) {
      if(_logger.getIsDebugEnabled()) {
        _logger.debug("Attempting to instantiate the exception diagnoser ${cls.getName()}");
      }

      final defc = cls.getNoArgConstructor() ?? cls.getBestConstructor([Class<ApplicationContext>(), Class<Environment>(), Class<PodFactory>()]);
  
      try {
        if(defc != null) {
          final args = ExecutableArgumentResolver()
            .and(Class<ApplicationContext>(), _context)
            .and(Class<Environment>(), _context?.getEnvironment())
            .and(Class<PodFactory>(), _context?.getPodFactory())
            .resolve(defc);
            
          final source = defc.newInstance(args.getNamedArguments(), args.getPositionalArguments());
          sources.add(source);
        } else {
          if(_logger.getIsWarnEnabled()) {
            _logger.warn("${cls.getName()} does not have a no-arg constructor");
          }
        }
      } catch (_) {
        // No-op
      }
    }

    return sources;
  }

  /// Discovers and instantiates all non-abstract subclasses of
  /// [ExceptionDiagnosisReporter].
  ///
  /// Only classes that define a **no-argument constructor** are eligible for
  /// loading. If a reporter lacks such a constructor, it is skipped and a
  /// warning is emitted when logging is enabled.
  ///
  /// Like diagnosers, instantiation errors are always ignored to ensure
  /// continued discovery of remaining reporters.
  ///
  /// Returns a list of successfully constructed reporter instances.
  List<ExceptionDiagnosisReporter> getReporters() {
    final cac = Class<ExceptionDiagnosisReporter>(null, PackageNames.CORE);
    final sources = <ExceptionDiagnosisReporter>[];
    final classes = cac.getSubClasses().where((cl) => !cl.isAbstract());

    for(final cls in classes) {
      if(_logger.getIsDebugEnabled()) {
        _logger.debug("Attempting to instantiate the exception diagnosis reporter ${cls.getName()}");
      }

      final defc = cls.getNoArgConstructor();
  
      try {
        if(defc != null) {
          final source = defc.newInstance();
          sources.add(source);
        } else {
          if(_logger.getIsWarnEnabled()) {
            _logger.warn("${cls.getName()} does not have a no-arg constructor");
          }
        }
      } catch (_) {
        // No-op
      }
    }

    return sources;
  }
}