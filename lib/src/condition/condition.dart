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
/// The `ConditionalContext` class in **Jetleaf** provides a unified 
/// context for working with conditional configuration in your applications.
///
/// It exposes core components required when writing logic that depends on 
/// environment settings, registered pod definitions, or direct interaction 
/// with the pod factory. This context ensures developers can implement 
/// complex conditional flows while keeping their code clean and consistent.
///
/// ### Core Properties:
/// - [registry] → Access and manage pod definitions.
/// - [environment] → Query environment profiles and properties.
/// - [podFactory] → Retrieve or configure pods programmatically.
///
/// ### Usage Example:
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// // A custom conditional configuration context.
/// class DatabaseConditionalContext extends ConditionalContext {
///   DatabaseConditionalContext(
///     Environment env,
///     ConfigurableListablePodFactory factory,
///   ) : super(env, factory);
///
///   void registerDatabasePodIfEnabled() {
///     if (environment.getProperty('db.enabled') == 'true') {
///       podFactory.registerPodDefinition(
///         'databasePod',
///         DatabasePod(),
///       );
///     }
///   }
/// }
///
/// void main() {
///   final context = DatabaseConditionalContext(
///     PodDefinitionRegistry(),
///     Environment(),
///     ConfigurableListablePodFactory(),
///   );
///
///   context.registerDatabasePodIfEnabled();
/// }
/// ```
///
/// In this example, `DatabaseConditionalContext` extends `ConditionalContext` 
/// and conditionally registers a database pod based on environment settings. 
/// Developers can build similar contexts for custom configuration logic.
/// {@endtemplate}
class ConditionalContext {
  /// {@template conditional_context_environment}
  /// The [Environment] for this context.
  ///
  /// Provides access to application properties, active profiles, and system 
  /// settings. Developers typically query this field to determine which pods 
  /// should be conditionally enabled or disabled.
  ///
  /// ### Example:
  /// ```dart
  /// if (environment.activeProfiles.contains('production')) {
  ///   print('Running in production mode.');
  /// }
  /// ```
  /// {@endtemplate}
  final Environment environment;

  /// {@template conditional_context_podFactory}
  /// The [ConfigurableListablePodFactory] associated with this context.
  ///
  /// It manages the lifecycle of pods and enables developers to retrieve or 
  /// configure pod instances programmatically, especially when applying 
  /// conditional logic during application startup.
  ///
  /// ### Example:
  /// ```dart
  /// final userService = podFactory.getPod<UserService>('userService');
  /// ```
  /// {@endtemplate}
  final ConfigurableListablePodFactory podFactory;

  /// {@template conditional_context_runtimeProvider}
  /// The [RuntimeProvider] associated with this context.
  ///
  /// It provides access to the runtime environment, making it a key entry 
  /// point for conditional runtime management.
  ///
  /// ### Example:
  /// ```dart
  /// final runtime = runtimeProvider.getRuntime();
  /// ```
  /// {@endtemplate}
  final RuntimeProvider runtimeProvider;

  /// {@macro conditional_context}
  const ConditionalContext(this.environment, this.podFactory, this.runtimeProvider);
}

/// {@template condition}
/// The `Condition` interface in **Jetleaf** defines a contract for writing 
/// conditional logic that determines whether certain pods, configurations, 
/// or classes should be applied in an application context.
///
/// Implementations of this interface are used by Jetleaf's conditional 
/// configuration system to evaluate runtime conditions (such as environment 
/// profiles, system properties, or custom logic) before deciding whether 
/// a pod or configuration should be activated.
///
/// ### Core Responsibility:
/// - Provide the [matches] method to evaluate a condition against the 
///   [ConditionalContext] and a target class type.
///
/// ### Usage Example:
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// // A custom condition that activates only in production profile.
/// class ProductionOnlyCondition implements Condition {
///   @override
///   Future<bool> matches(ConditionalContext context, Source source) async {
///     return context.environment.activeProfiles.contains('production');
///   }
/// }
///
/// // Example usage in configuration
/// @Configuration()
/// @Conditional(ProductionOnlyCondition)
/// class DatabaseConfig {
///   // This configuration will only be active in production mode.
/// }
/// ```
///
/// In this example, the `ProductionOnlyCondition` checks the active 
/// environment profiles from [ConditionalContext] and only matches 
/// when the application runs in production mode. Jetleaf uses this 
/// condition to decide whether to load `DatabaseConfig`.
/// {@endtemplate}
abstract interface class Condition {
  /// {@template condition_matches}
  /// Evaluates the condition against the given [ConditionalContext] and 
  /// [source].
  ///
  /// - [context] → Provides access to the pod registry, environment, 
  ///   and pod factory.  
  /// - [source] → The source that is being conditionally evaluated.
  ///
  /// Returns `true` if the condition matches and the source should be 
  /// included in the configuration; otherwise returns `false`.
  ///
  /// ### Example:
  /// ```dart
  /// class DatabaseEnabledCondition implements Condition {
  ///   @override
  ///   Future<bool> matches(ConditionalContext context, Source source) async {
  ///     return context.environment.getProperty('db.enabled') == 'true';
  ///   }
  /// }
  /// ```
  ///
  /// In this example, the condition evaluates an environment property 
  /// `db.enabled` to decide if the target class should be configured.
  /// {@endtemplate}
  Future<bool> matches(ConditionalContext context, Source source);
}