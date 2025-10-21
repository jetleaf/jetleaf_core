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

/// {@template on_property_condition}
/// A [Condition] implementation that evaluates whether a component or pod
/// should be activated based on the presence and value of properties
/// in the current [ConditionalContext.environment].
///
/// [OnPropertyCondition] is typically used in conjunction with the
/// [ConditionalOnProperty] annotation, which specifies property names,
/// optional prefixes, expected values, and whether missing properties
/// should still allow activation.
///
/// ### Behavior
///
/// - If the annotated element does **not** have a [ConditionalOnProperty]
///   annotation, this condition automatically passes.
/// - Retrieves the annotation from the source using [Annotation.getDirectAnnotation].
/// - For each property name:
///   - Combines the optional [prefix] with the property name to form the full key.
///   - Retrieves the property's value from [environment.getProperty].
///   - If the property is missing:
///     - Passes if [matchIfMissing] is `true`.
///     - Fails if [matchIfMissing] is `false`.
///   - If [havingValue] is specified, the property's value must match
///     (case-insensitive) to pass.
///   - If [havingValue] is not specified, any value equal to `"false"`
///     causes the condition to fail.
/// - Logs trace information at every evaluation step if logging is enabled.
///
/// ### Example
///
/// ```dart
/// @ConditionalOnProperty(
///   prefix: 'server',
///   names: ['ssl.enabled', 'ssl.enabled2'],
///   havingValue: 'true',
///   matchIfMissing: false,
/// )
/// class SslServerConfig {}
///
/// // During context evaluation:
/// final context = ConditionalContext(environment, podFactory, runtimeProvider);
/// final condition = OnPropertyCondition();
/// final shouldActivate = await condition.matches(context, source);
/// ```
///
/// ### Logging
///
/// Trace logging provides detailed step-by-step information:
/// - Annotation presence and retrieval.
/// - Property key resolution and value checks.
/// - Pass/fail decisions for each property.
///
/// ### Related Components
///
/// - [ConditionalContext]: Provides access to environment properties and
///   other conditional evaluation data.
/// - [ConditionalOnProperty]: Annotation that defines the properties to
///   evaluate for conditional activation.
/// - [Annotation]: The metadata source of the annotated element.
/// {@endtemplate}
class OnPropertyCondition implements Condition {
  /// {@macro on_property_condition}
  const OnPropertyCondition();

  @override
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source) async {
    final Log _logger = LogFactory.getLog(OnPropertyCondition);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnPropertyCondition for ${annotation.getSignature()}');
    }

    if (!annotation.matches<ConditionalOnProperty>()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @ConditionalOnProperty found → passing.');
      }

      return true;
    }

    final conditional = annotation.getInstance<ConditionalOnProperty>();
    final prefix = conditional.prefix;
    final names = conditional.names;
    final havingValue = conditional.havingValue;
    final matchIfMissing = conditional.matchIfMissing;

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('prefix=$prefix, names=$names, havingValue=$havingValue, matchIfMissing=$matchIfMissing');
    }

    for (final value in names) {
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
      _logger.trace('✅ OnPropertyCondition passed for ${annotation.getSignature()}');
    }

    return true;
  }
}

/// {@template on_class_condition}
/// A [Condition] implementation that evaluates the presence or absence of
/// classes in the current runtime to determine if a component, pod, or
/// configuration should be activated.
///
/// [OnClassCondition] works in conjunction with the [ConditionalOnClass]
/// and [ConditionalOnMissingClass] annotations. It checks for the existence
/// of required classes or ensures that specific classes are missing, enabling
/// conditional activation based on the application's classpath or type availability.
///
/// ### Behavior
///
/// - If the annotated element has a [ConditionalOnClass] annotation:
///   - Each type listed in the annotation is checked for existence.
///   - The condition fails if any required class is not present.
///   - The condition passes only if all required classes are found.
/// - If the annotated element has a [ConditionalOnMissingClass] annotation:
///   - Each type listed is checked for presence.
///   - The condition fails if any specified class exists.
///   - The condition passes only if all specified classes are absent.
/// - If neither annotation is present, the condition automatically passes.
/// - Detailed trace logging is available at every step when enabled, showing
///   evaluation of each class requirement or absence check.
///
/// ### Example
///
/// ```dart
/// // Activate only if AdvancedCache class exists
/// @ConditionalOnClass([ClassType<AdvancedCache>()])
/// class CacheConfig {}
///
/// // Activate only if LoggingService class is missing
/// @ConditionalOnMissingClass([ClassType<LoggingService>()])
/// class DefaultLoggerConfig {}
/// ```
///
/// During runtime evaluation:
///
/// ```dart
/// final context = ConditionalContext(environment, podFactory, runtimeProvider);
/// final condition = OnClassCondition();
/// final shouldActivate = await condition.matches(context, source);
/// ```
///
/// ### Logging
///
/// - Logs the evaluation of each required or missing class.
/// - Trace messages indicate pass/fail decisions and any missing or present
///   classes.
///
/// ### Related Components
///
/// - [ConditionalContext]: Provides the runtime environment for evaluating
///   class presence or absence.
/// - [ConditionalOnClass]: Annotation specifying required classes for
///   activation.
/// - [ConditionalOnMissingClass]: Annotation specifying classes that
///   must be absent for activation.
/// - [Annotation]: The metadata source of the annotated element.
/// {@endtemplate}
class OnClassCondition implements Condition {
  /// {@macro on_class_condition}
  const OnClassCondition();

  @override
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source) async {
    final Log _logger = LogFactory.getLog(OnClassCondition);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnClassCondition for ${annotation.getSignature()}');
    }

    // --- Handle @ConditionalOnClass ---
    if (annotation.matches<ConditionalOnClass>()) {
      final conditional = annotation.getInstance<ConditionalOnClass>();

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Found @ConditionalOnClass with ${conditional.value}');
      }

      for (final requiredType in conditional.value) {
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

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ OnClassCondition passed.');
      }
    }

    // --- Handle @ConditionalOnMissingClass ---
    if (annotation.matches<ConditionalOnMissingClass>()) {
      final conditional = annotation.getInstance<ConditionalOnMissingClass>();

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Found @ConditionalOnMissingClass with ${conditional.value}');
      }

      for (final missingType in conditional.value) {
        try {
          missingType.toClass();
          
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('❌ Found missingType ${missingType.getType()} → failing.');
          }

          return false;
        } catch (_) {}
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ OnMissingClassCondition passed.');
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('No relevant annotation found → passing.');
    }

    return true;
  }
}

/// {@template on_pod_condition}
/// A [Condition] implementation that evaluates the presence or absence of
/// pods in the current [ConditionalContext] to determine whether a component,
/// configuration, or definition should be activated.
///
/// [OnPodCondition] operates in conjunction with the [ConditionalOnPod] and
/// [ConditionalOnMissingPod] annotations. It checks whether specific pods
/// (by type or name) are present or missing in the application’s [PodFactory]
/// and adjusts component registration accordingly.
///
/// ### Behavior
///
/// - If the annotated element has a [ConditionalOnPod] annotation:
///   - For each required type listed in `types`, the condition searches
///     the [PodFactory] for existing pods of that type.
///   - For each name listed in `names`, the condition checks whether
///     a pod with that name exists.
///   - The condition fails if any required type or name is not found.
///   - The condition passes only if **all** specified pods exist or are
///     pending registration.
/// - If the annotated element has a [ConditionalOnMissingPod] annotation:
///   - For each type in `types`, the condition checks that no pod of
///     that type exists.
///   - For each name in `names`, the condition verifies that no pod
///     with that name exists.
///   - The `ignoredTypes` list can be used to exclude pods that should not
///     influence this evaluation (such as infrastructure or support pods).
///   - The condition passes only if **none** of the specified pods are
///     registered or queued for registration.
/// - If neither annotation is present, the condition automatically passes.
///
/// ### Example
///
/// ```dart
/// // Activate only if a DataSource pod exists
/// @ConditionalOnPod(types: [ClassType<DataSource>()])
/// class JdbcTemplateConfig {}
///
/// // Activate only if a remoteCache pod is missing
/// @ConditionalOnMissingPod(names: ['remoteCache'])
/// class InMemoryCacheConfig {}
/// ```
///
/// ### Evaluation Flow
///
/// 1. When [matches] is invoked, [OnPodCondition] retrieves all unregistered
///    [PodDefinition] instances from the [ConditionalContext].
/// 2. It evaluates the required pods by checking both the [PodFactory]
///    registry and unregistered definitions.
/// 3. If `@ConditionalOnPod` is present, all required types and names must
///    resolve successfully.
/// 4. If `@ConditionalOnMissingPod` is present, all specified pods must be
///    absent or ignored.
/// 5. The evaluation result determines whether the annotated component or pod
///    definition should proceed with activation.
///
/// ### Logging
///
/// - Provides detailed trace-level logging for each evaluation step.
/// - Logs include discovery of annotations, validation of pod types and names,
///   and pass/fail reasons.
/// - Trace messages include helpful markers like `✅` for success and `❌`
///   for failure, assisting in debugging startup conditions.
///
/// ### Related Components
///
/// - [ConditionalContext]: Provides runtime access to the environment,
///   [PodFactory], and pending [PodDefinition] instances.
/// - [ConditionalOnPod]: Annotation defining pods that **must exist** for
///   activation.
/// - [ConditionalOnMissingPod]: Annotation defining pods that **must not**
///   exist for activation.
/// - [PodFactory]: Manages pod lifecycle and provides lookup operations for
///   existing pods.
/// - [PodDefinition]: Represents an individual pod definition in the system.
/// - [Annotation]: Represents the metadata source of the annotated element.
/// {@endtemplate}
class OnPodCondition implements Condition {
  /// {@macro on_pod_condition}
  const OnPodCondition();

  @override
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source) async {
    final Log _logger = LogFactory.getLog(OnPodCondition);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnPodCondition for ${annotation.getSignature()}');
    }

    Future<bool> allClassesExists(Iterable<Class> classes) async {
      final results = await Future.wait(classes.map((cls) => context.podFactory.containsType(cls)));
      // Check if all results are true
      return results.all((match) => match);
    }

    Future<bool> allNamesExists(Iterable<String> names) async {
      final results = await Future.wait(names.map((name) => context.podFactory.containsPod(name)));
      // Check if all results are true
      return results.all((match) => match);
    }

    // --- Handle @ConditionalOnPod ---
    if (annotation.matches<ConditionalOnPod>()) {
      final conditional = annotation.getInstance<ConditionalOnPod>();

      if (conditional.types.isNotEmpty && conditional.names.isNotEmpty) {
        return await allClassesExists(conditional.types.map((type) => type.toClass()))
          && await allNamesExists(conditional.names.map((name) => name));
      }

      if (conditional.types.isNotEmpty) {
        return await allClassesExists(conditional.types.map((type) => type.toClass()));
      }

      if (conditional.names.isNotEmpty) {
        return await allNamesExists(conditional.names.map((name) => name));
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ OnPodCondition passed.');
      }
    }

    // --- Handle @ConditionalOnMissingPod ---
    if (annotation.matches<ConditionalOnMissingPod>()) {
      final conditional = annotation.getInstance<ConditionalOnMissingPod>();

      for (final ignoredType in conditional.ignoredTypes) {
        context.podFactory.registerIgnoredDependency(ignoredType.toClass());
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Registered ignored dependency: ${ignoredType.getType()}');
        }
      }

      if (conditional.types.isNotEmpty && conditional.names.isNotEmpty) {
        return !await allClassesExists(conditional.types.map((type) => type.toClass()))
          && !await allNamesExists(conditional.names.map((name) => name));
      }

      if (conditional.types.isNotEmpty) {
        return !await allClassesExists(conditional.types.map((type) => type.toClass()));
      }

      if (conditional.names.isNotEmpty) {
        return !await allNamesExists(conditional.names.map((name) => name));
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ OnMissingPodCondition passed.');
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('No relevant annotation found → passing.');
    }

    return true;
  }
}

/// {@template on_profile_condition}
/// A [Condition] implementation that evaluates the application's currently
/// active profiles to determine whether a component, configuration, or pod
/// should be activated.
///
/// [OnProfileCondition] supports both the [Profile] and [ConditionalOnProfile]
/// annotations. It provides flexible control over pod, and configuration
/// activation based on environment-specific profiles (e.g., `"dev"`, `"test"`,
/// `"prod"`).
///
/// This condition enables developers to restrict certain components to specific
/// runtime contexts, improving modularity and enabling environment-sensitive
/// configuration in JetLeaf applications.
///
/// ### Behavior
///
/// - If the annotated element includes a [Profile] annotation:
///   - Each declared profile is compared against the set of active profiles
///     in the [Environment].
///   - If `negate` is **false**, all specified profiles must be **active**
///     for the condition to pass.
///   - If `negate` is **true**, all specified profiles must be **inactive**
///     for the condition to pass.
///   - The condition fails if any profile violates these rules.
/// - If the annotated element includes a [ConditionalOnProfile] annotation:
///   - The annotation’s `value` list specifies profiles that must be active
///     in the environment.
///   - If none of the specified profiles are active, the condition fails.
///   - The condition passes if at least one of the declared profiles is active.
/// - If neither annotation is present, the condition automatically passes.
///
/// ### Example
///
/// ```dart
/// // Activate only in the 'dev' profile
/// @ConditionalOnProfile(['dev'])
/// class DevConfiguration {}
///
/// // Exclude this component when 'test' profile is active
/// @Profile(['test'], negate: true)
/// class ProductionDatabasePod {}
/// ```
///
/// ### Evaluation Flow
///
/// 1. When [matches] is invoked, [OnProfileCondition] retrieves the currently
///    active profiles from the [Environment].
/// 2. If a [Profile] annotation is present:
///    - Each listed profile is checked against the active profile set.
///    - Negation logic is applied if `negate: true`.
/// 3. If a [ConditionalOnProfile] annotation is present:
///    - The condition validates whether any declared profile is active.
/// 4. If neither annotation applies, the condition passes automatically.
/// 5. The result determines whether the annotated component or configuration
///    should be registered.
///
/// ### Logging
///
/// - Detailed trace logs show all evaluated annotations and profiles.
/// - Logs display active profiles, matched/failed conditions, and negation state.
/// - Uses icons and structured output for clarity:
///   - `✅` for successful matches
///   - `❌` for failed evaluations
///   - `🧩` for condition initialization
///
/// ### Related Components
///
/// - [ConditionalContext]: Provides access to the [Environment] and runtime state.
/// - [ConditionalOnProfile]: Annotation specifying profiles required for activation.
/// - [Profile]: Annotation specifying inclusion or exclusion rules for profiles.
/// - [Environment]: Holds the currently active and default profiles.
/// - [Annotation]: Represents the annotated element under evaluation.
/// {@endtemplate}
class OnProfileCondition implements Condition {
  /// {@macro on_profile_condition}
  const OnProfileCondition();

  @override
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source) async {
    final Log _logger = LogFactory.getLog(OnProfileCondition);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnProfileCondition for ${annotation.getSignature()}');
    }

    final activeProfiles = context.environment.getActiveProfiles();
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('Active profiles: $activeProfiles');
    }

    // --- Handle @Profile annotation ---
    if (annotation.matches<Profile>()) {
      final profile = annotation.getInstance<Profile>();

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Found @Profile annotation on ${annotation.getSignature()} with profiles: ${profile.profiles}');
      }

      for (final name in profile.profiles) {
        final isMismatch = profile.negate ? activeProfiles.contains(name) : !activeProfiles.contains(name);

        if (isMismatch) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('❌ Profile condition failed to match ${profile.negate ? '(negated)' : ''}: $name');
          }
          return false;
        }
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ Profile condition matched for ${annotation.getSignature()}');
      }
    }

    // --- Handle @ConditionalOnProfile annotation ---
    if (annotation.matches<ConditionalOnProfile>()) {
      final conditional = annotation.getInstance<ConditionalOnProfile>();
      
      final profiles = conditional.value;

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Required profiles: $profiles');
      }

      final isFalse = profiles.isNotEmpty && profiles.none((profile) => activeProfiles.contains(profile));

      if (isFalse) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('❌ No matching profile found → failing.');
        }
        return false;
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ Matching profile found → passing.');
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('No @ConditionalOnProfile found → passing.');
    }

    return true;
  }
}

/// {@template on_dart_condition}
/// A [Condition] implementation that evaluates the current Dart SDK version
/// to determine whether an annotated component, configuration, or pod
/// should be activated.
///
/// [OnDartCondition] works together with the [ConditionalOnDart] annotation
/// to perform fine-grained control over component activation based on the
/// Dart runtime version or version range.  
///
/// This condition is particularly useful for maintaining compatibility
/// across different Dart SDK releases, enabling or disabling features that
/// rely on language changes or version-dependent APIs.
///
/// ### Behavior
///
/// - If the annotated element includes a [ConditionalOnDart] annotation:
///   - The `version` field specifies the exact Dart version required.
///   - The optional `range` field defines a [VersionRange] that may include
///     multiple acceptable versions.
///   - The current runtime version is obtained from the [RuntimeProvider].
///   - The condition passes if the running Dart version **matches** the
///     specified version or **falls within** the specified range.
///   - Otherwise, the condition fails.
/// - If no [ConditionalOnDart] annotation is found, the condition
///   automatically passes.
///
/// ### Example
///
/// ```dart
/// // Activate only if running on Dart 3.1.0
/// @ConditionalOnDart('3.1.0')
/// class Dart31Config {}
///
/// // Activate for any version from 3.0.0 to 3.5.0 (inclusive)
/// @ConditionalOnDart('3.0.0', VersionRange(min: Version(3, 0, 0), max: Version(3, 5, 0)))
/// class ModernFeatureSupport {}
/// ```
///
/// ### Evaluation Flow
///
/// 1. When [matches] is invoked, the condition looks for a [ConditionalOnDart]
///    annotation on the provided [Annotation].
/// 2. If found, it retrieves the required version and version range.
/// 3. The current Dart version is extracted from the [RuntimeProvider] via
///    the [PackageNames.DART] reference.
/// 4. The condition passes if:
///    - The runtime version exactly matches the declared version, or  
///    - The runtime version is contained within the declared [VersionRange].
/// 5. If no annotation is found or the runtime version cannot be determined,
///    the condition passes by default.
///
/// ### Logging
///
/// - Logs key evaluation steps with clear semantic markers:
///   - `🧩` when condition evaluation begins.
///   - `✅` for version matches or range inclusion.
///   - `❌` for version mismatches or absent Dart runtime data.
/// - When trace logging is enabled, logs include:
///   - Required version and range.
///   - Detected runtime version.
///   - Resolution path (exact match vs range match).
///
/// ### Related Components
///
/// - [ConditionalOnDart]: Annotation defining the required Dart SDK version.
/// - [VersionRange]: Specifies the allowed semantic version interval.
/// - [RuntimeProvider]: Supplies runtime package information for evaluation.
/// - [ConditionalContext]: Provides the environment and runtime context.
/// - [Annotation]: Represents the annotated element under evaluation.
/// {@endtemplate}
class OnDartCondition implements Condition {
  /// {@macro on_dart_condition}
  const OnDartCondition();

  @override
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source) async {
    final Log _logger = LogFactory.getLog(OnDartCondition);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnDartCondition for ${annotation.getSignature()}');
    }

    if (!annotation.matches<ConditionalOnDart>()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @ConditionalOnDart found → passing.');
      }

      return true;
    }

    final conditional = annotation.getInstance<ConditionalOnDart>();
    final version = conditional.version;
    final range = conditional.range;
    final runningVersion = context.runtimeProvider.getAllPackages().find((p) => p.getName() == PackageNames.DART);

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

/// {@template on_asset_condition}
/// A [Condition] implementation that determines whether an annotated component, 
/// configuration, or pod should be activated based on the presence of a 
/// specific asset within the application's resource path.
///
/// [OnAssetCondition] works together with the [ConditionalOnAsset] annotation 
/// to enable or disable configuration elements depending on whether an 
/// asset file (such as configuration JSON, YAML, or other resource) exists
/// at the specified path.
///
/// This condition is particularly useful for auto-configuration systems
/// that adapt behavior dynamically based on available files in the
/// application bundle or runtime environment.
///
/// ### Behavior
///
/// - If the annotated element includes a [ConditionalOnAsset] annotation:
///   - The `asset` field defines the path of the asset that must exist.
///   - The condition uses [DefaultAssetPathResource] to verify accessibility
///     of the asset.
///   - The condition passes if the asset exists and is retrievable.
///   - If the asset is missing, the condition fails, preventing activation
///     of the annotated element.
/// - If no [ConditionalOnAsset] annotation is present, the condition passes
///   automatically.
///
/// ### Example
///
/// ```dart
/// // Activate configuration only if `config/app_config.json` exists
/// @ConditionalOnAsset('config/app_config.json')
/// class AppConfigPod {}
///
/// // Activate only when a credentials file is available
/// @ConditionalOnAsset('secrets/credentials.yaml')
/// class SecureConfig {}
/// ```
///
/// ### Evaluation Flow
///
/// 1. When [matches] is invoked, the condition checks whether the [Annotation]
///    has a [ConditionalOnAsset] annotation.
/// 2. If present, it extracts the declared `asset` path.
/// 3. It creates a [DefaultAssetPathResource] instance with that path and 
///    attempts to resolve it using [DefaultAssetPathResource.tryGet].
/// 4. The condition passes (`true`) if the asset is found and accessible.
/// 5. If the asset cannot be located or read, the condition fails (`false`).
/// 6. If no annotation is detected, the condition passes by default.
///
/// ### Logging
///
/// When trace logging is enabled:
/// - Logs the start of evaluation with the annotated element name.
/// - Logs the asset path being evaluated.
/// - Emits `✅` when the asset is found and accessible.
/// - Emits `❌` when the asset is missing or cannot be read.
/// - Logs all intermediate decisions to aid debugging in conditional
///   configuration flows.
///
/// ### Related Components
///
/// - [ConditionalOnAsset]: Annotation declaring the asset path to check.
/// - [DefaultAssetPathResource]: Utility for verifying the existence and 
///   accessibility of asset files.
/// - [ConditionalContext]: Provides the runtime context and resource access
///   for evaluation.
/// - [Source]: Represents the annotated class or method being evaluated.
/// - [Condition]: Base interface for all JetLeaf condition evaluators.
/// {@endtemplate}
class OnAssetCondition implements Condition {
  /// {@macro on_asset_condition}
  const OnAssetCondition();

  @override
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source) async {
    final Log _logger = LogFactory.getLog(OnAssetCondition);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnAssetCondition for ${annotation.getSignature()}');
    }

    if (!annotation.matches<ConditionalOnAsset>()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @ConditionalOnAsset found → passing.');
      }

      return true;
    }

    final conditional = annotation.getInstance<ConditionalOnAsset>();
    final asset = conditional.asset;
    final resource = DefaultAssetPathResource(asset);

    if (resource.tryGet() != null) {
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

/// {@template on_expression_condition}
/// A [Condition] implementation that dynamically evaluates an expression to 
/// determine whether a component, configuration, or pod should be activated.
///
/// [OnExpressionCondition] works in conjunction with the [ConditionalOnExpression]
/// annotation to enable or disable annotated elements based on the result of
/// an evaluated expression. This allows developers to declaratively define 
/// logical or contextual conditions that control configuration activation.
///
/// ### Purpose
///
/// This condition is especially useful for scenarios where simple presence-based 
/// conditions (e.g., [OnClassCondition], [OnPropertyCondition]) are not sufficient.
/// It enables fine-grained activation logic using dynamic expressions that 
/// can reference pods, scopes, or runtime environment properties.
///
/// Expressions are evaluated using JetLeaf’s [PodExpressionResolver], which 
/// supports structured resolution against the active [PodFactory] and 
/// optionally within a [Scope].
///
/// ### Behavior
///
/// - If a [ConditionalOnExpression] annotation is present on the [Annotation]:
///   - The annotation’s `expression` field defines the condition to evaluate.
///   - The expression is resolved in the context of the current [PodFactory].
///   - If a [Scope] annotation is also present, the expression is evaluated
///     within that scope’s registered pod namespace.
///   - The condition passes (`true`) if the expression evaluates successfully
///     and produces a non-null result.
///   - The condition fails (`false`) if the evaluation returns `null`, throws
///     an error, or the expression cannot be resolved.
/// - If no [ConditionalOnExpression] annotation is present, the condition passes
///   automatically.
/// - If expression resolution is unavailable (no [PodExpressionResolver]),
///   evaluation defaults to `false` for safety.
///
/// ### Example
///
/// ```dart
/// // Activates only if a specific property evaluates to true
/// @ConditionalOnExpression("env['jetleaf.enableFeatureX'] == true")
/// class FeatureXPod {}
///
/// // Scoped expression example
/// @Scope('web')
/// @ConditionalOnExpression("pods.contains('httpServer')")
/// class WebServerPod {}
/// ```
///
/// ### Evaluation Flow
///
/// 1. The condition checks for the presence of a [ConditionalOnExpression] 
///    annotation on the [Annotation].
/// 2. If found, it retrieves the associated expression string.
/// 3. It looks for a [Scope] annotation to determine the appropriate
///    evaluation context.
/// 4. It obtains a [PodExpressionResolver] from the [PodFactory].
/// 5. The resolver executes the expression inside a [PodExpressionContext],
///    passing in the [PodFactory] and the optional scope.
/// 6. If the expression returns a non-null value, the condition passes;
///    otherwise, it fails.
/// 7. If no expression annotation is found, the condition passes by default.
///
/// ### Logging
///
/// When trace logging is enabled:
/// - Logs the start of evaluation for each annotated source.
/// - Logs the expression being evaluated and the target scope (if any).
/// - Emits `✅` when evaluation returns a non-null value.
/// - Emits `❌` when the result is null or evaluation fails.
/// - Captures all intermediate evaluation details to aid conditional debugging.
///
/// ### Related Components
///
/// - [ConditionalOnExpression]: Declares the expression that determines activation.
/// - [PodExpressionResolver]: Executes the expression logic within the context.
/// - [PodExpressionContext]: Provides access to pods and scoped runtime state.
/// - [Scope]: Defines the contextual scope in which the expression is evaluated.
/// - [PodFactory]: Provides registered pods and access to the resolver.
/// - [ConditionalContext]: Supplies the overall evaluation environment.
/// - [Annotation]: Represents the annotated class or method being processed.
/// {@endtemplate}
class OnExpressionCondition implements Condition {
  /// {@macro on_expression_condition}
  const OnExpressionCondition();

  @override
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source) async {
    final Log _logger = LogFactory.getLog(OnExpressionCondition);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Evaluating OnExpressionCondition for ${annotation.getSignature()}');
    }

    if (!annotation.matches<ConditionalOnExpression>()) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('No @ConditionalOnExpression found → passing.');
      }

      return true;
    }
    
    final conditional = annotation.getInstance<ConditionalOnExpression>();
    Scope? scopeProperty;

    if (source.hasDirectAnnotation<Scope>()) {
      scopeProperty = source.getDirectAnnotation<Scope>();
    } else if (source is Class && source.hasAnnotation<Scope>()) {
      scopeProperty = source.getAnnotation<Scope>();
    }

    final scopeName = scopeProperty?.value;
    final expression = conditional.expression;
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