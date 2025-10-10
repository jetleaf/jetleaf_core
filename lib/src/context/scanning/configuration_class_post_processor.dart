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
import '../../annotations/pod.dart';
import '../../aware.dart';
import '../../condition/condition_evaluator.dart';
import '../helpers.dart';
import 'annotated_pod_definition_reader.dart';
import 'annotated_pod_name_generator.dart';
import 'configuration_class.dart';
import 'configuration_class_parser.dart';

/// {@template configuration_class_post_processor}
/// Post-processor for Jetleaf configuration classes.
///
/// The `ConfigurationClassPostProcessor` is responsible for:
/// - Scanning pod factory definitions for configuration candidates
/// - Parsing `@Configuration` and `@AutoConfiguration` classes
/// - Registering pods from `@Pod` methods
/// - Handling imported configurations and component scans
/// - Enhancing pod definitions when proxy semantics are enabled
///
/// ### Usage
/// This class is used internally by Jetleaf during application bootstrap.
/// Developers typically don’t instantiate it manually. However, for testing
/// or advanced use cases, you can create and invoke it directly:
///
/// ```dart
/// void main() async {
/// final env = Environment();
/// final factory = DefaultPodFactory();
/// final postProcessor = ConfigurationClassPostProcessor(env);
///
/// await postProcessor.postProcessFactory(factory);
/// }
/// ```
/// {@endtemplate}
class ConfigurationClassPostProcessor implements PodFactoryPostProcessor, EntryApplicationAware, EnvironmentAware, PriorityOrdered {
  /// Set of configuration classes that have been processed
  final Set<ConfigurationClass> processedConfigurations = {};
  
  /// Set of pod definition names that have been processed
  final Set<String> processedPodNames = {};

  /// The environment to use for configuration parsing
  late final Environment _environment;

  /// The condition evaluator to use for configuration parsing
  late final ConditionEvaluator conditionEvaluator;

  /// The pod factory to use for configuration parsing
  late final ConfigurableListablePodFactory podFactory;

  /// The entry application class
  late final Class<Object> entryApplication;

  /// {@macro configuration_class_post_processor}
  ConfigurationClassPostProcessor();

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE;

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  @override
  void setEntryApplication(Class<Object> entryApplication) {
    this.entryApplication = entryApplication;
  }

  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    this.podFactory = podFactory;
    conditionEvaluator = ConditionEvaluator(_environment, podFactory, Runtime);
    final parser = ConfigurationClassParser(_environment, podFactory, conditionEvaluator, entryApplication);

    // Find configuration candidates
    final candidates = await _findConfigurationCandidates();
    
    if (candidates.isEmpty) {
      return;
    }
    
    // Parse configuration classes
    final configClasses = <ConfigurationClass>[];
    for (final candidate in candidates) {
      final configClass = await parser.parse(candidate);
      if (configClass != null && !processedConfigurations.contains(configClass)) {
        configClasses.add(configClass);
        processedConfigurations.add(configClass);
      }
    }
    
    if (configClasses.isEmpty) {
      return;
    }
    
    // Register pod definitions from parsed configurations
    await loadPodDefinitions(configClasses);

    // Clear processed state
    clearProcessedState();
  }

  /// Finds configuration candidates from registered pod definitions
  /// 
  /// This method iterates over all registered pod definitions and checks if they are configuration candidates.
  /// If a pod definition is a configuration candidate, it is added to the list of candidates.
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Returns
  /// A list of pod definitions that are configuration candidates.
  Future<List<PodDefinition>> _findConfigurationCandidates() async {
    final candidates = <PodDefinition>[];
    
    for (final podName in podFactory.getDefinitionNames()) {
      if (processedPodNames.contains(podName)) {
        continue;
      }
      
      final definition = podFactory.getDefinition(podName);
      
      // Check if this is a configuration candidate
      if (await _isConfigurationCandidate(definition)) {
        candidates.add(definition);
        processedPodNames.add(podName);
      }
    }
    
    return candidates;
  }

  /// Determines if a pod definition is a configuration candidate
  /// 
  /// This method checks if a pod definition is a configuration candidate by
  /// checking if it has the `@Configuration` or `@AutoConfiguration` annotation.
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Parameters
  /// - `definition`: The pod definition to check.
  /// 
  /// ### Returns
  /// A boolean indicating whether the pod definition is a configuration candidate.
  Future<bool> _isConfigurationCandidate(PodDefinition definition) async {
    final type = definition.type;
    
    // Check for @Configuration annotation
    if (definition.hasAnnotation<Configuration>()) {
      return await conditionEvaluator.shouldInclude(type);
    }
    
    // Check for @AutoConfiguration annotation
    if (definition.hasAnnotation<AutoConfiguration>()) {
      return await conditionEvaluator.shouldInclude(type);
    }
    
    return false;
  }

  /// {@template load_pod_definitions}
  /// Main method to load pod definitions from parsed configuration classes.
  /// 
  /// This method processes:
  /// 1. @Pod methods in each configuration class
  /// 2. Imported configuration classes recursively
  /// 3. Component scan results
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Parameters
  /// - `configClasses`: The list of configuration classes to process.
  /// 
  /// ### Returns
  /// A list of pod definitions that are configuration candidates.
  /// {@endtemplate}
  Future<void> loadPodDefinitions(List<ConfigurationClass> configClasses) async {
    for (final configClass in configClasses) {
      await _loadPodDefinitionsForConfigurationClass(configClass);
    }
  }

  /// Loads pod definitions for a single configuration class
  /// 
  /// This method processes:
  /// 1. @Pod methods in the configuration class
  /// 2. Imported configuration classes recursively
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Parameters
  /// - `configClass`: The configuration class to process.
  /// 
  /// ### Returns
  /// A list of pod definitions that are configuration candidates.
  Future<void> _loadPodDefinitionsForConfigurationClass(ConfigurationClass configClass) async {
    // Register the configuration class itself if not already registered
    await _registerConfigurationClass(configClass);

    if(configClass.importedConfigurations.isNotEmpty) {
      // Process imported configurations recursively
      for (final importedConfig in configClass.importedConfigurations) {
        await _loadPodDefinitionsForConfigurationClass(importedConfig);
      }
    }

    // Register @Pod methods
    await _loadPodDefinitionsFromPodMethods(configClass);
  }

  /// Registers the configuration class itself as a pod
  /// 
  /// This method registers the configuration class itself as a pod
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Parameters
  /// - `configClass`: The configuration class to process.
  /// 
  /// ### Returns
  /// A list of pod definitions that are configuration candidates.
  Future<void> _registerConfigurationClass(ConfigurationClass configClass) async {
    // Check if already registered
    if (podFactory.containsDefinition(configClass.podName)) {
      return;
    }
    
    final definition = RootPodDefinition(type: configClass.type);
    definition.name = configClass.podName;
    AnnotatedPodDefinitionReader.processCommonDefinitionAnnotations(definition);
    
    if(definition.description?.isEmpty ?? false) {
      definition.description = 'Configuration class ${configClass.type.getSimpleName()}';
    }
    
    await podFactory.registerDefinition(configClass.podName, definition);
  }

  /// Registers pod definitions from @Pod methods
  /// 
  /// This method registers pod definitions from @Pod methods
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Parameters
  /// - `configClass`: The configuration class to process.
  /// 
  /// ### Returns
  /// A list of pod definitions that are configuration candidates.
  Future<void> _loadPodDefinitionsFromPodMethods(ConfigurationClass configClass) async {
    for (final podMethod in configClass.podMethods) {
      await _registerPodMethod(podMethod);
    }
  }
  
  /// Registers a single @Pod method as a pod definition
  /// 
  /// This method registers a single @Pod method as a pod definition
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Parameters
  /// - `podMethod`: The @Pod method to register.
  /// 
  /// ### Returns
  /// A list of pod definitions that are configuration candidates.
  Future<void> _registerPodMethod(PodMethod podMethod) async {
    final definition = await _createPodDefinitionFromMethod(podMethod);
    
    // Check if pod name is already in use
    String finalPodName = definition.name;
    if (podFactory.containsDefinition(finalPodName)) {
      finalPodName = SimplePodNameGenerator().generate(definition, podFactory);
    }

    if (podFactory.containsDefinition(finalPodName)) {
      finalPodName = podMethod.method.getName();
    }
    
    definition.name = finalPodName;
    
    await podFactory.registerDefinition(finalPodName, definition);
  }

  /// Creates a pod definition from a @Pod method
  /// 
  /// This method creates a pod definition from a @Pod method
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Parameters
  /// - `podMethod`: The @Pod method to register.
  /// 
  /// ### Returns
  /// A list of pod definitions that are configuration candidates.
  Future<RootPodDefinition> _createPodDefinitionFromMethod(PodMethod podMethod) async {
    final method = podMethod.method;
    final configClass = podMethod.configurationClass;
    final definition = RootPodDefinition(type: method.getReturnClass());
    
    // Determine pod name
    String? podName;

    Pod? podAnnotation;
    if (method.hasDirectAnnotation<Pod>()) {
      podAnnotation = method.getDirectAnnotation<Pod>();
      if (podAnnotation!.value != null && podAnnotation.value!.isNotEmpty) {
        podName = podAnnotation.value!;
      }
    }
    podName ??= method.getName();

    if (podFactory.containsDefinition(podName)) {
      podName = AnnotatedPodNameGenerator().generate(definition, podFactory);
    }

    podAnnotation ??= Pod();
    definition.name = podName;

    // Determine pod description
    String description = 'Pod method ${podMethod.getMethodName()} in ${configClass.podName}';

    if (method.hasDirectAnnotation<Description>()) {
      final descriptionAnnotation = method.getDirectAnnotation<Description>();
      if(descriptionAnnotation != null) {
        description = descriptionAnnotation.value;
      }
    }
    definition.description = description;
    
    // Configure scope
    Scope? scope;
    if (method.hasDirectAnnotation<Scope>()) {
      scope = method.getDirectAnnotation<Scope>();
    }

    if (scope != null) {
      definition.scope = ScopeDesign.type(scope.value);
    } else {
      if (configClass.type.hasAnnotation<Scope>()) {
        scope ??= configClass.type.getAnnotation<Scope>();
      }

      definition.scope = configClass.scopeResolver.resolveScopeDescriptor(configClass.type);
    }
    
    // Configure design properties
    DesignRole? role;
    if (method.hasDirectAnnotation<Role>()) {
      role = method.getDirectAnnotation<Role>()?.value;
    }

    Primary? primary;
    if (method.hasDirectAnnotation<Primary>()) {
      primary = method.getDirectAnnotation<Primary>();
    }

    Order? order;
    if (method.hasDirectAnnotation<Order>()) {
      order = method.getDirectAnnotation<Order>();
    }
    
    definition.design = DesignDescriptor(
      role: role ?? DesignRole.APPLICATION,
      isPrimary: primary != null,
      order: order?.value ?? -1,
    );
    
    // Configure lifecycle
    Lazy? lazy;
    if (method.hasDirectAnnotation<Lazy>()) {
      lazy = method.getDirectAnnotation<Lazy>();
    }
    
    definition.lifecycle = LifecycleDesign(
      isLazy: lazy?.value,
      initMethods: podAnnotation.initMethods,
      destroyMethods: podAnnotation.destroyMethods,
      enforceInitMethod: podAnnotation.enforceInitMethods,
      enforceDestroyMethod: podAnnotation.enforceDestroyMethods,
    );

    // Configure autowire mode
    definition.autowireCandidate = AutowireCandidateDescriptor(
      autowireMode: podAnnotation.autowireMode,
      autowireCandidate: true,
    );
    
    // Set factory method information
    definition.factoryMethod = FactoryMethodDesign(configClass.podName, podMethod.getMethodName(), configClass.type);
    
    // Configure dependencies
    DependsOn? dependsOn;
    if (method.hasDirectAnnotation<DependsOn>()) {
      dependsOn = method.getDirectAnnotation<DependsOn>();
    }
    
    if (dependsOn != null) {
      definition.dependsOn = dependsOn.value.map((dep) => DependencyDesign(name: dep)).toList();
    }

    if (configClass.proxyPodMethods) {
      await _enhancePodDefinition(definition, configClass);
    }
    
    return definition;
  }

  /// Enhances a single pod definition with proxy semantics
  /// 
  /// This method enhances a single pod definition with proxy semantics
  /// 
  /// ### Usage
  /// This method is called internally by Jetleaf during application bootstrap.
  /// Developers typically don’t instantiate it manually. However, for testing
  /// or advanced use cases, you can create and invoke it directly:
  /// 
  /// ```dart
  /// void main() async {
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final postProcessor = ConfigurationClassPostProcessor(env);
  ///
  /// await postProcessor.postProcessFactory(factory);
  /// }
  /// ```
  /// 
  /// ### Parameters
  /// - `definition`: The pod definition to enhance.
  /// - `configClass`: The configuration class to process.
  /// 
  /// ### Returns
  /// A list of pod definitions that are configuration candidates.
  Future<void> _enhancePodDefinition(PodDefinition definition, ConfigurationClass configClass) async {
    // Mark @Pod methods as singleton if proxyPodMethods is true
    if (configClass.proxyPodMethods) {
      // Force singleton scope for proxy semantics
      definition.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
    }
  }
  
  /// Clears processed state (useful for testing or reprocessing)
  void clearProcessedState() {
    processedConfigurations.clear();
    processedPodNames.clear();
  }
}