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
  List<Class> types = [];
  List<String> names = [];

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

    // Process @Profile
    if (source.hasDirectAnnotation<Profile>()) {
      final activeProfiles = environment.getActiveProfiles();
      final annotation = source.getDirectAnnotation<Profile>();

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Found @Profile annotation on ${source.getName()} with profiles: ${annotation?.profiles}');
      }

      if (annotation != null) {
        for (final profile in annotation.profiles) {
          if (annotation.negate) {
            if (!activeProfiles.contains(profile)) {
              if (_logger.getIsTraceEnabled()) {
                _logger.trace('Profile condition matched (negated): $profile');
              }

              return true;
            }
          } else {
            if (activeProfiles.contains(profile)) {
              if (_logger.getIsTraceEnabled()) {
                _logger.trace('Profile condition matched: $profile');
              }

              return true;
            }
          }
        }

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Profile condition failed for ${source.getName()}');
        }

        return false; // explicit mismatch
      }
    }

    final conditional = source.getDirectAnnotation<Conditional>();
    if (conditional == null) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @Conditional annotation found on ${source.getName()}, defaulting to include.');
      }

      return true;
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Found @Conditional annotation with conditions: ${conditional.conditions.map((c) => c.getType()).toList()}');
    }

    List<Condition> conditions = [];
    for (final condition in conditional.conditions) {
      final conditionClass = condition.toClass();
      final conditionName = conditionClass.getQualifiedName();

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Instantiating condition: $conditionName');
      }

      if (conditionName.equals(Class<OnPropertyCondition>(null, PackageNames.CORE).getQualifiedName())) {
        conditions.add(OnPropertyCondition());
      } else if (conditionName.equals(Class<OnClassCondition>(null, PackageNames.CORE).getQualifiedName())) {
        conditions.add(OnClassCondition());
      } else if (conditionName.equals(Class<OnPodCondition>(null, PackageNames.CORE).getQualifiedName())) {
        conditions.add(OnPodCondition(types: types, names: names));
      } else if (conditionName.equals(Class<OnProfileCondition>(null, PackageNames.CORE).getQualifiedName())) {
        conditions.add(OnProfileCondition());
      } else if (conditionName.equals(Class<OnDartCondition>(null, PackageNames.CORE).getQualifiedName())) {
        conditions.add(OnDartCondition());
      } else if (conditionName.equals(Class<OnAssetCondition>(null, PackageNames.CORE).getQualifiedName())) {
        conditions.add(OnAssetCondition());
      } else if (conditionName.equals(Class<OnExpressionCondition>(null, PackageNames.CORE).getQualifiedName())) {
        conditions.add(OnExpressionCondition());
      } else {
        try {
          conditions.add(conditionClass.newInstance());
        } catch (e) {
          _logger.trace('❌ Failed to instantiate condition: $conditionName — $e');
          throw IllegalArgumentException("Failed to instantiate condition $conditionName. Make sure it has a no-arg constructor.");
        }
      }
    }

    for (final condition in conditions) {
      final conditionName = condition.runtimeType.toString();
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Evaluating condition: $conditionName for source: ${source.getName()}');
      }

      final result = await condition.matches(this, source);
      if (!result) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Condition failed: $conditionName — Source ${source.getName()} will be excluded.');
        }
        return false;
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Condition passed: $conditionName');
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('✅ All conditions passed for ${source.getName()}. Including in context.');
    }

    return true;
  }
}