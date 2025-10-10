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
import 'package:jetleaf_pod/pod.dart';

import '../annotations/conditional.dart';
import '../annotations/others.dart';
import 'condition.dart';
import 'helpers.dart';

/// {@template jetleaf_on_property_condition}
/// A condition used in **Jetleaf** to evaluate whether a property exists
/// in the application environment and matches expected values.
///
/// This condition works with the [`@ConditionalOnProperty`] annotation
/// to decide if a component should be created or ignored depending on
/// environment configuration.
///
/// ### Behavior
/// - If no [`@ConditionalOnProperty`] is found, the condition **passes**.
/// - If the property is missing but `matchIfMissing` is `true`, the condition **passes**.
/// - If the property is missing and `matchIfMissing` is `false`, the condition **fails**.
/// - If `havingValue` is defined, the property must match it (case-insensitive).
/// - If no `havingValue` is set, the property must not equal `"false"`.
///
/// ### Example
/// ```dart
/// @ConditionalOnProperty(names: ['jetleaf.feature.enabled'], havingValue: 'true')
/// class FeaturePod {
///   // This pod is only active if jetleaf.feature.enabled=true
/// }
/// ```
/// {@endtemplate}
class OnPropertyCondition implements Condition {
  /// {@macro jetleaf_on_property_condition}
  OnPropertyCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (!source.hasDirectAnnotation<ConditionalOnProperty>()) {
      return true;
    }

    final property = source.getDirectAnnotation<ConditionalOnProperty>();
    if(property == null) {
      return true;
    }
    
    final prefix = property.prefix;
    final names = property.names;
    final havingValue = property.havingValue;
    final matchIfMissing = property.matchIfMissing;

    final values = <String>[];
    if(names.isEmpty) {
      values.addAll(names);
    }

    for(final value in values) {
      final val = context.environment.getProperty(prefix != null && prefix.isNotEmpty ? '$prefix.$value' : value);
      if (val == null) {
        if (!matchIfMissing) {
          return false; // missing property and not allowed
        } else {
          continue;
        }
      }

      if (havingValue != null && !havingValue.isEmpty) {
        if (!havingValue.equalsIgnoreCase(val)) {
          return false;
        }
      } else {
        // default semantics: property present and not equal to "false"
        if (val.equalsIgnoreCase("false")) {
          return false;
        }
      }
    }
    
    return true;
  }
}

/// {@template jetleaf_on_class_condition}
/// A condition in **Jetleaf** that checks whether specific classes
/// exist or are missing on the classpath.
///
/// Works with:
/// - [`@ConditionalOnClass`] – requires listed classes to be present.
/// - [`@ConditionalOnMissingClass`] – requires listed classes to be absent.
///
/// ### Behavior
/// - If no annotation is found, the condition **passes**.
/// - For `@ConditionalOnClass`, all specified classes must resolve.
/// - For `@ConditionalOnMissingClass`, all specified classes must **not** resolve.
///
/// ### Example
/// ```dart
/// @ConditionalOnClass(name: ['com.example.SomeDependency'])
/// class FeaturePod {
///   // Only available if com.example.SomeDependency is on the classpath
/// }
/// ```
/// {@endtemplate}
class OnClassCondition implements Condition {
  /// {@macro jetleaf_on_class_condition}
  OnClassCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (source.hasDirectAnnotation<ConditionalOnClass>()) {
      final onClassProperty = source.getDirectAnnotation<ConditionalOnClass>();
      if (onClassProperty != null) {
        for (final requiredType in onClassProperty.value) {
          try {
            requiredType.toClass();
          } catch (e) {
            return false;
          }
        }

        for (final requiredName in onClassProperty.names) {
          try {
            Class.fromQualifiedName(requiredName);
          } catch (e) {
            return false;
          }
        }

        return true;
      }
    }

    if (source.hasDirectAnnotation<ConditionalOnMissingClass>()) {
      final onMissingClassProperty = source.getDirectAnnotation<ConditionalOnMissingClass>();
      if (onMissingClassProperty != null) {
        for (final missingType in onMissingClassProperty.value) {
          try {
            missingType.toClass();
            return false;
          } catch (e) { }
        }

        for (final missingName in onMissingClassProperty.names) {
          try {
            Class.fromQualifiedName(missingName);
            return false;
          } catch (e) { }
        }

        return true;
      }
    }

    return true;
  }
}

/// {@template jetleaf_on_pod_condition}
/// A condition in **Jetleaf** that evaluates the presence or absence of
/// other pods in the dependency injection container.
///
/// Works with:
/// - [`@ConditionalOnPod`] – requires certain pods to exist.
/// - [`@ConditionalOnMissingPod`] – requires certain pods to be absent.
///
/// ### Behavior
/// - Checks for pods by type and name.
/// - Can also register ignored dependencies for missing pods.
///
/// ### Example
/// ```dart
/// @ConditionalOnPod(types: [DatabasePod])
/// class RepositoryPod {
///   // Only created if DatabasePod exists in the pod container
/// }
/// ```
/// {@endtemplate}
class OnPodCondition implements Condition {
  /// {@macro jetleaf_on_pod_condition}
  OnPodCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (source.hasDirectAnnotation<ConditionalOnPod>()) {
      final onPodProperty = source.getDirectAnnotation<ConditionalOnPod>();
      if (onPodProperty != null) {
        for (final requiredType in onPodProperty.types) {
          if ((await context.podFactory.getPodsOf(requiredType.toClass())).isEmpty) {
            return false;
          }
        }

        for (final requiredName in onPodProperty.names) {
          if (!await context.podFactory.containsPod(requiredName)) {
            return false;
          }
        }

        return true;
      }
    }

    if (source.hasDirectAnnotation<ConditionalOnMissingPod>()) {
      final onMissingPodProperty = source.getDirectAnnotation<ConditionalOnMissingPod>();
      if (onMissingPodProperty != null) {
        for (final ignoredType in onMissingPodProperty.ignoredTypes) {
          context.podFactory.registerIgnoredDependency(ignoredType.toClass());
        }

        for (final missingType in onMissingPodProperty.types) {
          if ((await context.podFactory.getPodsOf(missingType.toClass())).isNotEmpty) {
            return false;
          }
        }

        for (final missingName in onMissingPodProperty.names) {
          if (await context.podFactory.containsPod(missingName)) {
            return false;
          }
        }

        return true;
      }
    }

    return true;
  }
}

/// {@template jetleaf_on_profile_condition}
/// A condition in **Jetleaf** that activates pods only if the current
/// environment is running under specific profiles.
///
/// Works with the [`@ConditionalOnProfile`] annotation.
///
/// ### Behavior
/// - If no annotation is found, condition **passes**.
/// - If annotation has profiles, at least one active profile must match.
///
/// ### Example
/// ```dart
/// @ConditionalOnProfile(['dev'])
/// class DevOnlyPod {
///   // Only created when the application is running in the 'dev' profile
/// }
/// ```
/// {@endtemplate}
class OnProfileCondition implements Condition {
  /// {@macro jetleaf_on_profile_condition}
  OnProfileCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    final activeProfiles = context.environment.getActiveProfiles();
    
    // Process @ConditionalOnProfile
    if (source.hasDirectAnnotation<ConditionalOnProfile>()) {
      final onProfileProperty = source.getDirectAnnotation<ConditionalOnProfile>();
      if (onProfileProperty != null) {
        final profiles = onProfileProperty.value;

        if (profiles.isEmpty) {
          return true;
        }

        for (final profile in profiles) {
          if (activeProfiles.contains(profile)) {
            return true;
          }
        }
        return false; // explicit mismatch
      }
    }

    // Process @Profile
    if (source.hasDirectAnnotation<Profile>()) {
      final profileAnnotation = source.getDirectAnnotation<Profile>();
      if (profileAnnotation != null) {
        for (final profile in profileAnnotation.profiles) {
          if (profileAnnotation.negate) {
            if (!activeProfiles.contains(profile)) {
              return true;
            }
          } else {
            if (activeProfiles.contains(profile)) {
              return true;
            }
          }
        }
        return false; // explicit mismatch
      }
    }

    // ✅ No annotations = always include
    return true;
  }
}

/// {@template jetleaf_on_dart_condition}
/// A condition in **Jetleaf** that checks the running Dart SDK version
/// against required constraints.
///
/// Works with the [`@ConditionalOnDart`] annotation.
///
/// ### Behavior
/// - Passes if the running Dart version matches `version`.
/// - Passes if the running Dart version falls within `range`.
/// - Fails otherwise.
///
/// ### Example
/// ```dart
/// @ConditionalOnDart(version: '3.2.0')
/// class Dart32FeaturePod {
///   // Only enabled when running with Dart 3.2.0
/// }
/// ```
/// {@endtemplate}
class OnDartCondition implements Condition {
  /// {@macro jetleaf_on_dart_condition}
  OnDartCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (!source.hasDirectAnnotation<ConditionalOnDart>()) {
      return true;
    }

    final property = source.getDirectAnnotation<ConditionalOnDart>();
    if (property == null) {
      return true;
    }

    final version = property.version;
    final range = property.range;
    final runningVersion = context.runtimeProvider.getAllPackages().find((p) => p.getName() == PackageNames.DART);

    if(runningVersion != null) {
      if(version == runningVersion.getVersion()) {
        return true;
      }

      if(range.contains(Version.parse(runningVersion.getVersion()))) {
        return true;
      }
    }
    
    return false;
  }
}

/// {@template jetleaf_on_asset_condition}
/// A condition in **Jetleaf** that checks whether a given asset exists
/// in the application.
///
/// Works with the [`@ConditionalOnAsset`] annotation.
///
/// ### Behavior
/// - Passes if the asset is resolvable.
/// - Fails if the asset is missing.
///
/// ### Example
/// ```dart
/// @ConditionalOnAsset(asset: 'config/settings.yaml')
/// class SettingsPod {
///   // Only active if the asset config/settings.yaml exists
/// }
/// ```
/// {@endtemplate}
class OnAssetCondition implements Condition {
  /// {@macro jetleaf_on_asset_condition}
  OnAssetCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (!source.hasDirectAnnotation<ConditionalOnAsset>()) {
      return true;
    }
    
    final property = source.getDirectAnnotation<ConditionalOnAsset>();
    if (property == null) {
      return true;
    }

    final asset = property.asset;
    final resource = DefaultAssetPathResource(asset);

    if(resource.tryGet() != null) {
      return true;
    }
    
    return false;
  }
}

/// {@template jetleaf_on_expression_condition}
/// A condition in **Jetleaf** that allows evaluating custom expressions
/// to decide whether a pod should be loaded.
///
/// Works with the [`@ConditionalOnExpression`] annotation.
///
/// > ⚠️ Currently, this always evaluates to `true` but is reserved
///   for future expression-based evaluation.
///
/// ### Example
/// ```dart
/// @ConditionalOnExpression("2 + 2 == 4")
/// class AlwaysLoadedPod {
///   // Will currently always load, but expressions will be evaluated in future versions
/// }
/// ```
/// {@endtemplate}
class OnExpressionCondition implements Condition {
  /// {@macro jetleaf_on_expression_condition}
  OnExpressionCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (!source.hasDirectAnnotation<ConditionalOnExpression>()) {
      return true;
    }
    
    final property = source.getDirectAnnotation<ConditionalOnExpression>();
    Scope? scopeProperty;

    if (source is Class) {
      if (source.hasAnnotation<Scope>()) {
        scopeProperty = source.getAnnotation<Scope>();
      }
    } else {
      if (source.hasDirectAnnotation<Scope>()) {
        scopeProperty = source.getDirectAnnotation<Scope>();
      }
    }

    if (property == null) {
      return true;
    }

    final scopeName = scopeProperty?.value;
    final expression = property.expression;
    final podFactory = context.podFactory;
    final scope = scopeName != null ? podFactory.getRegisteredScope(scopeName) : null;
    final resolver = podFactory.getPodExpressionResolver();

    final result = await resolver?.evaluate(expression, PodExpressionContext(podFactory, scope));
    
    return result?.getValue() != null;
  }
}