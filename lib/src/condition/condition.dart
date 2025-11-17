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

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

/// {@template conditional_context}
/// Represents the conditional evaluation context in **JetLeaf** applications.
///
/// A [ConditionalContext] provides all necessary runtime information to
/// determine whether a pod, component, or configuration should be activated
/// based on environment variables, runtime conditions, active profiles, or
/// the presence/absence of other pods.
///
/// This context is passed to condition evaluators such as [OnPropertyCondition],
/// [OnProfileCondition], [OnPodCondition], or custom conditional evaluators
/// to decide if annotated elements should be processed. It serves as the
/// central point of access for environment, pod lifecycle, and runtime
/// information required for conditional logic.
///
/// ### Purpose
///
/// - Enables declarative conditional activation of pods and components.
/// - Provides a unified interface for querying runtime and environment state.
/// - Supports modular and environment-specific configurations in JetLeaf
///   applications.
/// - Reduces boilerplate by centralizing access to [Environment],
///   [PodFactory], and [RuntimeProvider].
///
/// ### Behavior
///
/// - Maintains a list of unregistered [PodDefinition] instances that have been
///   discovered but not yet registered.
/// - Ensures thread-safe updates to pod definitions using [addDefinition].
/// - Provides immutable access to currently unregistered pods via
///   [getUnregisteredDefinitions].
/// - Works seamlessly with JetLeaf's conditional evaluation framework,
///   allowing multiple conditions to evaluate consistently using the same
///   context.
///
/// ### Example
///
/// ```dart
/// final context = ConditionalContext(environment, podFactory, runtimeProvider);
///
/// // Query active profiles
/// if (context.environment.activeProfiles.contains('production')) {
///   print('Running in production mode.');
/// }
///
/// // Add a new pod definition safely
/// context.addDefinition(PodDefinition('cacheManager'));
///
/// // Retrieve unregistered definitions
/// final pendingPods = context.getUnregisteredDefinitions();
/// for (var pod in pendingPods) {
///   print('Pending pod: ${pod.name}');
/// }
/// ```
///
/// ### Related Components
///
/// - [Environment]: Provides access to application properties, system settings,
///   and active profiles.
/// - [ConfigurableListablePodFactory]: Manages lifecycle of pods and allows
///   retrieval or configuration of pod instances.
/// - [RuntimeProvider]: Provides runtime-specific information required for
///   conditional evaluation.
/// - [PodDefinition]: Represents the metadata and configuration of a pod
///   before registration.
/// {@endtemplate}
class ConditionalContext {
  /// {@macro conditional_context_environment}
  ///
  /// Access application properties, system settings, and active profiles.
  /// Often used in condition evaluations to determine whether a pod should
  /// be activated.
  final Environment environment;

  /// {@macro conditional_context_podFactory}
  ///
  /// Manages the lifecycle of pods in the current context.
  /// Developers can programmatically retrieve or configure pods.
  final ConfigurableListablePodFactory podFactory;

  /// {@macro conditional_context_runtimeProvider}
  ///
  /// Provides access to runtime-specific information, which can influence
  /// conditional activation logic.
  final RuntimeProvider runtimeProvider;

  /// {@macro conditional_context}
  ConditionalContext(this.environment, this.podFactory, this.runtimeProvider);

  /// {@macro pod_factory_support.unregistered_definitions}
  ///
  /// Internally stores pod definitions discovered but not yet registered.
  final List<PodDefinition> _unregisteredDefinitions = [];

  /// {@macro pod_factory_support.add_definition}
  ///
  /// Adds a [PodDefinition] to the list of unregistered definitions.
  /// Thread-safe and ensures uniqueness by removing existing instances
  /// before re-adding.
  void addDefinition(PodDefinition definition) {
    return synchronized(_unregisteredDefinitions, () {
      _unregisteredDefinitions.remove(definition);
      _unregisteredDefinitions.add(definition);
    });
  }

  /// {@macro pod_factory_support.get_unregistered_definitions}
  ///
  /// Returns an immutable snapshot of unregistered [PodDefinition] instances.
  /// External modifications do not affect the internal state.
  List<PodDefinition> getUnregisteredDefinitions() => List<PodDefinition>.unmodifiable(_unregisteredDefinitions);
}

/// {@template condition}
/// The base interface for all **JetLeaf condition evaluators**.
///
/// A [Condition] defines a contract for determining whether a pod, component, 
/// or configuration element should be processed and included in the application 
/// context based on runtime metadata, environment properties, or other contextual 
/// information.
///
/// Implementations of [Condition] are used in combination with annotations 
/// such as [ConditionalOnProperty], [ConditionalOnClass], [ConditionalOnProfile], 
/// [ConditionalOnPod], and others. JetLeaf evaluates these conditions during 
/// pod registration or configuration scanning to control which elements are 
/// active in the current application context.
///
/// ### Responsibilities
///
/// - Evaluate runtime or static conditions against a given [ConditionalContext].
/// - Return `true` if the annotated element should be included, `false` otherwise.
/// - Integrate seamlessly with annotations for declarative conditional logic.
/// - Provide detailed trace logging (optional) to aid debugging of configuration 
///   evaluation flows.
///
/// ### Related Components
///
/// - [ConditionalContext]: Provides access to environment properties, 
///   active profiles, pod factory, and runtime information required for 
///   condition evaluation.
/// - [Annotation]: The metadata that is being conditionally evaluated.
/// - [Source]: The annotated element (class, method, or field) that the 
///   condition applies to.
/// - JetLeaf condition implementations such as [OnClassCondition], 
///   [OnPropertyCondition], [OnProfileCondition], [OnDartCondition], 
///   [OnPodCondition], [OnAssetCondition], and [OnExpressionCondition].
/// {@endtemplate}
abstract interface class Condition {
  /// {@macro condition}
  const Condition();

  /// {@template condition_matches}
  /// Evaluates the condition against the given [ConditionalContext] and 
  /// [annotation] for the specified [Source].
  ///
  /// - [context]: Provides access to the environment, active profiles, pod 
  ///   factory, and runtime state.
  /// - [annotation]: The annotation instance associated with the conditional 
  ///   evaluation (e.g., [ConditionalOnProperty], [ConditionalOnClass]).
  /// - [source]: Represents the annotated class, method, or other element being 
  ///   evaluated.
  ///
  /// Returns `true` if the condition matches and the annotated element should 
  /// be included in the application context; returns `false` if the element 
  /// should be skipped.
  ///
  /// ### Example
  ///
  /// ```dart
  /// class DatabaseEnabledCondition implements Condition {
  ///   @override
  ///   Future<bool> matches(
  ///       ConditionalContext context, 
  ///       Annotation annotation, 
  ///       Source source) async {
  ///     return context.environment.getProperty('db.enabled') == 'true';
  ///   }
  /// }
  /// ```
  ///
  /// In this example, the condition reads the environment property 
  /// `db.enabled` to decide whether the target class should be configured 
  /// and included in the application context.
  /// {@endtemplate}
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source);
}