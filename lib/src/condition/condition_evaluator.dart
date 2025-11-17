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
import 'package:jetleaf_logging/logging.dart';

import '../annotations/conditional.dart';
import '../annotations/others.dart';
import 'condition.dart';
import 'conditions.dart';

/// {@template conditionEvaluator}
/// The `ConditionEvaluator` in **Jetleaf** is responsible for evaluating
/// conditional annotations (e.g., [Conditional], [ConditionalOnClass],
/// [ConditionalOnPod]) and determining whether a given source (class, method,
/// or configuration) should be included in the Jetleaf application context.
///
/// It checks all conditions attached to a [Source] via annotations and ensures
/// they are satisfied before including the source in the runtime.
///
/// ### Key Features:
/// - Inspects annotations of a given [Source].
/// - Instantiates condition classes declared in the annotation.
/// - Evaluates each condition against the current [ConditionalContext].
/// - Excludes sources if any condition does not match.
///
/// ### Usage Example:
/// ```dart
/// final evaluator = ConditionEvaluator(
///   registry,
///   environment,
///   podFactory,
///   classLoader,
///   runtimeProvider,
/// );
///
/// final shouldLoad = await evaluator.shouldInclude(mySource);
///
/// if (shouldLoad) {
///   print('Source included!');
/// } else {
///   print('Source excluded by conditions.');
/// }
/// ```
/// {@endtemplate}
final class ConditionEvaluator extends ConditionalContext {
  final Log _logger = LogFactory.getLog(ConditionEvaluator);

  /// {@macro conditionEvaluator}
  ConditionEvaluator(super.environment, super.podFactory, super.runtimeProvider);

  /// Evaluates whether the given [source] should be included in the Jetleaf context.
  ///
  /// - Retrieves the [Conditional] annotation from the source (if any).
  /// - Instantiates and executes all declared [Condition] classes.
  /// - Returns `true` if all conditions match, otherwise `false`.
  ///
  /// ### Example:
  /// ```dart
  /// final result = await evaluator.shouldInclude(mySource);
  /// if (result) {
  ///   // proceed with registering pods
  /// }
  /// ```
  Future<bool> shouldInclude(Source source) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Evaluating conditional inclusion for source: ${source.getName()}');
    }

    final conditions = <_AnnotatedCondition>[];

    if (source.hasDirectAnnotation<Profile>()) {
      final annotation = source.getAllDirectAnnotations().find((ann) => ann.matches<Profile>());
      
      if (annotation != null) {
        conditions.add(MapEntry(annotation, OnProfileCondition()));
      }
    }

    final matches = findAllConditionals(source);
    if (matches.isNotEmpty) {
      for (final match in matches) {
        final annotation = match.key;
        final value = match.value;

        if (value is List) {
          for (final item in value) {
            if (item is Condition) {
              conditions.add(MapEntry(annotation, item));
            }
          }
        }
      }
    }

    if (conditions.isNotEmpty) {
      return await allConditionsMatch(conditions, source);
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('No @Conditional or @Profile annotation found on ${source.getName()}, defaulting to include.');
    }

    return true;
  }

  /// Recursively finds all @Conditional annotations associated with a source.
  ///
  /// - [source] can be a Class or Method (anything that implements getAllDirectAnnotations()).
  /// - Walks through annotations that extend [WhenConditional] and finds
  ///   any @Conditional annotations on them, recursively.
  ///
  /// Returns a list of [_ConditionalMatch] entries.
  List<_ConditionalMatch> findAllConditionals(Source source) {
    final matches = <_ConditionalMatch>[];
    final conditional = Class<Conditional>(null, PackageNames.CORE);
    final whenConditional = Class<WhenConditional>(null, PackageNames.CORE);

    /// Recursively process a single annotation
    void processAnnotation(Annotation annotation) {
      final annotationClass = annotation.getClass();

      // Check all annotations on this annotation class
      for (final inner in annotationClass.getAllAnnotations()) {
        try {
          // If the inner annotation is assignable to Conditional, record it
          if (conditional.isAssignableFrom(inner.getClass())) {
            matches.add(MapEntry(annotation, inner.getFieldValue(Conditional.FIELD_KEY)));
          }

          // If the inner annotation itself extends WhenConditional, recurse
          if (whenConditional.isAssignableFrom(inner.getClass())) {
            processAnnotation(inner);
          }
        } catch (_) {
          // Ignore errors from reflection issues
        }
      }
    }

    // Start with all direct annotations on the source
    for (final ann in source.getAllDirectAnnotations()) {
      try {
        if (whenConditional.isAssignableFrom(ann.getClass())) {
          processAnnotation(ann);
        }

        // Also check if the annotation itself is a Conditional
        if (conditional.isAssignableFrom(ann.getClass())) {
          matches.add(MapEntry(ann, ann.getFieldValue(Conditional.FIELD_KEY)));
        }
      } catch (_) {}
    }

    return matches;
  }

  /// Checks whether **all given conditions** match the specified [source] asynchronously.
  ///
  /// Each [_AnnotatedCondition] contains an annotation and its associated [Condition].
  /// This method evaluates all conditions in parallel and returns `true` only if
  /// every condition’s `matches` method returns `true`.
  ///
  /// Example:
  /// ```dart
  /// final allMatch = await allConditionsMatch(conditions, source);
  /// if (allMatch) {
  ///   // All conditions passed
  /// }
  /// ```
  Future<bool> allConditionsMatch(Iterable<_AnnotatedCondition> conditions, Source source) async {
    final results = await Future.wait(conditions.map((condition) => condition.value.matches(this, condition.key, source)));

    // Check if all results are true
    return results.all((match) => match);
  }
}

/// Represents a pair of an annotation and its corresponding resolved
/// `@Conditional` annotation (or related metadata).
///
/// The key is the **main annotation** being processed, and the value is
/// the associated conditional metadata or resolved annotation.
typedef _ConditionalMatch = MapEntry<Annotation, dynamic>;

/// Represents a pair of an annotation and its associated `Condition`.
///
/// The key is the **annotation** being evaluated, and the value is the
/// `Condition` that determines whether the annotation is active or applicable.
typedef _AnnotatedCondition = MapEntry<Annotation, Condition>;