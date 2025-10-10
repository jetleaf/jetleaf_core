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
import 'package:meta/meta_meta.dart';

import '../condition/condition.dart';
import '../condition/conditions.dart';
import '../condition/helpers.dart';

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL
// -------------------------------------------------------------------------------------------------------

/// {@template conditional}
/// The `Conditional` annotation in **Jetleaf** allows developers to specify 
/// conditions that must be satisfied for a class or method to be processed 
/// by the framework.
///
/// This annotation is typically used on configuration classes, pods, or 
/// methods that should only be included when certain runtime conditions are met. 
/// Conditions are implemented as classes that implement the [Condition] interface.
///
/// ### Key Features:
/// - Supports multiple conditions; all must match for the annotated type to be processed.
/// - Can be applied to both classes and methods.
///
/// ### Usage Example:
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// // A condition that only matches when the application is running in production
/// class OnProductionEnvironmentCondition implements Condition {
///   @override
///   bool matches(ConditionalContext context, ClassType<Object> classType) {
///     return context.environment.activeProfiles.contains('production');
///   }
/// }
///
/// // Apply conditional configuration
/// @Conditional([ClassType<OnProductionEnvironmentCondition>()])
/// class ProductionDataSourceConfig {
///   // Beans/pods defined here will only be registered in production
/// }
/// ```
///
/// In this example, `ProductionDataSourceConfig` will only be processed by Jetleaf 
/// if `OnProductionEnvironmentCondition` evaluates to `true`. This allows 
/// developers to define environment-specific configuration easily.
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
class Conditional extends ReflectableAnnotation with EqualsAndHashCode {
  /// {@template conditional_value}
  /// Condition classes that must match for the annotated type to be processed.
  ///
  /// These classes are typically implementations of the [Condition] interface.
  ///
  /// ### Example:
  /// ```dart
  /// @Conditional([ClassType<OnProductionEnvironmentCondition>()])
  /// class ProductionDataSourceConfig {}
  /// ```
  /// {@endtemplate}
  final List<ClassType<Condition>> conditions;

  /// {@macro conditional}
  const Conditional(this.conditions);

  @override
  String toString() => 'Conditional(value: $conditions)';

  @override
  Type get annotationType => Conditional;

  @override
  List<Object?> equalizedProperties() => [conditions];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON PROPERTY
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_property}
/// Marks a class or method as conditional based on the presence and value of 
/// configuration properties.
///
/// This annotation is used to include or exclude a class based on one
/// or more environment or system properties. It is commonly used in 
/// auto-configuration or module activation scenarios.
///
/// ### Matching Rules
/// - You can specify multiple names via `names`.
/// - If `havingValue` is specified, the property must match that value.
/// - If `havingValue` is omitted, the property must not be equal to `'false'`.
/// - If the property is missing and `matchIfMissing` is `true`, it will match.
///
/// ### Example
/// ```dart
/// @ConditionalOnProperty(
///   prefix: 'server',
///   names: ['ssl.enabled', 'ssl.enabled2'],
///   havingValue: 'true',
/// )
/// class SslServerConfig {}
/// ```
///
/// This activates `SslServerConfig` only if `server.ssl.enabled=true`.
/// {@endtemplate}
@Conditional([ClassType<OnPropertyCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnProperty extends ReflectableAnnotation with EqualsAndHashCode {
  /// Optional prefix to prepend to the property name(s).
  ///
  /// For example, prefix `server` with name `port` will match `server.port`.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnProperty(
  ///   prefix: 'server',
  ///   names: ['ssl.enabled', 'ssl.enabled2'],
  ///   havingValue: 'true',
  /// )
  /// class SslServerConfig {}
  /// ```
  final String? prefix;

  /// Alternative to [name]; defines multiple property names to match.
  ///
  /// Used when multiple properties should be checked.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnProperty(
  ///   prefix: 'server',
  ///   names: ['ssl.enabled', 'ssl.enabled2'],
  ///   havingValue: 'true',
  /// )
  /// class SslServerConfig {}
  /// ```
  final List<String> names;

  /// The expected value the property must equal for the condition to match.
  ///
  /// If omitted, the property must not be `'false'`.
  /// 
  /// ### Example:
  /// ```dart
  /// @ConditionalOnProperty(
  ///   prefix: 'server',
  ///   names: ['ssl.enabled', 'ssl.enabled2'],
  ///   havingValue: 'true',
  /// )
  /// class SslServerConfig {}
  /// ```
  final String? havingValue;

  /// Whether to match even if the property is not set.
  ///
  /// Defaults to `false`. Set to `true` to match when the property is missing.
  /// 
  /// ### Example:
  /// ```dart
  /// @ConditionalOnProperty(
  ///   prefix: 'server',
  ///   names: ['ssl.enabled', 'ssl.enabled2'],
  ///   havingValue: 'true',
  ///   matchIfMissing: true,
  /// )
  /// class SslServerConfig {}
  /// ```
  final bool matchIfMissing;

  /// {@macro conditional_on_property}
  const ConditionalOnProperty({
    this.prefix,
    this.names = const [],
    this.havingValue,
    this.matchIfMissing = false,
  });

  @override
  String toString() => 'ConditionalOnProperty('
      'prefix: $prefix, '
      'names: $names, '
      'havingValue: $havingValue, '
      'matchIfMissing: $matchIfMissing)';

  @override
  Type get annotationType => ConditionalOnProperty;

  @override
  List<Object?> equalizedProperties() => [
    prefix,
    names,
    havingValue,
    matchIfMissing,
  ];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON MISSING CLASS
// -------------------------------------------------------------------------------------------------------

/// {@template conditionalOnMissingClass}
/// The `ConditionalOnMissingClass` annotation in **Jetleaf** allows developers 
/// to conditionally process a class or method only when certain classes are 
/// **absent** from the runtime classpath.
///
/// This is useful for providing default implementations or fallback 
/// configurations when optional libraries or classes are missing.
///
/// ### Usage Examples:
/// ```dart
/// // Only load default cache if AdvancedCache is missing
/// @ConditionalOnMissingClass(value: [ClassType<AdvancedCache>()])
/// class DefaultCacheConfig {}
///
/// // Use fully qualified class names instead of direct references
/// @ConditionalOnMissingClass(name: ['package:jetleaf/example/jetleaf_example.dart.LoggingService'])
/// class DefaultLogger {}
/// ```
/// {@endtemplate}
@Conditional([ClassType<OnClassCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnMissingClass extends ReflectableAnnotation with EqualsAndHashCode {
  /// Classes that must be absent from the classpath.
  ///
  /// Uses actual Dart types for checking absence.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnMissingClass(value: [ClassType<AdvancedCache>()])
  /// class DefaultCacheConfig {}
  /// ```
  final List<ClassType<Object>> value;

  /// ClassType names (fully qualified) that must be absent from the classpath.
  ///
  /// Useful when you don’t want to directly reference the types.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnMissingClass(name: ['package:jetleaf/example/jetleaf_example.dart.LoggingService'])
  /// class DefaultLogger {}
  /// ```
  final List<String> names;

  /// {@macro conditionalOnMissingClass}
  const ConditionalOnMissingClass({
    this.value = const [],
    this.names = const [],
  });

  @override
  String toString() => 'ConditionalOnMissingClass(value: $value, name: $names)';

  @override
  Type get annotationType => ConditionalOnMissingClass;

  @override
  List<Object?> equalizedProperties() => [value, names];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON CLASS
// -------------------------------------------------------------------------------------------------------

/// {@template conditionalOnClass}
/// The `ConditionalOnClass` annotation in **Jetleaf** allows developers 
/// to conditionally process a class or method only when certain classes are 
/// **present** in the runtime classpath.
///
/// This is useful for optional dependencies, integration with external 
/// libraries, or conditional configuration based on class availability.
///
/// ### Usage Examples:
/// ```dart
/// // Only load HTTP client configuration if HttpClient exists
/// @ConditionalOnClass(value: [ClassType<HttpClient>()])
/// class HttpClientAutoConfig {}
///
/// // Use fully qualified class names to avoid compilation errors
/// @ConditionalOnClass(name: ['package:jetleaf/example/jetleaf_example.dart.LoggingService'])
/// class OptionalFeatureConfig {}
/// ```
/// {@endtemplate}
@Conditional([ClassType<OnClassCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnClass extends ReflectableAnnotation with EqualsAndHashCode {
  /// Classes that must be present at runtime.
  ///
  /// Uses actual Dart types for checking availability.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnClass(value: [ClassType<HttpClient>()])
  /// class HttpClientAutoConfig {}
  /// ```
  final List<ClassType<Object>> value;

  /// ClassType names (fully qualified) that must be present at runtime.
  ///
  /// This is useful when types are not directly referenced to avoid
  /// compilation errors if missing.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnClass(name: ['package:jetleaf/example/jetleaf_example.dart.LoggingService'])
  /// class OptionalFeatureConfig {}
  /// ```
  final List<String> names;

  /// {@macro conditionalOnClass}
  const ConditionalOnClass({
    this.value = const [],
    this.names = const [],
  });

  @override
  String toString() => 'ConditionalOnClass(value: $value, name: $names)';

  @override
  Type get annotationType => ConditionalOnClass;

  @override
  List<Object?> equalizedProperties() => [value, names];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON POD
// -------------------------------------------------------------------------------------------------------

/// {@template conditionalOnPod}
/// The `ConditionalOnPod` annotation in **Jetleaf** allows developers to 
/// conditionally process classes or methods based on the presence of specific 
/// pods in the application context.
///
/// This is especially useful when you want a configuration, service, or pod 
/// to only be loaded if another pod (or set of pods) already exists. 
/// Conditions can be defined by pod type, annotation, or name.
///
/// ### Key Features:
/// - Require specific pod types to exist in the context.
/// - Require pods annotated with certain annotations.
/// - Require pods with given names.
///
/// ### Usage Examples:
/// ```dart
/// // Require a specific pod type
/// @ConditionalOnPod(types: [ClassType<DataSource>()])
/// class JdbcTemplateConfig {}
///
/// // Require a pod with a specific name
/// @ConditionalOnPod(names: ['myCustomService'])
/// class FallbackServiceConfig {}
/// ```
///
/// Using this annotation ensures your configuration or beans are only 
/// registered when the expected pods are already available in the Jetleaf 
/// context.
/// {@endtemplate}
@Conditional([ClassType<OnPodCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnPod extends ReflectableAnnotation with EqualsAndHashCode {
  /// Pod types that must be present in the context.
  ///
  /// Equivalent to [type], kept for semantic clarity.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnPod(types: [ClassType<DataSource>()])
  /// class JdbcTemplateConfig {}
  /// ```
  final List<ClassType<Object>> types;

  /// Pod names that must be present in the context.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnPod(names: ['myCustomService'])
  /// class FallbackServiceConfig {}
  /// ```
  final List<String> names;

  /// {@macro conditionalOnPod}
  const ConditionalOnPod({this.types = const [], this.names = const []});

  @override
  String toString() => 'ConditionalOnPod(types: $types, names: $names)';

  @override
  Type get annotationType => ConditionalOnPod;

  @override
  List<Object?> equalizedProperties() => [types, names];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON MISSING POD
// -------------------------------------------------------------------------------------------------------

/// {@template conditionalOnMissingPod}
/// The `ConditionalOnMissingPod` annotation in **Jetleaf** allows developers 
/// to conditionally process a class or method only when certain pods are 
/// **not present** in the application context.
///
/// This is particularly useful for providing fallback configurations or 
/// alternative beans/pods when expected ones are absent.
///
/// ### Key Features:
/// - Ensures a pod is only loaded if another pod type or name is missing.
/// - Supports ignoring specific annotations when determining pod presence.
/// - Supports ignoring entire pod types to avoid conflicts with infrastructure.
///
/// ### Usage Examples:
/// ```dart
/// // Only load an embedded database when no DataSource is present
/// @ConditionalOnMissingPod(types: [ClassType<DataSource>()])
/// class EmbeddedDatabaseConfig {}
///
/// // Provide a fallback service if a specific pod name is missing
/// @ConditionalOnMissingPod(name: ['myCustomService'])
/// class FallbackServiceConfig {}
///
/// // Ignore infrastructure pods while checking for missing dependencies
/// @ConditionalOnMissingPod(
///   types: [ClassType<MyService>()],
///   ignoredTypes: [ClassType<DataSource>()],
/// )
/// class AlternativeServiceConfig {}
/// ```
///
/// This ensures Jetleaf applications remain flexible by enabling conditional 
/// fallbacks and context-aware configuration.
/// {@endtemplate}
@Conditional([ClassType<OnPodCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnMissingPod extends ReflectableAnnotation with EqualsAndHashCode {
  /// Pod types that must **not** be present in the context.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnMissingPod(types: [ClassType<DataSource>()])
  /// class EmbeddedDatabaseConfig {}
  /// ```
  final List<ClassType<Object>> types;

  /// Pod names that must **not** be present in the context.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnMissingPod(name: ['myCustomService'])
  /// class FallbackServiceConfig {}
  /// ```
  final List<String> names;

  /// Types to **ignore** while searching for conflicting pods.
  ///
  /// Often used to exclude infrastructure or support pods that shouldn’t 
  /// prevent fallback registration.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnMissingPod(
  ///   types: [ClassType<MyService>()],
  ///   ignoredTypes: [ClassType<DataSource>()],
  /// )
  /// class AlternativeServiceConfig {}
  /// ```
  final List<ClassType<Object>> ignoredTypes;

  /// {@macro conditionalOnMissingPod}
  const ConditionalOnMissingPod({
    this.types = const [],
    this.names = const [],
    this.ignoredTypes = const [],
  });

  @override
  String toString() => 'ConditionalOnMissingPod(types: $types, name: $names, ignoredTypes: $ignoredTypes)';

  @override
  Type get annotationType => ConditionalOnMissingPod;

  @override
  List<Object?> equalizedProperties() => [types, names, ignoredTypes];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON PROFILE
// -------------------------------------------------------------------------------------------------------

/// {@template conditionalOnProfile}
/// Marks a class or method to be included **only when specific profiles are active**.
///
/// This is useful for registering pods or configuration only in certain environments
/// such as `dev`, `test`, or `prod`.
///
/// ### Example
/// ```dart
/// @ConditionalOnProfile(['dev', 'local'])
/// class DevConfig {}
/// ```
///
/// If none of the specified profiles are active, the pod or class will be skipped.
/// 
/// Profile activation is typically controlled via `Environment.activeProfiles`.
/// {@endtemplate}
@Conditional([ClassType<OnProfileCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnProfile extends ReflectableAnnotation with EqualsAndHashCode {
  /// The set of profiles for which the annotated component should be registered.
  /// 
  /// ### Example:
  /// ```dart
  /// @ConditionalOnProfile(['dev', 'local'])
  /// class DevConfig {}
  /// ```
  final List<String> value;

  /// {@macro conditionalOnProfile}
  const ConditionalOnProfile(this.value);

  @override
  String toString() => 'ConditionalOnProfile(value: $value)';

  @override
  Type get annotationType => ConditionalOnProfile;

  @override
  List<Object?> equalizedProperties() => [value];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON DART
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_dart}
/// The `ConditionalOnDart` annotation in **Jetleaf** allows developers to 
/// conditionally process a class or method based on the Dart SDK version.
///
/// This annotation evaluates the Dart runtime version using the 
/// [OnDartCondition] condition class. Developers can specify a specific 
/// version or a range of versions that must match for the annotated element 
/// to be processed.
///
/// ### Usage Example:
/// ```dart
/// @ConditionalOnDart('3.1.0')
/// class ModernFeaturePod {
///   // This pod will only be loaded if the Dart SDK version matches 3.1.0
/// }
/// ```
/// {@endtemplate}
@Conditional([ClassType<OnDartCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnDart extends ReflectableAnnotation with EqualsAndHashCode {
  /// The Dart SDK version required for the annotated element to be processed.
  ///
  /// Can be a single version (e.g., '3.1.0') or interpreted by the condition 
  /// class to match a range.
  final String version;

  /// Optional version [Range] used internally by Jetleaf to evaluate 
  /// version constraints.
  final VersionRange range;

  /// {@macro conditional_on_dart}
  const ConditionalOnDart(this.version, [this.range = const VersionRange()]);

  @override
  String toString() => 'ConditionalOnDart(version: $version)';

  @override
  Type get annotationType => ConditionalOnDart;

  @override
  List<Object?> equalizedProperties() => [version, range];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON EXPRESSION
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_expression}
/// The `ConditionalOnExpression` annotation in **Jetleaf** allows developers 
/// to conditionally process a class or method based on a runtime expression.
///
/// This annotation uses [OnExpressionCondition] to evaluate the expression 
/// provided as a string. If the expression evaluates to `true`, the annotated 
/// element is processed.
///
/// ### Usage Example:
/// ```dart
/// @ConditionalOnExpression('env["ENABLE_FEATURE"] == "true"')
/// class FeaturePod {
///   // This pod will only be loaded if the expression evaluates to true
/// }
/// ```
/// {@endtemplate}
@Conditional([ClassType<OnExpressionCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnExpression extends ReflectableAnnotation with EqualsAndHashCode {
  /// The expression to evaluate for determining if the annotated element 
  /// should be processed.
  final Object expression;

  /// {@macro conditional_on_expression}
  const ConditionalOnExpression(this.expression);

  @override
  String toString() => 'ConditionalOnExpression(expression: $expression)';

  @override
  Type get annotationType => ConditionalOnExpression;

  @override
  List<Object?> equalizedProperties() => [expression];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON ASSET
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_asset}
/// The `ConditionalOnAsset` annotation in **Jetleaf** allows developers to 
/// conditionally process a class or method based on the presence of an asset.
///
/// This annotation uses [OnAssetCondition] to check whether a specified 
/// asset is available in the application's resources. If the asset exists, 
/// the annotated element is processed.
///
/// ### Usage Example:
/// ```dart
/// @ConditionalOnAsset('config/app_config.json')
/// class AppConfigPod {
///   // This pod will only be loaded if 'config/app_config.json' exists
/// }
/// ```
/// {@endtemplate}
@Conditional([ClassType<OnAssetCondition>()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnAsset extends ReflectableAnnotation with EqualsAndHashCode {
  /// The asset path that must exist for the annotated element to be processed.
  final String asset;

  /// {@macro conditional_on_asset}
  const ConditionalOnAsset(this.asset);

  @override
  String toString() => 'ConditionalOnAsset(asset: $asset)';

  @override
  Type get annotationType => ConditionalOnAsset;

  @override
  List<Object?> equalizedProperties() => [asset];
}