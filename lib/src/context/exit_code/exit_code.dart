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

import '../../annotation_aware_order_comparator.dart';
import '../event/application_event.dart';
import 'exit_code_generator.dart';

/// {@template exit_code_event}
/// An [ApplicationEvent] that signals the application should exit
/// with a specific exit code.
///
/// This event can be published at any point in the application lifecycle
/// to trigger a graceful shutdown with the given code. It's commonly used
/// in CLI tools or frameworks where exit codes carry semantic meaning,
/// such as success, configuration error, missing file, or runtime failure.
///
/// ### Example:
/// ```dart
/// context.publishEvent(ExitCodeEvent(this, 1));
/// ```
///
/// {@endtemplate}
class ExitCodeEvent extends ApplicationEvent {
  final int _exitCode;

  /// Creates a new [ExitCodeEvent] with the given [source] and [_exitCode].
  ExitCodeEvent(super.source, this._exitCode);

  /// Returns the exit code associated with this event.
  int getExitCode() => _exitCode;

  @override
  List<Object?> equalizedProperties() => [...super.equalizedProperties(), _exitCode];

  @override
  ToStringOptions toStringOptions() => ToStringOptions()
    ..customParameterNames = [...super.toStringOptions().customParameterNames ?? [], "exitCode"]
    ..includeClassName = true;

  @override
  String getPackageName() => PackageNames.CORE;
}

// ===================================== EXIT CODE GENERATORS =========================================

/// {@template exit_code_generators}
/// A container and manager for multiple [ExitCodeGenerator] instances.
///
/// This class allows you to dynamically register and prioritize exit code generators.
/// These generators are responsible for computing application exit codes based on
/// exceptions thrown during execution.
///
/// It supports:
/// - Adding generators directly
/// - Mapping exceptions to exit codes using [ExitCodeExceptionHandler]
/// - Aggregating generators from multiple sources
/// - Resolving a final exit code from all registered generators
///
/// Example:
/// ```dart
/// final generators = ExitCodeGenerators();
///
/// generators.add(Exception("App crashed"), MyExitCodeMapper());
/// int code = generators.getExitCode();
/// exit(code);
/// ```
/// {@endtemplate}
class ExitCodeGenerators extends Iterable<ExitCodeGenerator> {
  final List<ExitCodeGenerator> _generators = ArrayList();

  /// {@macro exit_code_generators}
  ExitCodeGenerators();

  /// {@template add_all_exception_mappers}
  /// Adds a list of [ExitCodeExceptionHandler]s for a given [exception],
  /// mapping each one to an internal [_MappedExitCodeGenerator].
  ///
  /// Example:
  /// ```dart
  /// generators.addAll(
  ///   SomeException(),
  ///   [MyMapper1(), MyMapper2()],
  /// );
  /// ```
  /// {@endtemplate}
  void addAll(Throwable exception, List<ExitCodeExceptionHandler> mappers) {
    addAllMappers(exception, mappers);
  }

  /// {@template add_all_mappers}
  /// Adds a collection of [ExitCodeExceptionHandler]s for a given [exception].
  ///
  /// Each mapper is wrapped in a [_MappedExitCodeGenerator] internally.
  ///
  /// Example:
  /// ```dart
  /// generators.addAllMappers(
  ///   AppException(),
  ///   [MyMapper()],
  /// );
  /// ```
  /// {@endtemplate}
  void addAllMappers<T extends ExitCodeExceptionHandler>(Throwable exception, Iterable<T> mappers) {
    for (T mapper in mappers) {
      add(exception, mapper);
    }
  }

  /// {@template add_single_mapper}
  /// Adds a single [ExitCodeExceptionHandler] for a given [exception].
  ///
  /// Example:
  /// ```dart
  /// generators.add(MyException(), MyMapper());
  /// ```
  /// {@endtemplate}
  void add(Throwable exception, ExitCodeExceptionHandler mapper) {
    addGenerator(_MappedExitCodeGenerator(exception, mapper));
  }

  /// {@template add_all_generators}
  /// Adds a list of [ExitCodeGenerator] instances directly.
  ///
  /// Example:
  /// ```dart
  /// generators.addAllGenerators([CustomExitCodeGen()]);
  /// ```
  /// {@endtemplate}
  void addAllGenerators(List<ExitCodeGenerator> generators) {
    addAllMultiGenerators(generators);
  }

  /// {@template add_all_multi_generators}
  /// Adds multiple [ExitCodeGenerator]s to this manager.
  ///
  /// Example:
  /// ```dart
  /// generators.addAllMultiGenerators([
  ///   Generator1(),
  ///   Generator2(),
  /// ]);
  /// ```
  /// {@endtemplate}
  void addAllMultiGenerators<T extends ExitCodeGenerator>(Iterable<T> generators) {
    for (T generator in generators) {
      addGenerator(generator);
    }
  }

  /// {@template add_generator}
  /// Adds a single [ExitCodeGenerator] and ensures all generators
  /// are ordered using [AnnotationAwareOrderComparator].
  ///
  /// Example:
  /// ```dart
  /// generators.addGenerator(MyExitCodeGenerator());
  /// ```
  /// {@endtemplate}
  void addGenerator(ExitCodeGenerator generator) {
    _generators.add(generator);
    AnnotationAwareOrderComparator.sort(_generators);
  }

  @override
  Iterator<ExitCodeGenerator> get iterator => _generators.iterator;

  /// {@template get_exit_code}
  /// Resolves the final exit code by iterating over all registered
  /// [ExitCodeGenerator]s and returning the first non-zero code.
  ///
  /// If none returns a non-zero value, defaults to `0`.
  /// If a [Throwable] or [Exception] is thrown while calling `getExitCode`,
  /// it logs the stack trace and sets exit code to `1`.
  ///
  /// Example:
  /// ```dart
  /// int exitCode = generators.getExitCode();
  /// exit(exitCode);
  /// ```
  /// {@endtemplate}
  int getExitCode() {
    int exitCode = 0;
    for (ExitCodeGenerator generator in _generators) {
      try {
        int value = generator.getExitCode();
        if (value != 0) {
          exitCode = value;
          break;
        }
      } on Throwable catch (th) {
        exitCode = 1;
        th.printStackTrace();
      } on Exception catch (ex) {
        exitCode = 1;
        ex.printStackTrace();
      }
    }
    return exitCode;
  }
}

/// {@template mapped_exit_code_generator}
/// A concrete implementation of [ExitCodeGenerator] that delegates the
/// exit code computation to a provided [ExitCodeExceptionHandler] based on
/// a specific [Throwable] instance.
///
/// This class is used internally by [ExitCodeGenerators] to wrap an exception
/// and its associated mapper into an executable generator.
///
/// Example usage (internal):
/// ```dart
/// final generator = _MappedExitCodeGenerator(exception, mapper);
/// final exitCode = generator.getExitCode();
/// ```
/// {@endtemplate}
class _MappedExitCodeGenerator implements ExitCodeGenerator {
  /// The exception that will be passed to the mapper.
  final Throwable exception;

  /// The mapper responsible for converting the [exception] into an exit code.
  final ExitCodeExceptionHandler mapper;

  /// Creates a new mapped exit code generator using the given [exception]
  /// and [mapper].
  /// 
  /// {@macro mapped_exit_code_generator}
  _MappedExitCodeGenerator(this.exception, this.mapper);

  @override
  int getExitCode() => mapper.getExitCode(exception);

  @override
  String getPackageName() => PackageNames.CORE;
}