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

import '../../annotations/configuration.dart';
import '../../annotations/others.dart';
import '../../aware.dart';
import '../condition/condition_evaluator.dart';
import '../../scope/annotated_scope_metadata_resolver.dart';
import 'annotated_pod_name_generator.dart';

/// {@template jetleaf_class_AnnotatedPodDefinitionReader}
/// A utility class in Jetleaf that reads class annotations and converts them
/// into [RootPodDefinition] instances, registering them with the
/// [ConfigurableListablePodFactory].
///
/// This reader is responsible for interpreting annotations such as:
/// - `@Scope` → defines Pod scope  
/// - `@Lazy` → marks Pod as lazily initialized  
/// - `@DependsOn` → declares Pod dependencies  
/// - `@Role` → assigns Pod a specific design role  
/// - `@Primary` → marks Pod as a primary candidate for autowiring  
/// - `@Description` → provides human-readable Pod description  
///
/// It also evaluates conditional annotations (`@Conditional`) to determine
/// whether a Pod should be included, based on environment or runtime context.
///
/// ### Example
/// ```dart
/// @Scope('singleton')
/// @Role(DesignRole.APPLICATION)
/// @Description('Provides a database connection')
/// class DatabaseService {}
///
/// final reader = AnnotatedPodDefinitionReader(podFactory, environment);
///
/// // Register annotated classes
/// await reader.register([DatabaseService]);
///
/// // DatabaseService is now available as a Pod definition
/// final db = podFactory.getPod<DatabaseService>();
/// ```
///
/// ### When to use
/// - When you want to **register annotated classes as Pods** in Jetleaf.  
/// - When your application relies on declarative metadata instead of manual Pod configuration.  
/// - When integrating custom annotations into the Pod lifecycle.  
///
/// This class is part of **Jetleaf** – a framework developers can use
/// to build web applications.
/// {@endtemplate}
final class AnnotatedPodDefinitionReader implements EnvironmentAware, PodFactoryAware {
  /// The Pod factory where annotated class definitions are registered.
  late final ConfigurableListablePodFactory _podFactory;

  /// Evaluates runtime conditions for annotated classes,
  /// such as environment-based inclusion or exclusion.
  late final Environment _environment;

  /// Creates a new reader bound to the given [_podFactory] and [environment].
  ///
  /// The [environment] is used to evaluate conditional annotations.
  AnnotatedPodDefinitionReader();

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  @override
  void setPodFactory(PodFactory podFactory) {
    if (podFactory is ConfigurableListablePodFactory) {
      _podFactory = podFactory;
    }
  }

  /// Registers a list of annotated classes as Pod definitions.
  ///
  /// Each class is passed to [doRegister] for processing and registration.
  ///
  /// ### Example
  /// ```dart
  /// await reader.register([MyService, DatabaseService]);
  /// ```
  Future<void> register(List<Class<Object>> classes) async {
    for (final cls in classes) {
      await doRegister(cls);
    }
  }

  /// Registers a single annotated class as a Pod definition.
  ///
  /// - If [name] is provided, it is used as the Pod name.  
  /// - Otherwise, a name is generated using [AnnotatedPodNameGenerator].  
  ///
  /// This method:
  /// 1. Creates a [RootPodDefinition] from the given class.  
  /// 2. Evaluates `@Conditional` annotations via [ConditionEvaluator].  
  /// 3. Resolves the Pod's scope from `@Scope` or defaults.  
  /// 4. Processes other common annotations (via [processCommonDefinitionAnnotations]).  
  /// 5. Registers the definition with the Pod factory.  
  ///
  /// ### Example
  /// ```dart
  /// await reader.doRegister(MyService, 'customPodName');
  /// ```
  Future<void> doRegister(Class<Object> cls, [String? name]) async {
    ConditionEvaluator conditionEvaluator = ConditionEvaluator(_environment, _podFactory);
    RootPodDefinition definition = RootPodDefinition(type: cls);

    // Evaluate @Conditional
    for (final cls in definition.annotatedClasses) {
      if (!await conditionEvaluator.shouldInclude(cls)) {
        return;
      }
    }

    // Resolve scope (@Scope)
    ScopeDesign scopeMetadata = AnnotatedScopeMetadataResolver().resolveScopeDescriptor(definition.type);
    definition.scope = scopeMetadata;

    // Generate pod name if none provided
    String podName = name ?? AnnotatedPodNameGenerator().generate(definition, _podFactory);
    definition.name = podName;

    // Process proxying capabilities (@Configuration, @AutoConfiguration)
    processProxyingCapabilities(definition);

    // Process common annotations
    processCommonDefinitionAnnotations(definition);

    // Register pod
    await _podFactory.registerDefinition(podName, definition);
  }

  /// Processes **proxying-related annotations** for a Pod.
  ///
  /// This method checks for `@Configuration` and `@AutoConfiguration`
  /// annotations to determine if the Pod's methods should be proxied.
  /// If either annotation is present, it sets the Pod definition's
  /// `canProxy` property accordingly.
  /// ### Example
  /// ```dart
  /// final def = RootPodDefinition(type: MyService);
  /// AnnotatedPodDefinitionReader.processProxyingCapabilities(def);
  /// ```
  static void processProxyingCapabilities(RootPodDefinition def) {
    if (def.hasAnnotation<Configuration>()) {
      def.canProxy = def.getAnnotation<Configuration>()?.proxyPodMethods ?? true;
    } else if (def.hasAnnotation<AutoConfiguration>()) {
      def.canProxy = def.getAnnotation<AutoConfiguration>()?.proxyPodMethods ?? true;
    }
  }

  /// Processes **common definition annotations** for a Pod.
  ///
  /// This method applies metadata to a [RootPodDefinition] by checking
  /// for the following annotations:
  ///
  /// - `@Lazy` → Marks the Pod as lazy-initialized.  
  /// - `@DependsOn` → Declares dependencies on other Pods.  
  /// - `@Scope` → Sets Pod scope (singleton, prototype, etc.).  
  /// - `@Role` → Assigns the Pod's design role (application, infrastructure).  
  /// - `@Primary` → Marks Pod as a primary candidate for injection.  
  /// - `@Description` → Provides a human-readable description.  
  ///
  /// ### Example
  /// ```dart
  /// final def = RootPodDefinition(type: MyService);
  /// AnnotatedPodDefinitionReader.processCommonDefinitionAnnotations(def);
  /// ```
  static void processCommonDefinitionAnnotations(RootPodDefinition def) {
    // @Lazy
    final lazy = def.getAnnotation<Lazy>();
    if (lazy != null) {
      def.lifecycle.isLazy = lazy.value;
    }

    // @DependsOn
    final dependsOn = def.getAnnotation<DependsOn>();
    if (dependsOn != null) {
      def.dependsOn = dependsOn.names.map((d) {
        if (d is String) {
          return DependencyDesign(name: d);
        } else if (d is ClassType) {
          return DependencyDesign(type: d.toClass());
        } else {
          throw IllegalArgumentException("DependsOn annotation received an object of [${d.runtimeType}] which is unsupported. Supported types are [String] or [ClassType]");
        }
      }).toList();
    }

    // @Scope
    final scope = def.getAnnotation<Scope>();
    if (scope != null) {
      def.scope = ScopeDesign.type(scope.value);
    }

    // @Role
    final role = def.getAnnotation<Role>();
    if (role != null) {
      def.design.role = role.value;
    }

    // @Primary
    if (def.hasAnnotation<Primary>()) {
      def.design.isPrimary = true;
    }

    // @Description
    final description = def.getAnnotation<Description>();
    if (description != null) {
      def.description = description.value;
    }

    // @Order
    final order = def.getAnnotation<Order>();
    if (order != null) {
      def.design.order = order.value;
    }
  }
}