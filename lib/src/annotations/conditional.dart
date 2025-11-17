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
/// configuration class **only if certain classes are absent** from the Dart
/// runtime or compilation environment.
///
/// The [ConditionalOnMissingClass] annotation allows JetLeaf to register
/// fallback or default components when specific types are **not** available.
/// This provides a declarative, dependency-safe mechanism for defining
/// alternative implementations without introducing tight coupling or
/// runtime checks.
///
/// ### Purpose
///
/// In modular JetLeaf applications, developers often provide optional
/// features or alternative configurations that should only load when a
/// preferred class or integration is unavailable.  
///
/// [ConditionalOnMissingClass] enables this pattern by allowing classes
/// to self-declare that they should only initialize if certain other
/// classes **do not exist**, ensuring safe default behavior and
/// graceful degradation.
///
/// ### Behavior
///
/// - [values] may include:
///   - A **Dart [Type]** (e.g., `AdvancedCache`)
///   - A **[ClassType]** wrapper (e.g., `ClassType<AdvancedCache>()`)
///   - A **qualified class name string**
///     (e.g., `'package:app/core/logger.dart.LoggingService'`)
///
/// - The annotated element is processed **only if all referenced classes
///   are missing**.
/// - If any specified class exists, the condition fails silently and the
///   annotated element is skipped.
///
/// ### Example
///
/// ```dart
/// // Load only if AdvancedCache class is NOT present
/// @ConditionalOnMissingClass([ClassType<AdvancedCache>()])
/// class DefaultCacheConfig {}
///
/// // Use a qualified name to avoid a direct dependency
/// @ConditionalOnMissingClass([
///   ClassType.qualified('package:jetleaf/example/jetleaf_example.dart.LoggingService')
/// ])
/// class FallbackLoggingConfig {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext] – Evaluates class and pod absence during
///   conditional initialization.
/// - [Conditional] – The base conditional framework that this annotation
///   extends.
/// - [ConditionalOnClass] – The inverse condition, which activates when
///   specified classes **are present**.
/// {@endtemplate}
@Conditional([OnClassCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnMissingClass extends WhenConditional {
  /// The list of class identifiers that must be **absent** for the
  /// annotated element to be processed.
  ///
  /// Each entry may represent a Dart [Type], a [ClassType] wrapper,
  /// or a fully qualified class name string. JetLeaf evaluates each entry
  /// to confirm its absence before activating the annotated component.
  final List<Object> values;

  /// {@macro conditional_on_missing_class}
  const ConditionalOnMissingClass([this.values = const []]);

  @override
  String toString() => 'ConditionalOnMissingClass($values)';

  @override
  Type get annotationType => ConditionalOnMissingClass;

  @override
  List<Object?> equalizedProperties() => values;
}

/// {@template conditional_on_class}
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class **only if specific classes are present** in the Dart
/// runtime or compilation environment.
///
/// The [ConditionalOnClass] annotation allows JetLeaf to selectively load
/// components based on the presence of other classes, enabling modular
/// configuration and safe integration with optional dependencies.
///
/// ### Purpose
///
/// In JetLeaf applications, some modules or configurations should only
/// initialize when certain external or framework classes are available.
/// This is especially useful for optional integrations, third-party
/// dependencies, or feature toggles controlled by class availability.
///
/// [ConditionalOnClass] provides a **declarative, type-safe mechanism**
/// for expressing such conditions without resorting to procedural runtime
/// checks or try-catch imports.
///
/// ### Behavior
///
/// - [values] may include:
///   - A **Dart [Type]** (e.g., `MyService`)
///   - A **[ClassType]** wrapper (e.g., `ClassType<MyService>()`)
///   - A **qualified class name string** (e.g.,
///     `'package:app/core/logger.dart.LoggingService'`)
///
/// - The annotated element is processed **only if all specified classes exist**.
/// - If any referenced class cannot be resolved, the condition fails silently,
///   and the annotated element is skipped.
///
/// ### Example
///
/// ```dart
/// // Activated only if AdvancedCache class is available
/// @ConditionalOnClass([ClassType<AdvancedCache>()])
/// class AdvancedCacheConfig {}
///
/// // Activated only if LoggingService class exists by qualified name
/// @ConditionalOnClass([
///   ClassType.qualified('package:jetleaf/example/jetleaf_example.dart.LoggingService')
/// ])
/// class LoggingConfig {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext] – Evaluates and manages class- and pod-based
///   conditional activation.
/// - [Conditional] – The core conditional annotation base class that this
///   extends.
/// - [ConditionalOnMissingClass] – The inverse condition, which activates
///   only when classes are **absent**.
///
/// {@endtemplate}
@Conditional([OnClassCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnClass extends WhenConditional {
  /// The list of class identifiers that must be **present** for activation.
  ///
  /// Each entry may be a [ClassType], a Dart [Type], or a fully qualified class
  /// name string. The annotated element will only be processed if **all**
  /// referenced classes can be successfully resolved.
  final List<Object> values;

  /// {@macro conditional_on_class}
  const ConditionalOnClass([this.values = const []]);

  @override
  String toString() => 'ConditionalOnClass($values)';

  @override
  Type get annotationType => ConditionalOnClass;

  @override
  List<Object?> equalizedProperties() => values;
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON POD
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_pod}
/// An annotation that conditionally activates a [Component], [Pod], or
/// configuration class **based on the presence** of other pods within the
/// current [ConditionalContext].
///
/// The [ConditionalOnPod] annotation enables declarative control over component
/// initialization in JetLeaf. It allows you to specify which pods must already
/// exist before the annotated construct can be loaded. This promotes modular,
/// dependency-aware configuration and prevents the unnecessary creation of
/// components whose prerequisites are unavailable.
///
/// ### Purpose
///
/// In modular JetLeaf applications, some components should only initialize when
/// certain dependencies (pods) are present. Instead of manually checking for
/// these dependencies at runtime, [ConditionalOnPod] provides a declarative and
/// type-safe mechanism to:
///
/// - Express dependencies on other pods (by name or type).
/// - Prevent activation when dependencies are missing.
/// - Support clean, composable configuration layers that activate dynamically
///   based on contextual availability.
///
/// ### Behavior
///
/// - [values] can include either **pod names** (`String`) or **types**
///   (`Type`, [ClassType], or fully qualified class names).
/// - During evaluation, JetLeaf checks whether *all* specified pods are
///   present in the [ConditionalContext].
/// - If any required pod is missing, the annotated element is skipped silently,
///   ensuring graceful degradation.
///
/// ### Example
///
/// ```dart
/// // Activate only if a DataSource pod is registered
/// @ConditionalOnPod([ClassType<DataSource>()])
/// class JdbcTemplateConfig {}
///
/// // Activate only if a pod named 'myCustomService' exists
/// @ConditionalOnPod(['myCustomService'])
/// class FallbackServiceConfig {}
///
/// // Activate only if both a type and name condition are satisfied
/// @ConditionalOnPod([ClassType<Cache>(), 'metricsService'])
/// class CachedMetricsConfig {}
/// ```
///
/// ### Related Components
///
/// - [ConditionalContext] — Evaluates pod availability and manages
///   conditional initialization.
/// - [Conditional] — The base conditional annotation that [ConditionalOnPod]
///   extends for contextual activation logic.
/// - [ClassType] — Represents type references for type-safe pod checks.
/// {@endtemplate}
@Conditional([OnPodCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnPod extends WhenConditional {
  /// Specifies pods that must be **present** in the [ConditionalContext]
  /// for the annotated component to activate.
  ///
  /// Each entry may be one of:
  /// - A **pod name** (`String`) — e.g., `'userService'`.
  /// - A **Dart [Type]** — e.g., `UserService`.
  /// - A **[ClassType]** — e.g., `ClassType<UserService>()`.
  /// - A **qualified class name string** — e.g.,
  ///   `'package:app/core/logger.dart.LoggingService'`.
  ///
  /// The JetLeaf runtime resolves each entry and evaluates whether the
  /// corresponding pod exists in the context.
  final List<Object> values;

  /// {@macro conditional_on_pod}
  const ConditionalOnPod([this.values = const []]);

  @override
  String toString() => 'ConditionalOnPod($values)';

  @override
  Type get annotationType => ConditionalOnPod;

  @override
  List<Object?> equalizedProperties() => [values];
}

// -------------------------------------------------------------------------------------------------------
// CONDITIONAL ON MISSING POD
// -------------------------------------------------------------------------------------------------------

/// {@template conditional_on_missing_pod}
/// An annotation that activates a component **only when specific pods are absent**
/// from the [ConditionalContext].
///
/// This enables fallback configuration or alternative service definitions
/// when certain pods are not registered.
///
/// Each pod may be referenced by **type**, **qualified name**, or **pod name**.
/// Additionally, the [ignoredTypes] list can be used to exclude certain pod
/// types from absence checks.
///
/// ### Example
/// ```dart
/// @ConditionalOnMissingPod(
///   values: [ClassType<Database>(), 'cacheService'],
///   ignoredTypes: [ClassType<Logger>()],
/// )
/// class FallbackConfig {}
/// ```
///
/// The above activates only if:
/// - Neither `Database` nor a pod named `cacheService` exist,
/// - And the `Logger` pod is ignored during evaluation.
///
/// ### Related:
/// - [ConditionalOnPod]
/// - [ConditionalContext]
/// {@endtemplate}
@Conditional([OnPodCondition()])
@Target({TargetKind.classType, TargetKind.method})
class ConditionalOnMissingPod extends WhenConditional {
  /// The main list of pod references that **must be absent**.
  ///
  /// Can include:
  /// - `String` pod names (e.g., `"cacheService"`)
  /// - `Type` objects (e.g., `CacheService`)
  /// - `ClassType` wrappers
  /// - Qualified class name strings
  final List<Object> values;

  /// A list of pod types to **ignore** during absence checks.
  ///
  /// Only class-like references are supported (i.e., `String` qualified names,
  /// `Type`, or `ClassType`).
  ///
  /// These are used to skip certain pods during evaluation, ensuring they don’t
  /// block fallback registration.
  final List<Object> ignoredTypes;

  /// {@macro conditional_on_missing_pod}
  const ConditionalOnMissingPod({this.values = const [], this.ignoredTypes = const []});

  /// Returns a list of all resolved [Class] objects represented in [values].
  ///
  /// Handles `ClassType`, `Type`, and qualified class `String`s.
  List<Class> getClasses() {
    final result = <Class>[];
    for (final item in values) {
      if (item is ClassType) {
        result.add(item.toClass());
      } else if (item is Type) {
        result.add(ClassUtils.getClass(item));
      } else if (item is String && ClassUtils.isClass(item)) {
        result.add(Class.fromQualifiedName(item));
      }
    }
    return result;
  }

  /// Returns a list of pod names (non-class string values) from [values].
  ///
  /// These are plain identifiers such as `"userService"` or `"cacheManager"`.
  ///
  /// Class-like strings (qualified names) are ignored.
  List<String> getPodNames() {
    final result = <String>[];
    for (final item in values) {
      if (item is String && !ClassUtils.isClass(item)) {
        result.add(item);
      }
    }
    return result;
  }

  /// Returns a list of ignored [Class] types derived from [ignoredTypes].
  ///
  /// This method mirrors [getClasses] but applies specifically to the
  /// [ignoredTypes] field.
  ///
  /// Supports `ClassType`, `Type`, and qualified name `String`s.
  List<Class> getIgnoredTypes() {
    final result = <Class>[];
    for (final item in ignoredTypes) {
      if (item is ClassType) {
        result.add(item.toClass());
      } else if (item is Type) {
        result.add(ClassUtils.getClass(item));
      } else if (item is String && ClassUtils.isClass(item)) {
        result.add(Class.fromQualifiedName(item));
      }
    }
    return result;
  }

  @override
  String toString() => 'ConditionalOnMissingPod(values: $values, ignoredTypes: $ignoredTypes)';

  @override
  Type get annotationType => ConditionalOnMissingPod;

  @override
  List<Object?> equalizedProperties() => [values, ignoredTypes];
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