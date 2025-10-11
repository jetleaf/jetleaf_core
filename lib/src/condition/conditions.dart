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
  final Log _logger = LogFactory.getLog(OnPropertyCondition);

  /// {@macro jetleaf_on_property_condition}
  OnPropertyCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnPropertyCondition for ${source.getName()}');
    }

    if (!source.hasDirectAnnotation<ConditionalOnProperty>()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @ConditionalOnProperty found → passing.');
      }

      return true;
    }

    final property = source.getDirectAnnotation<ConditionalOnProperty>();
    if (property == null) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Annotation retrieval failed → passing.');
      }

      return true;
    }

    final prefix = property.prefix;
    final names = property.names;
    final havingValue = property.havingValue;
    final matchIfMissing = property.matchIfMissing;

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('prefix=$prefix, names=$names, havingValue=$havingValue, matchIfMissing=$matchIfMissing');
    }

    final values = <String>[];
    if (names.isNotEmpty) {
      values.addAll(names);
    }

    for (final value in values) {
      final key = prefix != null && prefix.isNotEmpty ? '$prefix.$value' : value;
      final val = context.environment.getProperty(key);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Checking property: $key = $val');
      }

      if (val == null) {
        if (!matchIfMissing) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('❌ Missing property $key and matchIfMissing=false → failing.');
          }

          return false;
        } else {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('⚠️ Missing property $key but matchIfMissing=true → continuing.');
          }

          continue;
        }
      }

      if (havingValue != null && havingValue.isNotEmpty) {
        if (!havingValue.equalsIgnoreCase(val)) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('❌ Value mismatch for $key (expected $havingValue, got $val) → failing.');
          }

          return false;
        }
      } else if (val.equalsIgnoreCase("false")) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('❌ Value for $key is "false" → failing.');
        }

        return false;
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('✅ OnPropertyCondition passed for ${source.getName()}');
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
  final Log _logger = LogFactory.getLog(OnClassCondition);

  /// {@macro jetleaf_on_class_condition}
  OnClassCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnClassCondition for ${source.getName()}');
    }

    if (source.hasDirectAnnotation<ConditionalOnClass>()) {
      final onClassProperty = source.getDirectAnnotation<ConditionalOnClass>();
      if (onClassProperty != null) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Found @ConditionalOnClass with values: ${onClassProperty.value}, names: ${onClassProperty.names}');
        }

        for (final requiredType in onClassProperty.value) {
          try {
            requiredType.toClass();
            
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('✅ Class ${requiredType.toClass().getQualifiedName()} found.');
            }
          } catch (_) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('❌ Required class ${requiredType.getType()} missing → failing.');
            }

            return false;
          }
        }

        for (final requiredName in onClassProperty.names) {
          try {
            Class.fromQualifiedName(requiredName);
            
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('✅ Class $requiredName found.');
            }
          } catch (_) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('❌ Required class $requiredName missing → failing.');
            }

            return false;
          }
        }

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ OnClassCondition passed.');
        }

        return true;
      }
    }

    if (source.hasDirectAnnotation<ConditionalOnMissingClass>()) {
      final onMissingClassProperty = source.getDirectAnnotation<ConditionalOnMissingClass>();
      if (onMissingClassProperty != null) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Found @ConditionalOnMissingClass with values: ${onMissingClassProperty.value}, names: ${onMissingClassProperty.names}');
        }

        for (final missingType in onMissingClassProperty.value) {
          try {
            missingType.toClass();
            
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('❌ Found missingType ${missingType.getType()} → failing.');
            }

            return false;
          } catch (_) {}
        }

        for (final missingName in onMissingClassProperty.names) {
          try {
            Class.fromQualifiedName(missingName);
            
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('❌ Found missingName $missingName → failing.');
            }

            return false;
          } catch (_) {}
        }

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ OnMissingClassCondition passed.');
        }

        return true;
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('No relevant annotation found → passing.');
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
  final List<Class> _types;
  final List<String> _names;

  final Log _logger = LogFactory.getLog(OnPodCondition);

  /// {@macro jetleaf_on_pod_condition}
  OnPodCondition({List<Class<dynamic>> types = const [], List<String> names = const []}) : _names = names, _types = types;

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnPodCondition for ${source.getName()}');
    }

    if (source.hasDirectAnnotation<ConditionalOnPod>()) {
      final onPodProperty = source.getDirectAnnotation<ConditionalOnPod>();
      if (onPodProperty != null) {
        for (final requiredType in onPodProperty.types) {
          final podType = requiredType.toClass();
          final pods = <String, Object>{};

          try {
            pods.addAll(await context.podFactory.getPodsOf(podType));
          } catch (_) {}

          if (_logger.getIsTraceEnabled()) {
            _logger.trace('Checking pod type ${podType.getQualifiedName()} → found ${pods.length} pods.');
          }

          if (pods.isEmpty || !_types.contains(podType) || _types.noneMatch((type) => type.getQualifiedName() == podType.getQualifiedName())) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('❌ Required pod type missing → failing.');
            }

            return false;
          }
        }

        for (final requiredName in onPodProperty.names) {
          final exists = await context.podFactory.containsPod(requiredName);

          if (_logger.getIsTraceEnabled()) {
            _logger.trace('Checking pod name $requiredName → exists=$exists');
          }

          if (!exists || !_names.contains(requiredName) || _names.noneMatch((name) => name.equals(requiredName))) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('❌ Required pod name missing → failing.');
            }

            return false;
          }
        }

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ OnPodCondition passed.');
        }

        return true;
      }
    }

    if (source.hasDirectAnnotation<ConditionalOnMissingPod>()) {
      final onMissingPodProperty = source.getDirectAnnotation<ConditionalOnMissingPod>();
      if (onMissingPodProperty != null) {
        for (final ignoredType in onMissingPodProperty.ignoredTypes) {
          context.podFactory.registerIgnoredDependency(ignoredType.toClass());
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('Registered ignored dependency: ${ignoredType.getType()}');
          }
        }

        for (final missingType in onMissingPodProperty.types) {
          final podType = missingType.toClass();
          final pods = <String, Object>{};

          try {
            pods.addAll(await context.podFactory.getPodsOf(podType));
          } catch (_) {}

          if (_logger.getIsTraceEnabled()) {
            _logger.trace('Checking missing pod type ${podType.getQualifiedName()} → found ${pods.length} pods.');
          }

          if (pods.isNotEmpty || _types.contains(podType) || _types.noneMatch((type) => type.getQualifiedName() == podType.getQualifiedName())) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('❌ Pod type ${podType.getQualifiedName()} exists → failing.');
            }

            return false;
          }
        }

        for (final missingName in onMissingPodProperty.names) {
          final exists = await context.podFactory.containsPod(missingName);

          if (_logger.getIsTraceEnabled()) {
            _logger.trace('Checking missing pod name $missingName → exists=$exists');
          }

          if (exists || _names.contains(missingName) || _names.noneMatch((name) => name.equals(missingName))) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('❌ Pod name $missingName exists → failing.');
            }

            return false;
          }
        }

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ OnMissingPodCondition passed.');
        }

        return true;
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('No relevant annotation found → passing.');
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
  final Log _logger = LogFactory.getLog(OnProfileCondition);

  /// {@macro jetleaf_on_profile_condition}
  OnProfileCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnProfileCondition for ${source.getName()}');
    }

    final activeProfiles = context.environment.getActiveProfiles();
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Active profiles: $activeProfiles');
    }

    if (source.hasDirectAnnotation<ConditionalOnProfile>()) {
      final onProfileProperty = source.getDirectAnnotation<ConditionalOnProfile>();
      if (onProfileProperty != null) {
        final profiles = onProfileProperty.value;
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Required profiles: $profiles');
        }

        if (profiles.isEmpty) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('No profiles specified → passing.');
          }

          return true;
        }

        for (final profile in profiles) {
          if (activeProfiles.contains(profile)) {
            if (_logger.getIsTraceEnabled()) {
              _logger.trace('✅ Matching profile found: $profile');
            }

            return true;
          }
        }

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('❌ No matching profile found → failing.');
        }

        return false;
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('No @ConditionalOnProfile found → passing.');
    }

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
  final Log _logger = LogFactory.getLog(OnDartCondition);

  /// {@macro jetleaf_on_dart_condition}
  OnDartCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnDartCondition for ${source.getName()}');
    }

    if (!source.hasDirectAnnotation<ConditionalOnDart>()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @ConditionalOnDart found → passing.');
      }

      return true;
    }

    final property = source.getDirectAnnotation<ConditionalOnDart>();
    if (property == null) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Annotation retrieval failed → passing.');
      }

      return true;
    }

    final version = property.version;
    final range = property.range;
    final runningVersion = context.runtimeProvider
        .getAllPackages()
        .find((p) => p.getName() == PackageNames.DART);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Required version=$version, range=$range, runningVersion=${runningVersion?.getVersion()}');
    }

    if (runningVersion != null) {
      if (version == runningVersion.getVersion()) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ Exact version match.');
        }

        return true;
      }

      if (range.contains(Version.parse(runningVersion.getVersion()))) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ Version within allowed range.');
        }

        return true;
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('❌ OnDartCondition failed.');
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
  final Log _logger = LogFactory.getLog(OnAssetCondition);

  /// {@macro jetleaf_on_asset_condition}
  OnAssetCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnAssetCondition for ${source.getName()}');
    }

    if (!source.hasDirectAnnotation<ConditionalOnAsset>()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @ConditionalOnAsset found → passing.');
      }

      return true;
    }
    
    final property = source.getDirectAnnotation<ConditionalOnAsset>();
    if (property == null) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Annotation retrieval failed → passing.');
      }

      return true;
    }

    final asset = property.asset;
    final resource = DefaultAssetPathResource(asset);

    if(resource.tryGet() != null) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ Asset found → passing.');
      }

      return true;
    }
    
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('❌ Asset not found → failing.');
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
  final Log _logger = LogFactory.getLog(OnExpressionCondition);

  /// {@macro jetleaf_on_expression_condition}
  OnExpressionCondition();

  @override
  Future<bool> matches(ConditionalContext context, Source source) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnExpressionCondition for ${source.getName()}');
    }

    if (!source.hasDirectAnnotation<ConditionalOnExpression>()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @ConditionalOnExpression found → passing.');
      }

      return true;
    }
    
    final property = source.getDirectAnnotation<ConditionalOnExpression>();
    Scope? scopeProperty;

    if (source is Class && source.hasAnnotation<Scope>()) {
      scopeProperty = source.getAnnotation<Scope>();
    } else if (source.hasDirectAnnotation<Scope>()) {
      scopeProperty = source.getDirectAnnotation<Scope>();
    }

    if (property == null) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Annotation retrieval failed → passing.');
      }

      return true;
    }

    final scopeName = scopeProperty?.value;
    final expression = property.expression;
    final podFactory = context.podFactory;
    final scope = scopeName != null ? podFactory.getRegisteredScope(scopeName) : null;
    final resolver = podFactory.getPodExpressionResolver();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Evaluating expression "$expression" in scope=$scopeName');
    }

    final result = await resolver?.evaluate(expression, PodExpressionContext(podFactory, scope));
    
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Expression was ${result?.getValue() != null ? "✅ successful" : "❌ not successful"}');
    }
    
    return result?.getValue() != null;
  }
}