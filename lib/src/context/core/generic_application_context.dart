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

import 'dart:async';

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta.dart';

import '../../annotation_aware_order_comparator.dart';
import '../application_context.dart';
import '../pod_registrar.dart';
import '../scanning/annotated_pod_name_generator.dart';
import 'abstract_application_context.dart';
import 'pod_spec.dart';

/// {@template generic_application_context}
/// Generic ApplicationContext implementation that holds a single internal
/// [DefaultListablePodFactory] instance and does not assume a specific pod
/// definition format.
///
/// This class implements the [ConfigurableApplicationContext] interface to allow
/// for convenient registration of pod definitions and classes as well as
/// programmatic registration of singletons. It serves as a flexible base
/// for various application context implementations in the JetLeaf framework.
///
/// ### Key Features:
/// - **Programmatic Registration**: Register pods and singletons via code
/// - **Flexible Configuration**: No assumptions about pod definition formats
/// - **Lifecycle Management**: Full context lifecycle support
/// - **Parent Context Support**: Hierarchical context relationships
/// - **Post-Processing**: Extensible processor architecture
///
/// ### Context Lifecycle:
/// 1. **Construction**: Context created with internal pod factory
/// 2. **Registration**: Pod definitions and singletons registered
/// 3. **Refresh**: Context initialized and pods instantiated
/// 4. **Operation**: Pods available for dependency injection
/// 5. **Destruction**: Context closed and resources cleaned up
///
/// ### Important Note:
/// The [setup] method **must be called exactly once** after all pod
/// definitions are registered and before any pod access attempts.
///
/// ### Usage Example:
/// ```dart
/// void main() async {
///   // Create context
///   final context = GenericApplicationContext();
/// 
///   // Register pod definitions programmatically
///   final podDef = RootPodDefinition(type: Class<UserService>());
///   context.registerDefinition('userService', podDef);
/// 
///   // Register singleton instances
///   context.getPodFactory().registerSingleton(
///     'configService', 
///     ConfigService()
///   );
/// 
///   // Refresh to initialize the context
///   await context.refresh();
/// 
///   // Use the context
///   final userService = context.getPod<UserService>('userService');
///   await userService.processUsers();
/// 
///   // Close context when done
///   await context.close();
/// }
/// ```
///
/// ### Advanced Configuration:
/// ```dart
/// // With custom pod factory
/// final customFactory = DefaultListablePodFactory();
/// customFactory.setAllowCircularReferences(true);
/// final context = GenericApplicationContext.withPodFactory(customFactory);
/// 
/// // With parent context for hierarchical lookup
/// final parentContext = GenericApplicationContext();
/// final childContext = GenericApplicationContext.withParent(parentContext);
/// ```
///
/// ### Framework Integration:
/// This context does not support special pod definition formats by default.
/// For contexts that read pod definitions from annotations, configuration
/// files, or other external sources, consider using specialized subclasses
/// like [AnnotationConfigApplicationContext].
///
/// See also:
/// - [AbstractApplicationContext] for the base implementation
/// - [ConfigurableApplicationContext] for the configuration interface
/// - [DefaultListablePodFactory] for the internal pod factory
/// - [AnnotationConfigApplicationContext] for annotation-based configuration
/// {@endtemplate}
abstract class GenericApplicationContext extends AbstractApplicationContext {
  /// {@template abstract_application_context.pod_factory_field}
  /// The pod factory associated with this application context.
  ///
  /// This is the core dependency injection container that manages
  /// pod definitions, instantiation, and dependency resolution.
  ///
  /// ### Responsibilities:
  /// - Pod definition registration and storage
  /// - Dependency injection and resolution
  /// - Singleton management and caching
  /// - Lifecycle coordination with context
  /// - Circular dependency detection and handling
  ///
  /// ### Access Pattern:
  /// Subclasses should access the pod factory through `getPodFactory()`
  /// rather than directly accessing this field to ensure proper
  /// lifecycle state checking.
  /// {@endtemplate}
  @protected
  late ConfigurableListablePodFactory podFactory;

  /// {@macro generic_application_context}
  ///
  /// Creates a new [GenericApplicationContext] with default settings.
  ///
  /// The context is created with a new [DefaultListablePodFactory] and
  /// no parent context. You must call [setup] after registering all
  /// pod definitions to initialize the context.
  ///
  /// ### Example:
  /// ```dart
  /// final context = GenericApplicationContext();
  /// // Register pods...
  /// await context.refresh();
  /// ```
  GenericApplicationContext() : this.all(null, null);

  /// {@template generic_application_context.with_configuration}
  /// Creates a new [GenericApplicationContext] with specified parent and pod factory.
  ///
  /// This constructor allows for advanced configuration scenarios where
  /// you need to specify both a parent context and a custom pod factory.
  ///
  /// ### Parameters:
  /// - [parent]: Optional parent application context for hierarchical lookup
  /// - [podFactory]: Optional custom pod factory instance
  ///
  /// ### Example:
  /// ```dart
  /// final parentContext = GenericApplicationContext();
  /// final customFactory = DefaultListablePodFactory();
  /// final context = GenericApplicationContext.all(parentContext, customFactory);
  /// ```
  /// {@endtemplate}
  GenericApplicationContext.all(ApplicationContext? parent, DefaultListablePodFactory? podFactory) {
    if(parent != null) {
      setParent(parent);
    }

    final localizedPodFactory = DefaultListablePodFactory();
    localizedPodFactory.setParentFactory(getParent()?.getPodFactory());
    localizedPodFactory.setDependencyComparator(AnnotationAwareOrderComparator());

    this.podFactory = podFactory ?? localizedPodFactory;
  }

  /// {@template generic_application_context.with_pod_factory}
  /// Creates a new [GenericApplicationContext] with the given pod factory.
  /// 
  /// Use this constructor when you need a custom configured pod factory
  /// with specific settings like circular reference handling or definition
  /// overriding.
  ///
  /// ### Parameters:
  /// - [podFactory]: The pod factory to use for this context
  /// - [parent]: Optional parent application context
  ///
  /// ### Example:
  /// ```dart
  /// final customFactory = DefaultListablePodFactory();
  /// customFactory.setAllowCircularReferences(true);
  /// customFactory.setAllowDefinitionOverriding(true);
  /// 
  /// final context = GenericApplicationContext.withPodFactory(customFactory);
  /// ```
  /// {@endtemplate}
  GenericApplicationContext.withPodFactory(DefaultListablePodFactory podFactory, [ApplicationContext? parent]) : this.all(parent, podFactory);

  /// {@template generic_application_context.with_parent}
  /// Creates a new [GenericApplicationContext] with the given parent context.
  /// 
  /// This constructor establishes a parent-child relationship between
  /// contexts, allowing the child context to delegate pod lookups to
  /// the parent when pods are not found locally.
  ///
  /// ### Parameters:
  /// - [parent]: The parent application context
  /// - [podFactory]: Optional custom pod factory instance
  ///
  /// ### Example:
  /// ```dart
  /// final parentContext = GenericApplicationContext();
  /// await parentContext.refresh();
  /// 
  /// final childContext = GenericApplicationContext.withParent(parentContext);
  /// // Child can access pods from parent context
  /// ```
  /// {@endtemplate}
  GenericApplicationContext.withParent(ApplicationContext parent, [DefaultListablePodFactory? podFactory]) : this.all(parent, podFactory);

  // ---------------------------------------------------------------------------------------------------------
  // OVERRIDDEN METHODS
  // ---------------------------------------------------------------------------------------------------------

  @override
  void setAllowCircularReferences(bool value) {
    podFactory.setAllowCircularReferences(value);
  }
  
  @override
  void setAllowDefinitionOverriding(bool value) {
    podFactory.setAllowDefinitionOverriding(value);
  }

  @override
  void setAllowRawInjection(bool value) {
    podFactory.setAllowRawInjection(value);
  }

  @override
  Future<void> refreshPodFactory() async {
    if (getIsSetupReady()) {
      return;
    }
    
    await super.refreshPodFactory();
  }

  @override
  void setParent(ApplicationContext parent) {
    super.setParent(parent);

    final pr = getParent();
    if (pr != null) {
      final pf = pr.getPodFactory();
      podFactory.setParentFactory(pf);
    }
  }

  @override
  void setApplicationStartup(ApplicationStartup applicationStartup) {
    super.setApplicationStartup(applicationStartup);
    podFactory.setApplicationStartup(applicationStartup);
  }

  @override
  ConfigurableListablePodFactory getPodFactory() {
    final pf = podFactory;

    if (pf is DefaultListablePodFactory && pf.getParentFactory() == null) {
      pf.setParentFactory(getParent()?.getPodFactory());
    }

    return pf;
  }

  @override
  Future<bool> isNameInUse(String name) async => await podFactory.isNameInUse(name);

  @override
  void registerAlias(String name, String alias) => podFactory.registerAlias(name, alias);

  @override
  bool isAlias(String name) => podFactory.isAlias(name);

  @override
  void removeAlias(String alias) => podFactory.removeAlias(alias);

  @override
  List<String> getAliases(String name) => podFactory.getAliases(name);

  @override
  String? getAlias(String name) => podFactory.getAlias(name);
  
  @override
  Future<void> registerDefinition(String name, PodDefinition pod) async => await podFactory.registerDefinition(name, pod);

  @override
  Future<void> removeDefinition(String name) async => await podFactory.removeDefinition(name);

  @override
  PodDefinition getDefinition(String name) => podFactory.getDefinition(name);

  @override
  PodDefinition getDefinitionByClass(Class type) => podFactory.getDefinitionByClass(type);

  @override
  int getNumberOfPodDefinitions() => podFactory.getNumberOfPodDefinitions();

  @override
  List<String> getDefinitionNames() => podFactory.getDefinitionNames();

  @override
  bool containsDefinition(String name) => podFactory.containsDefinition(name);

  @override
  Future<bool> containsLocalPod(String podName) async => await podFactory.containsLocalPod(podName);

  @override
  Future<bool> containsPod(String podName) async => await podFactory.containsPod(podName);

  @override
  Future<void> registerPod<T>(Class<T> podClass, {Consumer<Spec<T>>? customizer, String? name}) async {
    PodDefinition podDef = RootPodDefinition(type: podClass);
    String podName;

    if(name != null) {
      podDef.name = name;
      podDef.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
      registerDefinition(name, podDef);

      podName = name;
    } else if(customizer != null) {
      final customizerImpl = PodSpec<T>(PodSpecContext(podFactory));
      customizer(customizerImpl);

      podDef = customizerImpl.clone();
      
      if (podDef.name.isNotEmpty) {
        registerDefinition(podDef.name, podDef);
      } else {
        podName = AnnotatedPodNameGenerator().generate(podDef, podFactory);
        registerDefinition(podName, podDef);
      }
    } else {
      podDef.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
      podName = AnnotatedPodNameGenerator().generate(podDef, podFactory);
      registerDefinition(podName, podDef);
    }

    return Future.value();
  }

  @override
  void register(PodRegistrar registrar) {
    registrar.register(this, getEnvironment());
    final definition = RootPodDefinition(type: registrar.getClass());
    final name = AnnotatedPodNameGenerator().generate(definition, podFactory);
    definition.name = name;

    registerDefinition(name, definition);
  }

  @override
  Future<void> destroyPods() async {
    super.destroyPods();

    return Future.value();
  }

  @override
  Future<void> resetCommonCaches() async {
    super.resetCommonCaches();

    return Future.value();
  }
}