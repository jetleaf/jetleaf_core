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

import '../../annotation_aware_order_comparator.dart';
import '../application_context.dart';
import '../helpers.dart';
import '../pod_registrar.dart';
import '../scanning/annotated_pod_name_generator.dart';
import '../processors/default_aware_processor.dart';
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
/// The [refresh] method **must be called exactly once** after all pod
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
  /// {@template generic_application_context.pod_factory}
  /// A temporary pod factory used to register pod definitions before refresh.
  ///
  /// This factory is used during the configuration phase to accumulate
  /// pod definitions. During [refresh], its configuration is copied to
  /// the main operational pod factory.
  ///
  /// ### Lifecycle:
  /// - **Pre-Refresh**: Used for definition registration
  /// - **During Refresh**: Configuration copied to main factory
  /// - **Post-Refresh**: Main factory becomes operational
  /// {@endtemplate}
  late final ConfigurableListablePodFactory _podFactory;

  /// {@macro generic_application_context}
  ///
  /// Creates a new [GenericApplicationContext] with default settings.
  ///
  /// The context is created with a new [DefaultListablePodFactory] and
  /// no parent context. You must call [refresh] after registering all
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

    _podFactory = podFactory ?? DefaultListablePodFactory();
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
  ConfigurableListablePodFactory getPodFactory() {
    if (podFactory == null) {
      if (getIsRefreshed()) {
        throw IllegalStateException("Cannot access pod factory since it has not been initialized yet.");
      } else {
        return _podFactory;
      }
    }

    return podFactory!;
  }

  @override
  Future<ConfigurableListablePodFactory> doGetFreshPodFactory() async {
    if(podFactory != null) {
      clearSingletonCache();
      clearMetadataCache();
      destroySingletons();
      destroyPods();
      podFactory = null;
    }

    final factory = DefaultListablePodFactory();
    factory.copyConfigurationFrom(_podFactory);
    factory.setDependencyComparator(AnnotationAwareOrderComparator());

    return factory;
  }

  @override
  Future<void> registerPod<T>(Class<T> podClass, {Consumer<Spec<T>>? customizer, String? name}) async {
    if (podFactory != null) {
      PodDefinition podDef = RootPodDefinition(type: podClass);
      String podName;

      if(name != null) {
        podDef.name = name;
        podDef.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
        registerDefinition(name, podDef);

        podName = name;
      } else if(customizer != null) {
        final customizerImpl = PodSpec<T>(PodSpecContext(podFactory!));
        customizer(customizerImpl);

        podDef = customizerImpl.clone();
        
        if (podDef.name.isNotEmpty) {
          registerDefinition(podDef.name, podDef);
        } else {
          podName = AnnotatedPodNameGenerator().generate(podDef, podFactory!);
          registerDefinition(podName, podDef);
        }
      } else {
        podDef.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
        podName = AnnotatedPodNameGenerator().generate(podDef, podFactory!);
        registerDefinition(podName, podDef);
      }
    }

    return Future.value();
  }

  @override
  void register(PodRegistrar registrar) {
    registrar.register(this, getEnvironment());
  }

  @override
  Future<void> postProcessPodFactory() async {
    addPodAwareProcessor(DefaultAwareProcessor(this));

    return Future.value();
  }

  @override
  Future<void> invokePodFactoryPostProcessors() async {
    final pods = await getPodsOf(Class<PodFactoryPostProcessor>(null, PackageNames.CORE));

    getPodFactoryPostProcessors().addAll(pods.values);
    final processors = List<PodFactoryPostProcessor>.from(getPodFactoryPostProcessors()).toSet().toList();

    AnnotationAwareOrderComparator.sort(processors);

    for (final processor in processors) {
      await processor.postProcessFactory(this);
    }

    return Future.value();
  }

  @override
  Future<void> registerPodAwareProcessors() async {
    final pods = await getPodsOf(Class<PodAwareProcessor>(null, PackageNames.CORE));
    final processors = List<PodAwareProcessor>.from(pods.values).toSet().toList();
    processors.addAll(getPodAwareProcessors());

    AnnotationAwareOrderComparator.sort(processors);

    for (final processor in processors) {
      addPodAwareProcessor(processor);
    }

    return Future.value();
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