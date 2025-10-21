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
/// An annotation that conditionally enables or disables JetLeaf-managed
/// constructs such as [Component], [Pod], or configuration classes based
/// on one or more declarative [Condition] evaluators.
///
/// The [Conditional] annotation is a reflective directive that instructs
/// the JetLeaf framework to include the annotated type or method only if
/// **all** specified [conditions] evaluate to `true` during pod resolution.
///
/// ### Purpose
///
/// In a modular JetLeaf application, certain [Component]s or configuration
/// classes may only be applicable under specific runtime contexts, such as
/// environment, platform, or other application state. [Conditional] provides
/// a declarative and compile-time safe mechanism to express these
/// contextual dependencies.
///
/// ### Behavior
///
/// - Each class in [conditions] must implement [Condition].
/// - Each condition class **must have a `const` constructor** so that
///   [Conditional] can be used as a compile-time constant.
/// - JetLeaf evaluates all conditions in the order they are declared. The
///   annotated construct is processed only if **every** condition returns
///   `true` via [Condition.matches].
///
/// ### Example
///
/// ```dart
/// class OnProductionEnvironmentCondition implements Condition {
///   const OnProductionEnvironmentCondition();
///
///   @override
///   bool matches(Environment env) => env.isProduction();
/// }
///
/// @Conditional([OnProductionEnvironmentCondition()])
/// class ProductionDataSourceConfig {}
/// ```
///
/// Declaring conditions as `const` ensures deterministic evaluation and
/// eliminates runtime instantiation overhead.
///
/// ### Related Components
///
/// - [Condition]: Interface that defines the logical predicate for
///   conditional activation.
/// - [ConditionalContext]: JetLeaf context responsible for evaluating conditions
///   and initializing pods.
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.method})
final class Conditional extends ReflectableAnnotation with EqualsAndHashCode {
  /// {@template when_conditional_field_key}
  /// The key used to store or reference condition information for
  /// a `Conditional` annotation. It matches [conditions] in [Conditional]
  ///
  /// This constant is typically used as a metadata key when inspecting
  /// annotations that are associated with conditional processing.
  ///
  /// ### Example
  /// ```dart
  /// final conditions = annotation.getFieldValue(Conditional.FIELD_KEY);
  /// ```
  /// {@endtemplate}
  static const String FIELD_KEY = "conditions";

  /// {@template conditional_value}
  /// Condition classes that must match for the annotated type or method
  /// to be processed.
  ///
  /// Each class in [conditions] must implement the [Condition] interface,
  /// **and its constructor must be declared as `const`**.  
  /// This allows the `@Conditional` annotation itself to be used as a
  /// compile-time constant, enabling the Dart analyzer and reflection
  /// system to resolve it safely.
  ///
  /// ### Example:
  /// ```dart
  /// class OnProductionEnvironmentCondition implements Condition {
  ///   const OnProductionEnvironmentCondition();
  ///
  ///   @override
  ///   bool matches(Environment env) => env.isProduction();
  /// }
  ///
  /// @Conditional([OnProductionEnvironmentCondition()])
  /// class ProductionDataSourceConfig {}
  /// ```
  ///
  /// Declaring `const` constructors in condition classes ensures that
  /// they can be evaluated deterministically and used in annotation
  /// metadata without runtime instantiation overhead.
  /// {@endtemplate}
  final List<Condition> conditions;

  /// {@macro conditional}
  const Conditional(this.conditions);

  @override
  String toString() => 'Conditional(value: $conditions)';

  @override
  Type get annotationType => Conditional;

  @override
  List<Object?> equalizedProperties() => [conditions];
}

/// {@template when_conditional}
/// The base class for all annotations that are eligible for conditional
/// evaluation in the JetLeaf framework.
///
/// [WhenConditional] serves as a marker class for annotations that may be
/// decorated with [Conditional] or its specialized variants (e.g., 
/// [ConditionalOnClass], [ConditionalOnProperty], [ConditionalOnPod], etc.).
///
/// Any annotation that **does not extend or implement [WhenConditional]**
/// will be ignored by the [ConditionEvaluator] during runtime pod or 
/// configuration evaluation. This ensures that only explicitly marked 
/// annotations participate in JetLeaf's conditional activation logic.
///
/// ### Purpose
///
/// - Acts as a **type filter** for the JetLeaf [ConditionEvaluator].
/// - Ensures that only supported conditional annotations are evaluated.
/// - Provides a common base for equality and hash code behavior through 
///   [EqualsAndHashCode].
///
/// ### Example
///
/// ```dart
/// @Conditional([OnPropertyCondition()])
/// class ConditionalOnProperty extends WhenConditional {
///   final List<String> names;
///   const ConditionalOnProperty({this.names = const []});
/// }
///
/// // During evaluation:
/// // Only annotations extending WhenConditional are processed.
/// ```
///
/// ### Related Components
///
/// - [Conditional]: The general annotation that enables conditional evaluation.
/// - [ConditionEvaluator]: Responsible for evaluating conditions on annotations.
/// - [EqualsAndHashCode]: Ensures consistent equality and hashcode behavior
///   for all annotations extending this base class.
/// {@endtemplate}
abstract class WhenConditional extends ReflectableAnnotation with EqualsAndHashCode {
  /// {@macro when_conditional}
  const WhenConditional();
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON PROPERTY
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_property}
/// An annotation that conditionally enables a [Component], [Pod], or
/// configuration class based on the value(s) of one or more properties.
///
/// The [ConditionalOnProperty] annotation evaluates property values at
/// runtime and only allows the annotated type or method to be processed
/// if the specified property conditions are met. This is particularly
/// useful for feature toggles, environment-specific configuration,
/// or conditional module activation.
///
/// ### Purpose
///
/// In JetLeaf applications, certain components or configurations may only
/// be relevant when specific properties are present or have certain values.
/// [ConditionalOnProperty] allows declarative, property-based activation
/// without requiring procedural checks in the component initialization
/// logic.
///
/// ### Behavior
///
/// - [prefix] can be prepended to property names when matching, allowing
///   hierarchical property keys like `server.port`.
/// - [names] is a list of property names to check; at least one property
///   in the list must match the expected condition.
/// - [havingValue] is the expected property value; if omitted, any value
///   other than `'false'` is considered a match.
/// - [matchIfMissing] determines whether a missing property should count
///   as a match. Defaults to `false`.
///
/// ### Example
///
/// ```dart
/// @ConditionalOnProperty(
///   prefix: 'server',
///   names: ['ssl.enabled', 'ssl.enabled2'],
///   havingValue: 'true',
/// )
/// class SslServerConfig {}
/// ```
///
/// This configuration will only activate if the property `server.ssl.enabled`
/// or `server.ssl.enabled2` equals `'true'`.
///
/// ### Related Components
///
/// - [ConditionalContext]: Evaluates properties and determines whether to
///   instantiate the annotated type.
/// - [Conditional]: The general conditional annotation framework that
///   [ConditionalOnProperty] builds upon.
/// {@endtemplate}
@Conditional([OnPropertyCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnProperty extends WhenConditional {
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
  List<Object?> equalizedProperties() => [prefix, names, havingValue, matchIfMissing];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON MISSING CLASS
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_missing_class}
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class only if certain classes are **absent** from the
/// Dart runtime or classpath.
///
/// The [ConditionalOnMissingClass] annotation instructs JetLeaf to process
/// the annotated type or method only when all classes listed in [value]
/// are missing. This supports defining default or fallback configurations
/// without introducing hard dependencies.
///
/// ### Purpose
///
/// In modular JetLeaf applications, it is common to provide default
/// implementations or fallback components that should only be active when
/// more specific classes are not present. [ConditionalOnMissingClass]
/// enables this declaratively, avoiding manual runtime type checks.
///
/// ### Behavior
///
/// - [value] contains instances of [ClassType] representing the types that
///   must be absent.
/// - [ClassType] supports either actual Dart types (`ClassType<SomeClass>()`)
///   or fully qualified names (`ClassType.qualified('package:...')`) for
///   safe reference without importing the class directly.
/// - The annotated element is only processed if **all specified classes are missing**.
///
/// ### Example
///
/// ```dart
/// @ConditionalOnMissingClass([ClassType<AdvancedCache>()])
/// class DefaultCacheConfig {}
///
/// // Using fully qualified names to avoid compilation issues
/// @ConditionalOnMissingClass([ClassType.qualified('package:jetleaf/example/jetleaf_example.dart.LoggingService')])
/// class DefaultCacheConfig {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext]: Evaluates pod absence and manages conditional initialization.
/// - [Conditional]: The general conditional annotation framework that
///   [ConditionalOnMissingClass] extends.
/// {@endtemplate}
@Conditional([OnClassCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnMissingClass extends WhenConditional {
  /// Classes that must be absent from the classpath.
  ///
  /// Uses actual Dart types or JetLeaf's qualified names for checking absence.
  ///
  /// ### Example:
  /// ```dart
  /// @ConditionalOnMissingClass([ClassType<AdvancedCache>()])
  /// class DefaultCacheConfig {}
  /// 
  /// or for compilation issues
  /// @ConditionalOnMissingClass([ClassType.qualified('package:jetleaf/example/jetleaf_example.dart.LoggingService')])
  /// class DefaultCacheConfig {}
  /// ```
  final List<ClassType<Object>> value;

  /// {@macro conditional_on_missing_class}
  const ConditionalOnMissingClass([this.value = const []]);

  @override
  String toString() => 'ConditionalOnMissingClass($value)';

  @override
  Type get annotationType => ConditionalOnMissingClass;

  @override
  List<Object?> equalizedProperties() => value;
}

/// {@template conditional_on_class}
/// An annotation that conditionally enables a [Component], [Pod], or
/// configuration class only if certain classes are **present** in the Dart
/// runtime or classpath.
///
/// The [ConditionalOnClass] annotation instructs JetLeaf to process the
/// annotated type or method only when all classes listed in [value] exist.
/// This allows declarative activation of components that depend on specific
/// optional or external classes.
///
/// ### Purpose
///
/// In JetLeaf applications, some components or configuration classes should
/// only be loaded if certain other classes are available. [ConditionalOnClass]
/// provides a safe and declarative way to express such dependencies without
/// requiring procedural runtime checks.
///
/// ### Behavior
///
/// - [value] contains instances of [ClassType] representing the classes
///   that must be present for activation.
/// - [ClassType] supports either actual Dart types (`ClassType<SomeClass>()`)
///   or fully qualified names (`ClassType.qualified('package:...')`) to avoid
///   direct import dependencies.
/// - The annotated element is only processed if **all specified classes exist**.
///
/// ### Example
///
/// ```dart
/// @ConditionalOnClass([ClassType<AdvancedCache>()])
/// class AdvancedCacheConfig {}
///
/// @ConditionalOnClass([ClassType.qualified('package:jetleaf/example/jetleaf_example.dart.LoggingService')])
/// class LoggingConfig {}
/// ```
///
/// ### Related Components
/// 
/// - [ConditionalContext]: Evaluates pod absence and manages conditional initialization.
/// - [Conditional]: General conditional annotation framework that
///   [ConditionalOnClass] extends.
/// {@endtemplate}
@Conditional([OnClassCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnClass extends WhenConditional {
  /// Classes that must be present in the classpath for the annotated
  /// type or method to be processed.
  ///
  /// This is a list of [ClassType] instances representing required Dart
  /// types or qualified class names. The annotated element is processed
  /// only if **all classes** in [value] exist.
  final List<ClassType<Object>> value;

  /// {@macro conditional_on_class}
  const ConditionalOnClass([this.value = const []]);

  @override
  String toString() => 'ConditionalOnClass($value)';

  @override
  Type get annotationType => ConditionalOnClass;

  @override
  List<Object?> equalizedProperties() => value;
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON POD
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_pod}
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class based on the presence of other pods within the
/// current [ConditionalContext].
///
/// The [ConditionalOnPod] annotation allows the JetLeaf framework to
/// declaratively control which constructs are instantiated or registered
/// by evaluating dependencies on existing pods. This enables modular
/// configuration and ensures that certain components are only loaded when
/// their required pods are available.
///
/// ### Purpose
///
/// In complex JetLeaf applications, some components should only initialize
/// if their dependencies (pods) are present. Instead of manually checking
/// for these pods at runtime, [ConditionalOnPod] provides a declarative,
/// framework-native mechanism for:
///
/// - Enforcing type-safe pod dependencies using [types].
/// - Checking for specific pod identifiers using [names].
/// - Avoiding initialization errors or unnecessary object creation when
///   dependencies are missing.
/// - Supporting conditional wiring and composition in modular pod designs.
///
/// ### Behavior
///
/// - [types] contains [ClassType] instances representing the required pod
///   types. The annotated element will only be processed if **all** of
///   these types are present in the current [ConditionalContext].
/// - [names] contains string identifiers of pods that must exist. Useful
///   when type references are not sufficient or to check for dynamically
///   registered pods.
/// - The evaluation is performed during pod resolution. If any required
///   type or name is missing, the annotated component will be skipped
///   without throwing an error, maintaining graceful degradation.
///
/// ### Example
///
/// ```dart
/// // Activate only if a DataSource pod is present
/// @ConditionalOnPod(types: [ClassType<DataSource>()])
/// class JdbcTemplateConfig {}
///
/// // Activate only if a pod named 'myCustomService' exists
/// @ConditionalOnPod(names: ['myCustomService'])
/// class FallbackServiceConfig {}
///
/// // Activate only if both a type and name condition are met
/// @ConditionalOnPod(
///   types: [ClassType<Cache>()],
///   names: ['metricsService']
/// )
/// class CachedMetricsConfig {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext]: Evaluates pod absence and manages conditional initialization.
/// - [Conditional]: The base conditional annotation that [ConditionalOnPod]
///   builds upon for evaluating contextual activation rules.
/// - [ClassType]: Represents type references used for type-safe pod
///   checks.
/// {@endtemplate}
@Conditional([OnPodCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnPod extends WhenConditional {
  /// Pod types that must be present in the [ConditionalContext] for the annotated
  /// element to be processed.
  ///
  /// This field is used for type-safe checks, allowing the JetLeaf
  /// framework to determine the presence of required pods by type. The
  /// annotated component will only be activated if **all specified types**
  /// exist.
  final List<ClassType<Object>> types;

  /// Pod names that must be present in the [ConditionalContext] for the annotated
  /// element to be processed.
  ///
  /// This field provides flexibility for identifying pods by string
  /// identifiers rather than types. It is particularly useful when
  /// pod registration occurs dynamically, or type references are not
  /// available. The annotated component will only be activated if
  /// **all specified names** exist in the pod context.
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

/// {@template conditional_on_missing_pod}
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class only if certain pods are **absent** from the
/// current [ConditionalContext].
///
/// The [ConditionalOnMissingPod] annotation enables JetLeaf to define
/// fallback or alternative components that should only be initialized
/// when specified pods are missing. This supports graceful degradation
/// and modular configuration without causing runtime errors.
///
/// ### Purpose
///
/// In JetLeaf applications, it is common to provide default or alternative
/// configurations that should only be active if certain pods are not
/// registered. [ConditionalOnMissingPod] provides a declarative way to:
///
/// - Avoid conflicts with existing pods.
/// - Conditionally register fallback services or configurations.
/// - Exclude infrastructure or support pods from blocking fallback
///   registration using [ignoredTypes].
///
/// ### Behavior
///
/// - [types] is a list of [ClassType] representing pod types that must
///   **not** exist for the annotated element to be processed.
/// - [names] is a list of pod names that must **not** exist for activation.
/// - [ignoredTypes] allows certain pod types to be disregarded when
///   evaluating conflicts. This is useful for excluding common or
///   infrastructure pods that should not prevent fallback registration.
/// - The annotated element is skipped if any pod in [types] or [names]
///   exists, unless it is included in [ignoredTypes].
///
/// ### Example
///
/// ```dart
/// // Activate only if DataSource pod is missing
/// @ConditionalOnMissingPod(types: [ClassType<DataSource>()])
/// class EmbeddedDatabaseConfig {}
///
/// // Activate only if pod named 'myCustomService' is missing
/// @ConditionalOnMissingPod(names: ['myCustomService'])
/// class FallbackServiceConfig {}
///
/// // Ignore DataSource while checking for conflicts
/// @ConditionalOnMissingPod(
///   types: [ClassType<MyService>()],
///   ignoredTypes: [ClassType<DataSource>()],
/// )
/// class AlternativeServiceConfig {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext]: Evaluates pod absence and manages conditional initialization.
/// - [Conditional]: Base conditional annotation that [ConditionalOnMissingPod]
///   extends for declarative activation rules.
/// - [ClassType]: Represents pod types used in type-safe evaluation.
/// {@endtemplate}
@Conditional([OnPodCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnMissingPod extends WhenConditional {
  /// Pod types that must **not** be present in the [ConditionalContext].
  ///
  /// The annotated element is only processed if **all** of the specified
  /// types are missing.
  final List<ClassType<Object>> types;

  /// Pod names that must **not** be present in the [ConditionalContext].
  ///
  /// Provides a flexible alternative to [types] for dynamically registered
  /// pods. Activation occurs only if **all specified names** are absent.
  final List<String> names;

  /// Pod types to **ignore** during absence checks.
  ///
  /// Useful for excluding common infrastructure or support pods that should
  /// not block fallback registration. Any type in this list is disregarded
  /// when evaluating [types] conflicts.
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

/// {@template conditional_on_profile}
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class based on the currently active profiles in the
/// [ConditionalContext].
///
/// The [ConditionalOnProfile] annotation allows JetLeaf to selectively
/// include or exclude components depending on environment, runtime,
/// or deployment profiles. This is useful for differentiating
/// configuration between development, staging, production, or other
/// environment-specific contexts.
///
/// ### Purpose
///
/// In JetLeaf applications, different pods or components may only be
/// relevant under certain profiles. [ConditionalOnProfile] provides a
/// declarative way to ensure:
///
/// - Components are activated only for the intended environment(s).
/// - Profile-specific pods, services, or configurations do not interfere
///   with other environments.
/// - Conditional wiring and pod initialization are evaluated at runtime
///   in the current [ConditionalContext].
///
/// ### Behavior
///
/// - [value] is a list of profile names (strings) that determine when the
///   annotated component should be active.
/// - The component is registered only if the currently active profile(s)
///   in the [ConditionalContext] match any of the profiles specified in [value].
/// - Multiple profiles can be specified to allow activation under
///   multiple contexts.
///
/// ### Example
///
/// ```dart
/// @ConditionalOnProfile(['dev', 'local'])
/// class DevConfig {}
///
/// @ConditionalOnProfile(['prod'])
/// class ProductionConfig {}
/// ```
///
/// In this example, `DevConfig` will only be active if the pod context
/// has a profile of `'dev'` or `'local'`, while `ProductionConfig` is
/// active only in `'prod'`.
///
/// ### Related Components
///
/// - [ConditionalContext]: Evaluates the currently active profiles and determines
///   conditional registration.
/// - [Conditional]: The base conditional annotation that
///   [ConditionalOnProfile] extends to evaluate contextual activation.
/// {@endtemplate}
@Conditional([OnProfileCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnProfile extends WhenConditional {
  /// Profiles for which the annotated component should be registered.
  ///
  /// The annotated component is only activated if at least one of the
  /// specified profiles in [value] matches the currently active profiles
  /// in the [ConditionalContext].
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
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class based on the current Dart SDK version.
///
/// The [ConditionalOnDart] annotation allows JetLeaf to include or exclude
/// annotated elements depending on the Dart version present at runtime or
/// compile-time. This is particularly useful for maintaining compatibility
/// across multiple SDK versions, leveraging version-specific features, or
/// avoiding breaking changes.
///
/// ### Purpose
///
/// In JetLeaf applications, certain components or pods may only work with
/// specific Dart versions. [ConditionalOnDart] provides a declarative
/// mechanism to:
///
/// - Ensure compatibility with a target Dart SDK version or range.
/// - Conditionally register version-specific components.
/// - Prevent runtime errors or unsupported operations due to SDK mismatches.
///
/// ### Behavior
///
/// - [version] specifies the required Dart SDK version for the annotated
///   element. It can be a single version (e.g., `'3.1.0'`) or interpreted
///   by the [range] to match a broader version range.
/// - [range] is an optional [VersionRange] that defines minimum, maximum,
///   or compatible version intervals. Defaults to an unrestricted range.
/// - The element is processed only if the current Dart SDK version satisfies
///   the specified constraints.
///
/// ### Example
///
/// ```dart
/// // Activate only for Dart SDK >=3.1.0
/// @ConditionalOnDart('3.1.0', VersionRange(min: '3.1.0'))
/// class ModernFeatureConfig {}
///
/// // Activate for a specific version
/// @ConditionalOnDart('3.0.5')
/// class LegacyFeatureConfig {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext]: Evaluates version constraints and determines conditional
///   registration of pods or components.
/// - [VersionRange]: Represents version constraints for evaluation.
/// - [Conditional]: Base conditional annotation that [ConditionalOnDart]
///   extends for declarative activation.
/// {@endtemplate}
@Conditional([OnDartCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnDart extends WhenConditional {
  /// The Dart SDK version required for the annotated element to be processed.
  ///
  /// Can be a single version string (e.g., `'3.1.0'`) or interpreted by
  /// the [range] for broader version matching.
  final String version;

  /// Optional [VersionRange] used by JetLeaf to evaluate version constraints.
  ///
  /// Provides minimum, maximum, or compatible version intervals. Defaults
  /// to an unrestricted range if not specified.
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
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class based on the evaluation of a custom expression.
///
/// The [ConditionalOnExpression] annotation allows JetLeaf to determine
/// at runtime whether the annotated element should be processed by
/// evaluating the provided [expression]. This enables dynamic, context-aware
/// conditional activation beyond static type or property checks.
///
/// ### Purpose
///
/// In JetLeaf applications, some components require complex conditional
/// logic that cannot be expressed with simple presence checks, properties,
/// or profiles. [ConditionalOnExpression] provides a flexible mechanism to:
///
/// - Enable or disable components based on arbitrary runtime expressions.
/// - Support conditional wiring that depends on multiple factors.
/// - Allow developers to define custom activation rules using a single expression.
///
/// ### Behavior
///
/// - [expression] is evaluated during pod resolution to determine whether
///   the annotated element should be included.
/// - The expression can reference context values, environment variables,
///   or any data accessible through JetLeaf’s [ConditionalContext].
/// - If the expression evaluates to `true`, the annotated element is
///   processed; otherwise, it is skipped.
/// - This annotation is evaluated at runtime and allows maximum flexibility
///   for conditional activation.
///
/// ### Example
///
/// ```dart
/// // Activate if a custom condition evaluates to true
/// @ConditionalOnExpression('env["FEATURE_FLAG"] == true')
/// class ExperimentalFeatureConfig {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext]: Provides runtime values used in expression evaluation.
/// - [Conditional]: Base conditional annotation that [ConditionalOnExpression]
///   extends for declarative activation.
/// {@endtemplate}
@Conditional([OnExpressionCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnExpression extends WhenConditional {
  /// The expression to evaluate to determine if the annotated element
  /// should be processed.
  ///
  /// Can reference runtime context, environment variables, or other
  /// evaluatable data within the current [ConditionalContext]. The annotated
  /// element is only activated if the expression evaluates to `true`.
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
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class based on the presence of a specific asset in the
/// application's resources.
///
/// The [ConditionalOnAsset] annotation leverages [OnAssetCondition] to
/// evaluate whether the provided asset path exists. If the asset is present,
/// the annotated element is processed and registered within the JetLeaf
/// [ConditionalContext].
///
/// ### Purpose
///
/// In JetLeaf applications, certain components or pods may depend on
/// external resources such as configuration files, templates, or
/// static assets. [ConditionalOnAsset] allows developers to:
///
/// - Load pods only when required assets are available.
/// - Avoid runtime errors caused by missing resources.
/// - Implement conditional configuration and modular resource-based
///   activation.
///
/// ### Behavior
///
/// - [asset] is the relative or absolute path to the asset to check for
///   presence.
/// - The annotated element is processed only if the asset exists in the
///   application's resources as evaluated by [OnAssetCondition].
/// - Evaluation occurs at pod initialization time, ensuring early
///   conditional activation without manual checks.
///
/// ### Example
///
/// ```dart
/// // Loads AppConfigPod only if the configuration file exists
/// @ConditionalOnAsset('config/app_config.json')
/// class AppConfigPod {
///   // Initialization code that depends on 'config/app_config.json'
/// }
///
/// // Conditional pod based on multiple assets (if wrapped in a custom condition)
/// @ConditionalOnAsset('assets/logo.png')
/// class LogoPod {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext]: Provides the environment in which assets are evaluated
///   and pods are initialized.
/// - [OnAssetCondition]: Evaluates the presence of assets for conditional
///   activation.
/// - [Conditional]: Base conditional annotation that [ConditionalOnAsset]
///   extends for declarative activation logic.
/// {@endtemplate}
@Conditional([OnAssetCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnAsset extends WhenConditional {
  /// The asset path that must exist for the annotated element to be processed.
  ///
  /// This path can be relative to the project root or the assets directory
  /// and is evaluated at pod initialization time. The element is activated
  /// only if the asset exists.
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