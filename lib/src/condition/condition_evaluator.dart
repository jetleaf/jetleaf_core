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

import '../annotations/conditional.dart';
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
  /// {@macro conditionEvaluator}
  ConditionEvaluator(super.environment, super.podFactory, super.runtimeProvider);

  /// Default conditions used by the evaluator.
  List<Condition> _defaultConditions = [
    OnPropertyCondition(),
    OnClassCondition(),
    OnPodCondition(),
    OnProfileCondition(),
    OnDartCondition(),
    OnAssetCondition(),
    OnExpressionCondition()
  ];

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
    if (!source.hasDirectAnnotation<Conditional>()) {
      // Jetleaf's default conditions
      for (final condition in _defaultConditions) {
        if (!await condition.matches(this, source)) {
          return false;
        }
      }

      return true;
    }
    
    final conditional = source.getDirectAnnotation<Conditional>();
    if (conditional == null) {
      // Jetleaf's default conditions
      for (final condition in _defaultConditions) {
        if (!await condition.matches(this, source)) {
          return false;
        }
      }

      return true;
    }

    for (final condition in conditional.conditions) {
      try {
        final instance = condition.toClass().newInstance();
        final context = ConditionalContext(environment, podFactory, runtimeProvider);
        if (!await instance.matches(context, source)) {
          return false;
        }
      } catch (_) {}
    }

    // Jetleaf's default conditions
    for (final condition in _defaultConditions) {
      if (!await condition.matches(this, source)) {
        return false;
      }
    }

    return true;
  }
}