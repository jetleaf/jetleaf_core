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
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta.dart';

import '../../annotations/configuration.dart';
import '../../annotations/others.dart';
import '../../annotations/pod.dart';
import '../../annotations/stereotype.dart';
import '../../aware.dart';
import '../condition/condition_evaluator.dart';
import '../../scope/annotated_scope_metadata_resolver.dart';
import '../core/pod_spec.dart';
import '../base/helpers.dart';
import '../base/pod_registrar.dart';
import '../type_filters/annotation_type_filter.dart';
import '../type_filters/assignable_type_filter.dart';
import '../type_filters/regex_pattern_type_filter.dart';
import '../type_filters/type_filter.dart';
import 'annotated_pod_definition_reader.dart';
import 'annotated_pod_name_generator.dart';
import 'class_path_pod_definition_scanner.dart';
import 'component_scan_annotation_parser.dart';
import 'configuration_class.dart';
import 'configuration_class_builder.dart';

/// {@template configuration_class_post_processor}
/// Central post-processor responsible for assembling and registering
/// all configuration-derived pod definitions in the application context.
///
/// This class represents the **final orchestration phase** of JetLeaf’s
/// configuration bootstrap pipeline. It extends [AnnotatedPodMethodBuilder]
/// to inherit the ability to build `@Pod`-annotated factory methods into
/// runtime [PodDefinition] instances, while also implementing key framework
/// contracts for factory post-processing and environment awareness.
///
///
/// ### Core Responsibilities
///
/// 1. **Configuration Discovery**
///    - Scans all registered configuration classes annotated with `@Configuration`.
///    - Builds [ConfigurationClass] models and applies `@Import`, `@ComponentScan`,
///      and type filtering metadata.
///
/// 2. **Pod Method Assembly**
///    - Delegates to [buildPodMethods] (from [AnnotatedPodMethodBuilder])
///      to generate [PodDefinition]s from `@Pod` methods.
///    - Merges all discovered definitions, including locally registered ones.
///
/// 3. **Conditional Evaluation**
///    - Uses [ConditionEvaluator] to determine whether a given configuration
///      or pod should be included in the final context based on runtime
///      environment properties, profiles, or custom conditions.
///
/// 4. **Factory Registration**
///    - Registers validated and eligible pod definitions into the
///      [ConfigurableListablePodFactory].
///    - Applies deterministic ordering via [PackageOrderComparator].
///
///
/// ### Integration
/// This post-processor is automatically invoked during application startup
/// after environment preparation but before any pod instantiation.  
/// It ensures that **all configuration metadata is fully resolved** before
/// the context becomes operational.
///
///
/// ### Implements
/// - [PodFactoryPostProcessor] — allows modification of the pod factory
///   after its standard initialization.
/// - [EntryApplicationAware] — provides access to the entry application class.
/// - [EnvironmentAware] — injects the current runtime [Environment].
/// - [PodRegistry] — supports manual or programmatic pod registration.
/// - [PriorityOrdered] — controls execution precedence among post-processors.
///
///
/// ### Example
/// ```dart
/// void main() async {
///   final env = DefaultEnvironment();
///   final factory = DefaultPodFactory();
///   final processor = ConfigurationClassPostProcessor()
///     ..setEnvironment(env)
///     ..setEntryApplication(Class.forType(MyApplication));
///
///   await processor.postProcessFactory(factory);
/// }
/// ```
///
///
/// ### Logging
/// - **Trace logs**: detailed step-by-step information about discovered configurations,
///   skipped imports, and registration order.
/// - **Debug logs**: high-level lifecycle milestones and completion events.
/// {@endtemplate}
class ConfigurationClassPostProcessor extends AnnotatedPodMethodBuilder implements PodFactoryPostProcessor, EntryApplicationAware, EnvironmentAware, PodRegistry, PriorityOrdered {
  // ---------------------------------------------------------------------------
  // 🔧 Runtime Context
  // ---------------------------------------------------------------------------

  /// Environment instance used for configuration parsing and condition evaluation.
  ///
  /// Provides access to environment variables, active profiles, and property
  /// sources required for evaluating conditional inclusion logic in pods or
  /// configuration classes.
  late final Environment _environment;

  /// The main entry application class (annotated with `@Configuration` or similar).
  ///
  /// Used as a scanning root for classpath-based discovery and component scans.
  late final Class<Object> _entryApplication;

  /// Local cache of pod definitions collected during scanning and registration.
  ///
  /// Stores definitions that are discovered dynamically or registered via
  /// [registerPod] or [register], prior to being committed to the pod factory.
  final Map<String, PodDefinition> _localDefinitions = {};

  /// Central factory responsible for maintaining all registered pod definitions.
  ///
  /// Acts as the authoritative registry and lifecycle controller for all
  /// pods in the current application context.
  late final ConfigurableListablePodFactory _podFactory;
  
  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE;

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  @override
  void setEntryApplication(Class<Object> entryApplication) {
    _entryApplication = entryApplication;
  }

  @override
  Future<void> registerPod<T>(Class<T> podClass, {Consumer<Spec<T>>? customizer, String? name}) async {
    PodDefinition podDef = RootPodDefinition(type: podClass);
    String podName;

    if(name != null) {
      podDef.name = name;
      podDef.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
      _localDefinitions.add(name, podDef);

      podName = name;
    } else if(customizer != null) {
      final customizerImpl = PodSpec<T>(PodSpecContext(_podFactory));
      customizer(customizerImpl);

      podDef = customizerImpl.clone();
      
      if (podDef.name.isNotEmpty) {
        _localDefinitions.add(podDef.name, podDef);
      } else {
        podName = AnnotatedPodNameGenerator().generate(podDef, _podFactory);
        _localDefinitions.add(podName, podDef);
      }
    } else {
      podDef.scope = ScopeDesign.type(ScopeType.SINGLETON.name);
      podName = AnnotatedPodNameGenerator().generate(podDef, _podFactory);
      _localDefinitions.add(podName, podDef);
    }

    return Future.value();
  }

  @override
  Future<void> register(PodRegistrar registrar) async {
    registrar.register(this, _environment);

    final definition = RootPodDefinition(type: registrar.getClass());
    final name = AnnotatedPodNameGenerator().generate(definition, _podFactory);
    definition.name = name;

    _localDefinitions.add(name, definition);
  }

  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    if (logger.getIsDebugEnabled()) {
      logger.debug('🔧 $runtimeType starting postProcessFactory for podFactory ${podFactory.runtimeType}');
    }

    _podFactory = podFactory;

    // Step 1: Find configuration definitions
    final evaluator = ConditionEvaluator(_environment, podFactory);
    final definitions = await getConfigDefinitions(podFactory, evaluator);
    
    if (definitions.isEmpty) {
      if (logger.getIsTraceEnabled()) {
        logger.trace('⚠️ No configuration definitions found. Exiting post-process early.');
      }

      return;
    }

    if (logger.getIsTraceEnabled()) {
      logger.trace('🧩 Found ${definitions.length} configuration candidate(s).');
    }

    // Step 2: Build ConfigurationClass
    final builder = ConfigurationClassBuilder(podFactory);
    final configurationClasses = <ConfigurationClass>[];

    for (final candidate in definitions) {
      final configClass = await builder.build(candidate);
      if (configClass != null && _processedConfigurations.add(configClass.type.getQualifiedName())) {
        configurationClasses.add(configClass);
      }

      if (logger.getIsTraceEnabled()) {
        logger.trace('✅ Parsed initial configuration class: ${configClass?.type.getQualifiedName()}');
      }
    }

    // Step 3: Find all TypeFilters
    if (logger.getIsTraceEnabled()) {
      logger.trace('🔍 PHASE 1 START: Discovering all configuration classes and collecting TypeFilters...');
    }

    await discoverFilters(configurationClasses, evaluator);

    if (logger.getIsTraceEnabled()) {
      logger.trace('🏁 PHASE 1 COMPLETE: Discovered ${_processedConfigurations.length} configuration(s).');
    }

    final scanner = ClassPathPodDefinitionScanner(evaluator, podFactory, _entryApplication);
    final parser = ComponentScanAnnotationParser(scanner);

    // Scan for classes
    await recursivelyScanCandidates(configurationClasses, evaluator, builder, podFactory, parser);

    if (logger.getIsTraceEnabled()) {
      logger.trace('📋 Finished processing configuration queue. Total definitions: ${discoveredDefinitions.length}, total pod methods: ${discoveredPodMethods.length}.');
    }

    final finalizedDefinitions = <PodDefinition>{};
    final mappedPodMethods = await buildPodMethods(finalizedDefinitions, podFactory);

    // Merge remaining definitions
    for (final definition in discoveredDefinitions) {
      final notRegistered = definitions.none((def) => def.name.equals(definition.name) && def.type.getQualifiedName().equals(definition.type.getQualifiedName()));

      if (notRegistered && finalizedDefinitions.add(definition)) {
        if (logger.getIsTraceEnabled()) {
          logger.trace('🧱 Added standalone pod definition: ${definition.name} (${definition.type.getQualifiedName()})');
        }
      }
    }

    // Add the pending definitions to the condition evaluator for late
    for (final definition in finalizedDefinitions) {
      evaluator.addDefinition(definition);
    }

    // Complete pod registration
    await _completeRegistration(finalizedDefinitions, mappedPodMethods, evaluator);

    // Add any local pod definition for registration
    await _completeRegistration(_localDefinitions.values, {}, evaluator);

    if (logger.getIsTraceEnabled()) {
      logger.trace('🧹 Clearing processed configuration state.');
    }

    // Clear processed state
    _processedConfigurations.clear();
    _processedImports.clear();
    parser.scanner.clearScannedTracking();

    if (logger.getIsDebugEnabled()) {
      logger.debug('🏁 Completed post-processing for [$runtimeType].');
    }

    return Future.value();
  }

  /// Completes the registration of pod definitions in the pod factory.
  ///
  /// This method processes a list of [PodDefinition] instances, filters them
  /// according to disabled imports and conditional inclusion rules, and then
  /// registers the eligible definitions with the pod factory.
  ///
  /// ### Processing Steps
  /// 1. **Sorting Definitions**
  ///    - Definitions are sorted using [PackageOrderComparator] to ensure a
  ///      consistent registration order based on package and type priority.
  ///
  /// 2. **Filtering Disabled Imports**
  ///    - Any definition whose type matches a [disabledImportClasses] entry is skipped.
  ///    - A type may be matched either by its fully qualified name or its package name.
  ///    - If trace logging is enabled, skipped definitions are logged.
  ///
  /// 3. **Conditional Registration**
  ///    - For definitions that correspond to a mapped pod method in [mappedPodMethods]:
  ///      - The method is evaluated by [ConditionEvaluator.shouldInclude].
  ///      - If the condition passes, the definition is registered; otherwise, it is skipped.
  ///    - For definitions not associated with a mapped pod method:
  ///      - The type itself is evaluated by [ConditionEvaluator.shouldInclude].
  ///      - Eligible definitions are registered; failing ones are skipped.
  ///
  /// 4. **Registration**
  ///    - Successful registrations call [ConfigurableListablePodFactory.registerDefinition] with
  ///      the pod name and definition.
  ///    - Trace logs are generated for each registration or skipped pod.
  ///
  /// ### Parameters
  /// - [definitions]: The list of pod definitions to consider for registration.
  /// - [disabledImportClasses]: A list of imports that are explicitly disabled and should
  ///   be skipped during registration.
  /// - [mappedPodMethods]: A map of pod names to [PodMethod]s used for conditional
  ///   evaluation before registration.
  ///
  /// ### Notes
  /// - This method performs asynchronous registration of pods in the pod factory.
  /// - Trace-level logging provides detailed insight into which pods were registered
  ///   or skipped and why.
  /// - Definitions are evaluated in deterministic order to ensure consistent
  ///   registration behavior across application runs.
  ///
  /// ### Example
  /// ```dart
  /// await _completeRegistration(definitions, disabledImportClasses, mappedPodMethods);
  /// ```
  Future<void> _completeRegistration(Iterable<PodDefinition> definitions, Map<String, PodMethod> mappedPodMethods, ConditionEvaluator evaluator) async {
    final definitionToRegister = List<PodDefinition>.from(definitions);
    definitionToRegister.sort((def1, def2) => PackageOrderComparator().compare(def1.type, def2.type));

    for (final def in definitionToRegister) {
      if (logger.getIsTraceEnabled()) {
        logger.trace("Starting registration of the pod definition ${def.name} with type ${def.type}");
      }

      final decl = def.type;
      if (disabledImportClasses.any((i) => i.importedClass != null ? (decl == i.importedClass || decl.getQualifiedName() == i.importedClass!.getQualifiedName()) : (decl.getPackage().getName().equals(i.packageName)))) {
        if (logger.getIsTraceEnabled()) {
          logger.trace('🧱 Skipping disabled import of $decl');
        }

        continue;
      }

      if (mappedPodMethods[createPodKey(def)] case final source?) {
        if (await evaluator.shouldInclude(source.method) && await evaluator.shouldInclude(decl)) {
          if (logger.getIsTraceEnabled()) {
            logger.trace('✅ Registered pod from method: ${def.name}');
          }

          await _podFactory.registerDefinition(def.name, def);
        } else {
          if (logger.getIsTraceEnabled()) {
            logger.trace('🚫 Skipped pod (condition failed): ${def.name}');
          }
        }
      } else if (await evaluator.shouldInclude(decl)) {
        if (logger.getIsTraceEnabled()) {
          logger.trace('✅ Registered pod definition: ${def.name}');
        }

        await _podFactory.registerDefinition(def.name, def);

        final registrarClass = Class<PodRegistrar>(null, PackageNames.CORE);
        if (registrarClass.isAssignableFrom(decl)) {
          final instance = decl.getNoArgConstructor()?.newInstance();
          if (instance is PodRegistrar) {
            instance.register(this, _environment);
          }
        }
      } else {
        if (logger.getIsTraceEnabled()) {
          logger.trace('🚫 Skipped pod (condition failed): ${def.name}');
        }
      }
    }
  }
}

/// {@template annotated_pod_method_builder}
/// Abstract base class responsible for constructing and enhancing
/// [PodDefinition]s from `@Pod`-annotated methods discovered in
/// configuration classes.
///
/// This class completes the **final phase** of JetLeaf’s configuration
/// discovery pipeline — after all configuration classes and component
/// scans have been processed by [ConfigurationClassCandidateScanner].
///
/// It translates annotated methods into runtime-managed pod definitions,
/// resolving their names, scopes, lifecycle metadata, autowiring
/// capabilities, and dependency relationships.
///
///
/// ### Core Responsibilities
///
/// 1. **Pod Method Resolution**
///    - Iterates over all discovered [PodMethod]s collected during
///      configuration scanning.
///    - Filters out methods belonging to disabled imports.
///    - Creates fully qualified [RootPodDefinition] instances for
///      each valid pod factory method.
///
/// 2. **Definition Construction**
///    - Invokes [_createPodDefinitionFromMethod] to construct pod definitions.
///    - Handles async return types and generic inference failures gracefully.
///    - Ensures unique pod names within the factory.
///
/// 3. **Proxy Enhancement**
///    - Applies proxy semantics via [_enhancePodDefinition] when
///      `proxyPodMethods` is enabled on a configuration class.
///    - Enforces appropriate scoping for proxied pods (singleton/prototype).
///
/// 4. **Lifecycle, Scope, and Metadata Resolution**
///    - Resolves annotations such as:
///      - `@Scope`
///      - `@Lazy`
///      - `@DependsOn`
///      - `@Primary`
///      - `@Role`
///      - `@Order`
///      - `@Description`
///    - Constructs detailed `DesignDescriptor`, `LifecycleDesign`, and
///      `AutowireCandidateDescriptor` models for each pod.
///
///
/// ### Processing Workflow
///
/// | Phase | Responsibility | Method |
/// |-------|----------------|--------|
/// | 1 | Collect & filter `@Pod` methods | [buildPodMethods] |
/// | 2 | Create definitions from methods | [_createPodDefinitionFromMethod] |
/// | 3 | Apply proxying & enhancement | [_enhancePodDefinition] |
///
///
/// ### Example
/// ```dart
/// final builder = DefaultAnnotatedPodMethodBuilder();
/// final definitions = <PodDefinition>{};
/// final mappedPodMethods = <String, PodMethod>{};
///
/// await builder.buildPodMethods(definitions, factory);
///
/// // The `definitions` set now contains all @Pod-based pods.
/// ```
///
///
/// ### Integration Notes
/// - This class is typically invoked internally by the
///   [ConfigurationClassPostProcessor].
/// - It expects that all [PodMethod]s have already been discovered by
///   [ConfigurationClassCandidateScanner].
///
///
/// ### Logging
/// Emits detailed **trace-level logs** describing each build phase:
/// - Method resolution
/// - Name assignment
/// - Scope & lifecycle resolution
/// - Dependency wiring
/// - Proxy enhancement
///
/// {@endtemplate}
abstract class AnnotatedPodMethodBuilder extends ConfigurationClassCandidateScanner {
  /// Builds pod definitions from discovered [PodMethod] instances.
  ///
  /// This method iterates through each [PodMethod] previously gathered
  /// during configuration scanning, validates it, and converts it into
  /// a corresponding [PodDefinition].
  ///
  /// Each definition is then registered into the provided [definitions]
  /// collection and mapped to its originating [PodMethod].
  ///
  /// ### Workflow Summary
  /// 1. **Skip Disabled Imports**
  ///    - Any methods belonging to a configuration class marked as a
  ///      disabled import (see [disabledImportClasses]) are ignored.
  ///
  /// 2. **Definition Creation**
  ///    - Invokes [_createPodDefinitionFromMethod] to produce a
  ///      [RootPodDefinition].
  ///    - Skips methods returning `void` or `Future<void>`.
  ///
  /// 3. **Conflict Resolution**
  ///    - Ensures unique pod names within the [podFactory].
  ///
  /// 4. **Registration**
  ///    - Adds resulting definitions to the registry and trace-logs
  ///      the registration progress.
  ///
  /// ### Returns
  /// A `Map<String, PodMethod>` mapping pod names to their factory methods.
  @protected
  Future<Map<String, PodMethod>> buildPodMethods(Set<PodDefinition> definitions, ConfigurableListablePodFactory podFactory) async {
    final methods = <String, PodMethod>{};

    for (final podMethod in discoveredPodMethods) {
      final decl = podMethod.configurationClass.type;
      if (disabledImportClasses.any((i) => i.importedClass != null ? (decl == i.importedClass || decl.getQualifiedName() == i.importedClass!.getQualifiedName()) : (decl.getPackage().getName().equals(i.packageName)))) {
        if (logger.getIsTraceEnabled()) {
          logger.trace('🧱 Skipping disabled import of $decl');
        }

        continue;
      }

      if (podMethod.method.isFutureVoid()) {
        if (logger.getIsWarnEnabled()) {
          logger.warn('Registration of any void or Future<void> factory method is not possible. All pods must return an object');
        }
      }

      if (podMethod.method.isFutureDynamic()) {
        if (logger.getIsWarnEnabled()) {
          logger.warn('Registration of any void or Future<dynamic> factory method is not possible. All pods must return an object');
        }
      }

      if (podMethod.method.isDynamic()) {
        if (logger.getIsWarnEnabled()) {
          logger.warn('Registration of any void or dynamic factory method is not possible. All pods must return an object');
        }
      }

      if (podMethod.method.isVoid()) {
        if (logger.getIsWarnEnabled()) {
          logger.warn('Registration of any void or void factory method is not possible. All pods must return an object');
        }
      }
 
      final definition = await _createPodDefinitionFromMethod(podMethod, podFactory);

      if (definition == null) {
        if (logger.getIsDebugEnabled()) {
          logger.debug('Registration of ${podMethod.method.getSignature()} was not completed, possibly because it is async and the generic type was not completely resolved');
        }

        continue;
      }
    
      definitions.add(definition);
      methods[createPodKey(definition)] = podMethod;

      if (logger.getIsTraceEnabled()) {
        logger.trace('🔧 Created pod definition from method: ${definition.name} (${definition.type.getQualifiedName()})');
      }
    }

    return methods;
  }

  /// Creates a **stable, globally unique pod key** for the given [PodDefinition].
  ///
  /// This method generates a composite identifier that uniquely represents
  /// a pod within the JetLeaf container by combining:
  ///
  /// 1. The **factory type signature** (if available)
  /// 2. The **explicit pod name**
  ///
  /// The resulting key is used internally as:
  /// - A lookup key in pod registries and caches
  /// - A deduplication mechanism during pod discovery
  /// - A stable identifier across lifecycle phases (scan → resolve → instantiate)
  ///
  /// ---
  /// ## Key Structure
  ///
  /// The generated key has the following form:
  ///
  /// ```text
  /// <factory-type-signature>ºª<pod-name>
  /// ```
  ///
  /// ### Components
  /// - **Factory type signature**  
  ///   Obtained from `def.factoryMethod.factoryType?.getSignature()`.  
  ///   This captures the *declaring class and method signature* responsible
  ///   for producing the pod.
  ///
  /// - **Separator (`ºª`)**  
  ///   A deliberately uncommon delimiter chosen to:
  ///   - Avoid collisions with valid Dart identifiers
  ///   - Preserve reversibility if parsing is ever required
  ///
  /// - **Pod name**  
  ///   The logical name assigned to the pod, either explicitly or by convention.
  ///
  /// ---
  /// ## Why This Is Necessary
  ///
  /// JetLeaf allows multiple pods to:
  /// - Share the same name but originate from different factories
  /// - Be produced by the same factory method under different configurations
  ///
  /// A simple name-based key would be ambiguous. This composite key ensures:
  /// - Deterministic pod resolution
  /// - Safe coexistence of similarly named pods
  /// - Reliable caching and lifecycle tracking
  ///
  /// ---
  /// ## Example
  ///
  /// ```dart
  /// final key = createPodKey(def);
  ///
  /// print(key);
  /// // → "com.example.config.DatabaseConfig#createDataSource()ºªdataSource"
  /// ```
  ///
  /// ---
  /// ## Notes
  /// - If `factoryType` is `null`, the string `"null"` will appear in the key.
  ///   This is intentional and still produces a deterministic identifier.
  /// - This method is **pure** and side-effect free.
  /// - The exact delimiter is an internal contract and should not be relied
  ///   upon by user code.
  ///
  String createPodKey(PodDefinition def) => "${def.factoryMethod.factoryType?.getSignature()}ºª${def.name}";

  /// Creates a [RootPodDefinition] from a single `@Pod`-annotated method.
  ///
  /// This method inspects the provided [PodMethod] and its surrounding
  /// [ConfigurationClass] to determine all metadata necessary to construct
  /// a valid [PodDefinition].
  ///
  /// The resulting definition includes:
  /// - Fully resolved pod name
  /// - Scope, lifecycle, and design metadata
  /// - Autowire configuration
  /// - Factory method reference
  /// - Dependency descriptors (`@DependsOn`)
  ///
  /// ### Behavior
  /// - Detects naming from `@Pod`, `@Named`, or fallback method name.
  /// - Determines scope from `@Scope`, class-level annotations, or default.
  /// - Resolves lazy, primary, order, and role attributes.
  /// - Creates dependency relationships for `@DependsOn`.
  /// - Applies proxy enhancement if `proxyPodMethods` is enabled.
  ///
  /// Returns `null` for async methods whose return type cannot be inferred.
  Future<RootPodDefinition?> _createPodDefinitionFromMethod(PodMethod podMethod, ConfigurableListablePodFactory podFactory) async {
    final method = podMethod.method;
    final configClass = podMethod.configurationClass;
    final returnType = method.isAsync() ? method.componentType() : method.getReturnClass();

    if (returnType == null) {
      return null;
    }

    final definition = RootPodDefinition(type: returnType);

    if (logger.getIsTraceEnabled()) {
      logger.trace('⚙️ Creating RootPodDefinition from method: ${method.getName()} in ${configClass.type.getQualifiedName()}');
    }
    
    // Name Resolution ----------------------------------------------------------
    String? podName;

    Pod? podAnnotation;
    if (method.hasDirectAnnotation<Pod>()) {
      podAnnotation = method.getDirectAnnotation<Pod>();
      if (podAnnotation!.value != null && podAnnotation.value!.isNotEmpty) {
        podName = podAnnotation.value!;
      }
    }
    
    if (podName == null) {
      final methodName = method.getName();

      if (podFactory.containsDefinition(methodName)) {
        podName ??= "${configClass.podName}.${method.getName()}";
      } else {
        podName ??= methodName;
      }
    }

    final named = method.getDirectAnnotation<Named>();
    if (named != null) {
      podName = named.name;
    }

    podAnnotation ??= Pod();
    definition.name = podName;

    if (logger.getIsTraceEnabled()) {
      logger.trace('🧩 Assigned pod name: "$podName" (return type: ${definition.type.getQualifiedName()})');
    }

    // Description --------------------------------------------------------------
    String description = 'Pod method ${podMethod.getMethodName()} in ${configClass.podName}';

    if (method.hasDirectAnnotation<Description>()) {
      final descriptionAnnotation = method.getDirectAnnotation<Description>();
      if(descriptionAnnotation != null) {
        description = descriptionAnnotation.value;
      }
    }
    definition.description = description;

    if (logger.getIsTraceEnabled()) {
      logger.trace('📝 Pod description set to: "$description"');
    }
    
    // Scope --------------------------------------------------------------------
    Scope? scope;
    if (method.hasDirectAnnotation<Scope>()) {
      scope = method.getDirectAnnotation<Scope>();
    }

    if (scope != null) {
      definition.scope = ScopeDesign.type(scope.value);

      if (logger.getIsTraceEnabled()) {
        logger.trace('🔍 Found method-level @Scope: ${scope.value}');
      }
    } else {
      if (configClass.type.hasAnnotation<Scope>()) {
        scope ??= configClass.type.getAnnotation<Scope>();

        if (logger.getIsTraceEnabled()) {
          logger.trace('🔍 Using class-level @Scope: ${scope?.value}');
        }
      }

      definition.scope = configClass.scopeResolver.resolveScopeDescriptor(configClass.type);
      if (logger.getIsTraceEnabled()) {
        logger.trace('🧭 Resolved scope descriptor: ${definition.scope}');
      }
    }
    
    // Design -------------------------------------------------------------------
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

    if (logger.getIsTraceEnabled()) {
      logger.trace('🎨 DesignDescriptor(role=${definition.design.role}, isPrimary=${definition.design.isPrimary}, order=${definition.design.order})');
    }
    
    // Lifecycle ----------------------------------------------------------------
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

    if (logger.getIsTraceEnabled()) {
      logger.trace('🔁 LifecycleDesign(isLazy=${definition.lifecycle.isLazy}, initMethods=${definition.lifecycle.initMethods}, destroyMethods=${definition.lifecycle.destroyMethods})');
    }

    // Autowire -----------------------------------------------------------------
    definition.autowireCandidate = AutowireCandidateDescriptor(
      autowireMode: podAnnotation.autowireMode,
      autowireCandidate: true,
    );

    if (logger.getIsTraceEnabled()) {
      logger.trace('🔗 AutowireCandidateDescriptor(autowireMode=${definition.autowireCandidate.autowireMode})');
    }
    
    // Factory Method -----------------------------------------------------------
    definition.factoryMethod = FactoryMethodDesign(configClass.podName, podMethod.getMethodName(), configClass.type);

    if (logger.getIsTraceEnabled()) {
      logger.trace('🏭 FactoryMethodDesign(factoryPod=${configClass.podName}, method=${podMethod.getMethodName()})');
    }
    
    // Dependencies -------------------------------------------------------------
    DependsOn? dependsOn;
    if (method.hasDirectAnnotation<DependsOn>()) {
      dependsOn = method.getDirectAnnotation<DependsOn>();
    }
    
    if (dependsOn != null) {
      definition.dependsOn = dependsOn.names.map((dep) {
        if (dep is String) {
          return DependencyDesign(name: dep);
        } else if (dep is ClassType) {
          return DependencyDesign(type: dep.toClass());
        } else {
          throw IllegalArgumentException("DependsOn annotation received an object of [${dep.runtimeType}] which is unsupported. Supported types are [String] or [ClassType]");
        }
      }).toList();

      if (logger.getIsTraceEnabled()) {
        logger.trace('🧩 DependsOn: ${definition.dependsOn.map((d) => d.name).join(", ")}');
      }
    }

    // Proxy Enhancement --------------------------------------------------------
    if (configClass.proxyPodMethods) {
      if (logger.getIsTraceEnabled()) {
        logger.trace('🧬 ProxyPodMethods enabled — enhancing definition for ${definition.name}');
      }

      definition.canProxy = configClass.proxyPodMethods;

      await _enhancePodDefinition(definition, configClass);
    }

    if (logger.getIsTraceEnabled()) {
      logger.trace('✅ Finished creating RootPodDefinition for "${definition.name}" (${definition.type.getQualifiedName()})');
    }
    
    return definition;
  }

  /// Enhances the given [PodDefinition] for proxy compatibility.
  ///
  /// When `proxyPodMethods` is enabled on the associated [ConfigurationClass],
  /// this enhancement enforces **singleton scope** to ensure consistent
  /// proxy semantics across the container lifecycle.
  ///
  /// If proxying is disabled, the pod is instead configured with a
  /// **prototype scope**, preserving independence per request.
  ///
  /// ### Behavior
  /// - Logs detailed before/after state changes.
  /// - Updates the [ScopeDesign] on the provided [definition].
  /// - Does not modify other aspects of the pod definition.
  Future<void> _enhancePodDefinition(PodDefinition definition, ConfigurationClass configClass) async {
    if (logger.getIsTraceEnabled()) {
      logger.trace('🔧 Enhancing PodDefinition "${definition.name}" from configuration: ${configClass.type.getQualifiedName()}');
    }

    // Mark @Pod methods as singleton if proxyPodMethods is true or else, mark as prototype
    if (configClass.proxyPodMethods) {
      if (logger.getIsTraceEnabled()) {
        logger.trace('🧬 proxyPodMethods = true → forcing singleton scope for proxy compatibility');
        logger.trace('   Previous scope: ${definition.scope.type}');
      }

      // Force singleton scope for proxy semantics
      definition.scope = ScopeDesign.type(ScopeType.SINGLETON.name);

      if (logger.getIsTraceEnabled()) {
        logger.trace('   Updated scope: ${definition.scope.type}');
        logger.trace('✅ Enhancement complete for "${definition.name}"');
      }
    } else {
      if (logger.getIsTraceEnabled()) {
        logger.trace('ℹ️ proxyPodMethods = false → no enhancement applied to "${definition.name}"');
      }

      definition.scope = ScopeDesign.type(ScopeType.PROTOTYPE.name);

      if (logger.getIsTraceEnabled()) {
        logger.trace('   Updated scope: ${definition.scope.type}');
        logger.trace('✅ Enhancement complete for "${definition.name}"');
      }
    }
  }
}

/// {@template configuration_class_candidate_scanner}
/// Abstract base class providing recursive configuration discovery,
/// component scanning, and candidate registration logic for JetLeaf’s
/// configuration infrastructure.
///
/// This scanner is responsible for discovering, parsing, and registering
/// all **configuration classes**, **pods**, and **component definitions**
/// across the application classpath. It builds on
/// [AbstractTypeFilterSupport], inheriting advanced filtering,
/// import resolution, and conditional evaluation capabilities.
///
///
/// ### Core Responsibilities
/// 1. **Recursive Configuration Discovery**
///    - Processes initial and nested configuration classes.
///    - Detects and handles new configuration candidates found through
///      component scanning or `@Import` declarations.
///    - Supports multiple iterations of discovery until no new
///      candidates remain.
///
/// 2. **Component Scanning**
///    - Uses [ComponentScanAnnotationParser] to perform package scans
///      based on `@ComponentScan` metadata.
///    - Applies include/exclude filters inherited from previous discovery phases.
///    - Collects and registers discovered [PodDefinition]s.
///
/// 3. **Pod Method Detection**
///    - Identifies methods annotated with `@Pod` inside configuration classes.
///    - Wraps them as [PodMethod] objects for deferred instantiation and registration.
///
/// 4. **Import & Auto-Configuration Handling**
///    - Processes `@Import` annotations and nested configuration imports.
///    - Detects and builds [RootPodDefinition]s for auto-configurations.
///    - Supports `ImportSelector` extensions to dynamically provide imports.
///
///
/// ### Internal Lifecycle
/// 1. `recursivelyScanCandidates()` — orchestrates the full scanning lifecycle:
///    - Executes component scans and import resolution.
///    - Builds pod definitions and configuration candidates.
///    - Adds new candidates to the discovery queue until fully exhausted.
/// 2. `_processComponentScan()` — executes classpath scanning for
///    discovered `@ComponentScan` metadata.
/// 3. `_processPodMethods()` — extracts and registers all `@Pod`-annotated
///    methods within configuration classes.
/// 4. `_createPodDefinition()` — creates [RootPodDefinition] instances
///    for auto-configuration imports with resolved names and scopes.
///
///
/// ### Example
/// ```dart
/// final scanner = DefaultConfigurationClassScanner();
/// await scanner.recursivelyScanCandidates(
///   initialCandidates,
///   conditionEvaluator,
///   configurationBuilder,
///   podFactory,
///   componentScanParser,
/// );
///
/// final definitions = scanner.discoveredDefinitions;
/// final pods = scanner.discoveredPodMethods;
/// ```
///
///
/// ### Logging
/// The scanner emits detailed **trace-level logs** describing each phase of
/// the scanning lifecycle — including configuration discovery, import processing,
/// pod method analysis, and component scanning outcomes.
///
///
/// {@endtemplate}
abstract class ConfigurationClassCandidateScanner extends AbstractTypeFilterSupport {
  /// Tracks configuration class names that have already been processed.
  ///
  /// Prevents duplicate scanning of configurations that were already
  /// discovered through previous iterations or imports.
  @protected
  final Set<String> _processedConfigurations = {};

  /// Tracks class names that have already been added to [discoveredDefinitions].
  ///
  /// Prevents duplicate definitions that were already
  /// discovered through previous iterations or imports.
  @protected
  final Set<String> _processedClasses = {};

  /// Tracks class names that have already been added to [discoveredPodMethods].
  ///
  /// Prevents duplicate definitions that were already
  /// discovered through previous iterations or imports.
  @protected
  final Set<String> _processedPodMethods = {};

  /// Accumulates all discovered [PodDefinition]s across scanning iterations.
  ///
  /// Includes both direct component-scan results and auto-configuration
  /// class definitions.
  @protected
  final List<PodDefinition> discoveredDefinitions = [];

  /// Accumulates all `@Pod`-annotated methods discovered during scanning.
  ///
  /// These are stored as [PodMethod]s and later invoked by the
  /// configuration parser or pod instantiation subsystem.
  @protected
  final List<PodMethod> discoveredPodMethods = [];

  Future<void> addDefinition(PodDefinition definition, Class type) async {
    return synchronizedAsync(_processedClasses, () async {
      if (_processedClasses.add(type.getQualifiedName())) {
        discoveredDefinitions.add(definition);
        await _processPodMethods(ConfigurationClass(definition.name, type, definition));
      }
    });
  }

  /// Recursively scans configuration candidates for component definitions,
  /// nested configuration classes, and pod methods.
  ///
  /// This method forms the **heart** of JetLeaf’s configuration discovery phase.
  /// It performs iterative scanning until no further configuration classes
  /// are found, ensuring that the entire configuration graph is fully resolved.
  ///
  /// ### Parameters
  /// - `candidates` — The initial configuration class candidates to process.
  /// - `evaluator` — Used to conditionally include/exclude configurations.
  /// - `builder` — Responsible for constructing [ConfigurationClass] instances.
  /// - `podFactory` — The factory used to register new [PodDefinition]s.
  /// - `parser` — The component scanner responsible for parsing `@ComponentScan`.
  ///
  /// ### Behavior
  /// 1. Iteratively processes each configuration class.
  /// 2. Resolves imports and auto-configurations.
  /// 3. Performs component scans and pod method discovery.
  /// 4. Adds any newly found configuration candidates to the processing queue.
  ///
  /// Continues looping until the queue is empty.
  @protected
  Future<void> recursivelyScanCandidates(List<ConfigurationClass> candidates, ConditionEvaluator evaluator, ConfigurationClassBuilder builder, ConfigurableListablePodFactory podFactory, ComponentScanAnnotationParser parser) async {
    // Queue for configuration classes to process
    final queue = <ConfigurationClass>[...candidates];

    for (final configClass in importedConfigurations) {
      final definition = _createPodDefinition(configClass, podFactory);
      final cc = ConfigurationClass(definition.name, configClass, definition);

      if (logger.getIsTraceEnabled()) {
        logger.trace('🔍 Found auto-configuration candidate: ${configClass.getQualifiedName()}');
      }

      await addDefinition(definition, configClass);
      await _processPodMethods(cc);

      if (_processedConfigurations.add(cc.type.getQualifiedName())) {
        queue.add(cc);
      }
    }

    final parsed = await parser.parse(ComponentScanConfiguration(
      basePackages: unscannedPackages.filter((b) => _scannedPackages.add(b)).toList(),
      includeFilters: includeFilters, // Use accumulated filters
      excludeFilters: excludeFilters, // Use accumulated filters
    ));

    for (final parse in parsed) {
      await addDefinition(parse, parse.type);
      await _processPodMethods(ConfigurationClass(parse.name, parse.type, parse));
    }

    importedConfigurations.clear();
    unscannedPackages.clear();

    // Process queue iteratively until empty
    int iteration = 0;
    while (queue.isNotEmpty) {
      iteration++;

      if (logger.getIsTraceEnabled()) {
        logger.trace('🔁 Iteration $iteration — Processing ${queue.length} configuration class(es).');
      }

      final localDefinitions = <PodDefinition>[];
      final current = queue.removeLast();

      if (logger.getIsTraceEnabled()) {
        logger.trace('⚙️ Processing configuration: ${current.type.getQualifiedName()}');
      }

      // Process imports, scans, and pods
      await processImports(current, evaluator);

      await _processComponentScan(current, localDefinitions, parser);
      await _processPodMethods(current);

      if (logger.getIsTraceEnabled()) {
        logger.trace('📦 Processed ${localDefinitions.length} local pod definition(s).');
      }

      final parsed = await parser.parse(ComponentScanConfiguration(
        basePackages: unscannedPackages.filter((b) => _scannedPackages.add(b)).toList(),
        includeFilters: includeFilters, // Use accumulated filters
        excludeFilters: excludeFilters, // Use accumulated filters
      ));
      localDefinitions.addAll(parsed);

      // Step 3: Check for new configuration candidates
      final newCandidates = <ConfigurationClass>[];
      for (final def in localDefinitions) {
        if (await isConfigurationCandidate(def, evaluator)) {
          if (logger.getIsTraceEnabled()) {
            logger.trace('🔎 Found nested configuration candidate: ${def.type.getQualifiedName()}');
          }

          final nestedConfig = await builder.build(def);
          if (nestedConfig != null && _processedConfigurations.add(nestedConfig.type.getQualifiedName())) {
            newCandidates.add(nestedConfig);
            await _processPodMethods(nestedConfig);
          }
        }
      }

      // Step 4: Process any auto-configurations
      for (final configClass in importedConfigurations) {
        final definition = _createPodDefinition(configClass, podFactory);
        final cc = ConfigurationClass(definition.name, configClass, definition);

        if (logger.getIsTraceEnabled()) {
          logger.trace('🔍 Found auto-configuration candidate: ${configClass.getQualifiedName()}');
        }

        localDefinitions.add(definition);

        if (_processedConfigurations.add(cc.type.getQualifiedName())) {
          newCandidates.add(cc);
          await _processPodMethods(cc);
        }
      }

      if (logger.getIsTraceEnabled() && newCandidates.isNotEmpty) {
        logger.trace('🧭 Added ${newCandidates.length} new configuration class(es) to queue.');
      }

      // Add discovered configs to queue for next iteration
      queue.addAll(newCandidates);
      await addDefinition(current.definition, current.type);

      for (final local in localDefinitions) {
        await addDefinition(local, local.type);
      }
      
      importedConfigurations.clear();
      unscannedPackages.clear();
    }
  }

  /// Creates a [RootPodDefinition] for a given configuration class.
  ///
  /// Responsible for assigning the pod name, scope, and annotation
  /// metadata, effectively registering the configuration as a
  /// root-level definition within the [PodFactory].
  ///
  /// Steps performed:
  /// 1. **Name Resolution** → Uses [AnnotatedPodNameGenerator].
  /// 2. **Scope Resolution** → Uses [AnnotatedScopeMetadataResolver].
  /// 3. **Proxy Capability Analysis** → Processes `@Configuration` or
  ///    `@AutoConfiguration` proxying behavior.
  /// 4. **Common Annotation Processing** → Applies standard JetLeaf
  ///    metadata (e.g., `@Primary`, `@Lazy`).
  RootPodDefinition _createPodDefinition(Class type, ConfigurableListablePodFactory podFactory) {
    final definition = RootPodDefinition(type: type);

    // Name generation
    final nameGenerator = AnnotatedPodNameGenerator();
    definition.name = nameGenerator.generate(definition, podFactory);
    if (logger.getIsTraceEnabled()) {
      logger.trace('🧩 Assigned pod name "${definition.name}" to ${type.getQualifiedName()}');
    }

    // Scope resolution
    final resolver = AnnotatedScopeMetadataResolver();
    definition.scope = resolver.resolveScopeDescriptor(definition.type);
    if (logger.getIsTraceEnabled()) {
      logger.trace('🏷️ Resolved scope "${definition.scope.type}" for ${definition.name}');
    }

    // Process proxying capabilities (@Configuration, @AutoConfiguration)
    AnnotatedPodDefinitionReader.processProxyingCapabilities(definition);

    // Common annotations
    AnnotatedPodDefinitionReader.processCommonDefinitionAnnotations(definition);
    if (logger.getIsTraceEnabled()) {
      logger.trace('🪶 Processed common annotations for ${definition.name}');
    }

    return definition;
  }

  /// Processes all [`@ComponentScan`] annotations present on the given configuration class.
  ///
  /// Each declared base package and base package class is resolved, and
  /// the [ComponentScanAnnotationParser] is used to perform discovery
  /// using the current include/exclude filters.
  ///
  /// This method operates incrementally, combining discovered results
  /// into the provided [definitions] list.
  Future<void> _processComponentScan(ConfigurationClass configClass, List<PodDefinition> definitions, ComponentScanAnnotationParser parser) async {
    final componentScans = configClass.definition.getAnnotations<ComponentScan>();

    if (logger.getIsTraceEnabled()) {
      logger.trace('ℹ️ No @ComponentScan annotations in ${configClass.type.getQualifiedName()}');
    }
    
    for (final componentScan in componentScans) {
      List<String> basePackages = List<String>.from(componentScan.basePackages);
      List<Class> basePackageClasses = List<Class>.from(componentScan.basePackageClasses.map((c) => c.toClass()));

      final basePackage = configClass.type.getPackage().getName();
      basePackages.add(basePackage);

      if (logger.getIsTraceEnabled()) {
        logger.trace('🔎 Performing component scan in ${basePackages.length} package(s) for ${configClass.type.getQualifiedName()}');
      }

      // Use pre-collected filters from PHASE 1
      // _includeFilters.addAll(_createTypeFilters(componentScan.includeFilters));
      // _excludeFilters.addAll(_createTypeFilters(componentScan.excludeFilters));
      
      final scanConfig = ComponentScanConfiguration(
        basePackages: basePackages.filter((b) => _scannedPackages.add(b)).toList(),
        basePackageClasses: basePackageClasses.filter((b) => _scannedClasses.add(b)).toList(),
        includeFilters: includeFilters, // Use accumulated filters
        excludeFilters: excludeFilters, // Use accumulated filters
        useDefaultFilters: componentScan.useDefaultFilters,
        scopeResolver: componentScan.scopeResolver,
        nameGenerator: componentScan.nameGenerator,
      );
      
      final parsed = await parser.parse(scanConfig);
      definitions.addAll(parsed);

      if (logger.getIsTraceEnabled()) {
        logger.trace('✅ Component scan completed for ${configClass.type.getQualifiedName()} — Found ${parsed.length} definitions.');
      }
    }
  }

  /// Scans the provided configuration class for `@Pod`-annotated methods.
  ///
  /// Each discovered method is converted into a [PodMethod] and stored
  /// in [discoveredPodMethods] for later invocation during the
  /// configuration initialization phase.
  Future<void> _processPodMethods(ConfigurationClass configClass) async {
    if (!_processedPodMethods.add(configClass.type.getQualifiedName())) {
      return;
    }

    final methods = configClass.type.getMethods();

    if (logger.getIsTraceEnabled()) {
      logger.trace('⚙️ Scanning pod methods for ${configClass.type.getQualifiedName()}');
    }
    
    int count = 0;
    for (final method in methods) {
      if (method.hasDirectAnnotation<Pod>()) {
        count++;
        discoveredPodMethods.add(PodMethod(configurationClass: configClass, method: method));

        if (logger.getIsTraceEnabled()) {
          logger.trace('🧩 Found @Pod method: ${method.getName()}');
        }
      }
    }

    if (logger.getIsTraceEnabled()) {
      logger.trace('✅ Completed pod method scan for ${configClass.type.getQualifiedName()}. Found $count methods.');
    }
  }
}

/// {@template filtering_support}
/// Abstract support class providing advanced **component-scanning**,
/// **filter resolution**, and **import processing** capabilities for
/// JetLeaf configuration discovery.
///
/// This class extends [AbstractConfigurationClassDefinitionSupport] and serves
/// as a reusable infrastructure layer for processors that need to:
///
/// - Handle `@ComponentScan` filters (`includeFilters`, `excludeFilters`)
/// - Detect and manage imported configuration classes (`@Import`)
/// - Manage scanned packages and prevent redundant scanning
/// - Cooperate with conditional configuration inclusion via [ConditionEvaluator]
///
///
/// ### Core Responsibilities
/// 1. **Filter Discovery**
///    - Scans configuration classes for [`@ComponentScan`] annotations.
///    - Extracts and builds include/exclude [TypeFilter] sets.
///    - Supports filter types: annotation-based, assignable, regex, and custom.
///
/// 2. **Import Resolution**
///    - Parses [`@Import`] annotations in configuration classes.
///    - Handles nested imports and avoids circular dependencies.
///    - Supports dynamic imports via [`ImportSelector`] implementations.
///    - Records imported configuration classes and disabled imports.
///
/// 3. **Cycle & Duplication Prevention**
///    - Tracks scanned packages and classes using multiple deduplication
///      collections (`_scannedPackages`, `_scannedClasses`,
///      `_scannedClassQualifiedNames`).
///    - Maintains an `_importStack` to detect import recursion.
///    - Skips previously processed imports and already scanned classes.
///
/// 4. **Integration Hooks**
///    - Designed to be extended by JetLeaf infrastructure classes that perform
///      scanning, parsing, or registration of configuration classes during
///      the **bootstrap phase**.
///
///
/// ### Example
/// ```dart
/// class ConfigurationClassParser extends AbstractTypeFilterSupport {
///   Future<void> parseConfigurations(List<ConfigurationClass> configs) async {
///     final evaluator = ConditionEvaluator();
///     await discoverFilters(configs, evaluator);
///     // Continue scanning using include/exclude filters...
///   }
/// }
/// ```
///
///
/// ### Lifecycle
/// - `discoverFilters()` → extracts filters and triggers import processing.
/// - `processImports()` → resolves and registers configuration imports.
/// - `_createTypeFilters()` → materializes include/exclude filters.
/// - Downstream processors use collected filters for selective scanning.
///
///
/// ### Logging
/// All major operations emit trace-level logs for deep introspection during
/// framework debugging. The logs describe the scanning lifecycle, imports,
/// and discovered filters in real-time.
///
///
/// {@endtemplate}
abstract class AbstractTypeFilterSupport extends ConfigurationClassDefinitionSupport {
  /// Tracks packages already scanned to prevent redundant discovery.
  final Set<String> _scannedPackages = {};

  /// Tracks configuration classes that have already been scanned.
  final Set<Class> _scannedClasses = {};

  /// Tracks qualified names of scanned classes as a fallback in case
  /// `_scannedClasses` does not detect equality (e.g., due to proxying).
  final Set<String> _scannedClassQualifiedNames = {};

  /// Stack of configuration classes currently being processed through imports.
  ///
  /// Used to detect and avoid circular `@Import` references.
  final List<Class> _importStack = [];

  /// Tracks fully processed imports to avoid re-evaluation.
  @protected
  final Set<String> _processedImports = {};

  /// Collection of explicitly **disabled import classes** discovered
  /// during import processing.
  @protected
  final List<ImportClass> disabledImportClasses = [];

  /// List of successfully imported configuration classes.
  ///
  /// Includes both direct and selector-based imports.
  @protected
  final List<Class<dynamic>> importedConfigurations = [];

  /// Aggregated include filters collected across all configuration sources.
  @protected
  final List<TypeFilter> includeFilters = [];

  /// Aggregated exclude filters collected across all configuration sources.
  @protected
  final List<TypeFilter> excludeFilters = [];

  /// Set of packages that are discovered but not yet scanned.
  ///
  /// Enables deferred scanning or later-stage processing.
  @protected
  final Set<String> unscannedPackages = {};

  /// Discovers include/exclude filters from all [ConfigurationClass] candidates.
  ///
  /// Performs a recursive traversal through configuration hierarchies and
  /// imported configurations to extract component scan metadata.
  ///
  /// - Extracts `@ComponentScan` annotations and merges discovered filters.
  /// - Invokes [processImports] for handling `@Import` annotations.
  /// - Populates [includeFilters], [excludeFilters], and [importedConfigurations].
  ///
  /// This is the **entry point** for filter resolution during configuration parsing.
  @protected
  Future<void> discoverFilters(List<ConfigurationClass> candidates, ConditionEvaluator evaluator) async {
    final queue = <ConfigurationClass>[...candidates];

    // Iteratively discover all nested configurations and extract filters
    var iteration = 0;
    while (queue.isNotEmpty) {
      iteration++;

      if (logger.getIsTraceEnabled()) {
        logger.trace('🔁 PHASE 1 Iteration $iteration — Processing ${queue.length} configuration class(es).');
      }

      final current = queue.removeLast();
      final configClass = current.type;

      if (logger.getIsTraceEnabled()) {
        logger.trace('⚙️ Extracting filters from: ${configClass.getQualifiedName()}');
      }

      final componentScans = current.definition.getAnnotations<ComponentScan>();
      _extractComponentScanFilters(componentScans, configClass);
      await processImports(current, evaluator);
    }

    for (final import in importedConfigurations) {
      final componentScans = import.getDirectAnnotations<ComponentScan>();
      _extractComponentScanFilters(componentScans, import);
    }
  }

  /// Extracts include/exclude filters from [`@ComponentScan`] annotations.
  ///
  /// Merges discovered filters into the global [includeFilters] and [excludeFilters]
  /// lists for later use by the scanning subsystem.
  ///
  /// Emits detailed logs describing the number and type of filters discovered.
  void _extractComponentScanFilters(Iterable<ComponentScan> componentScans, Class type) {
    for (final componentScan in componentScans) {
      includeFilters.addAll(_createTypeFilters(componentScan.includeFilters));
      excludeFilters.addAll(_createTypeFilters(componentScan.excludeFilters));

      if (logger.getIsTraceEnabled()) {
        logger.trace(
          '📦 Extracted ${componentScan.includeFilters.length} include and '
          '${componentScan.excludeFilters.length} exclude filter(s) '
          'from ${type.getQualifiedName()}'
        );
      }
    }
  }

  /// Processes [`@Import`] annotations on a given [ConfigurationClass].
  ///
  /// - Resolves imported classes and detects circular dependencies.
  /// - Handles [`ImportSelector`]s and merges their selected classes.
  /// - Registers both direct and package-level imports.
  /// - Populates [importedConfigurations], [disabledImportClasses],
  ///   and [unscannedPackages].
  ///
  /// This method is invoked during filter discovery to ensure all imports are
  /// available for further configuration processing.
  @protected
  Future<void> processImports(ConfigurationClass configClass, ConditionEvaluator evaluator) async {
    final key = configClass.type.getQualifiedName();

    if (!_processedImports.add(key)) {
      return;
    }

    final imports = configClass.definition.getAnnotations<Import>().toSet().flatMap((i) => i.classes).toList();

    if (imports.isEmpty) {
      if (logger.getIsTraceEnabled()) {
        logger.trace('ℹ️ No @Import annotations in $key');
      }

      return;
    }

    if (logger.getIsTraceEnabled()) {
      logger.trace('📦 Processing @Import annotations for $key');
    }

    final localImportClasses = <ImportClass>[];
    final importConfigurationClasses = <Class>[];
    
    for (final import in imports) {
      final type = import.toClass();

      // Avoid import cycles
      if (_importStack.any((c) => c == type || c.getQualifiedName() == type.getQualifiedName())) {
        if (logger.getIsTraceEnabled()) {
          logger.trace('⚠️ Import cycle detected for ${type.getQualifiedName()}, skipping.');
        }

        continue; // Import cycle detected
      }

      if (!_scannedClasses.add(type) || !_scannedClassQualifiedNames.add(type.getQualifiedName())) {
        if (logger.getIsTraceEnabled()) {
          logger.trace('⏭️ Already scanned import class ${type.getQualifiedName()}, skipping.');
        }

        continue;
      }
      
      _importStack.add(type);

      if (Class<ImportSelector>(null, PackageNames.CORE).isAssignableFrom(type)) {
        final selector = (type.getNoArgConstructor() ?? type.getBestConstructor([]))?.newInstance();
        if (selector != null && selector is ImportSelector) {
          if (logger.getIsTraceEnabled()) {
            logger.trace('🧭 ImportSelector selected ${selector.selects().length} classes.');
          }

          localImportClasses.addAll(selector.selects());
        }
      } else if (await isConfigurationCandidate(type, evaluator)) {
        importConfigurationClasses.add(type);

        if (logger.getIsTraceEnabled()) {
          logger.trace('📘 Importing configuration class ${type.getQualifiedName()}');
        }
      }

      final basePackage = type.getPackage().getName();
      localImportClasses.add(ImportClass.package(basePackage));
    }

    if (importConfigurationClasses.isEmpty && localImportClasses.isEmpty) {
      if (logger.getIsTraceEnabled()) {
        logger.trace('ℹ️ No import configuration or classes found for $key');
      }

      return;
    }

    List<String> packages = <String>[];

    for (final importClass in localImportClasses.whereType<EnabledImportClass>()) {
      if (importClass.importedClass case final importedClass?) {
        importConfigurationClasses.add(importedClass);
      } else {
        packages.add(importClass.packageName);
      }
    }

    for (final importedConfigClass in importConfigurationClasses.where((i) => !i.hasDirectAnnotation<AutoConfiguration>())) {
      final packageName = importedConfigClass.getPackage().getName();
      packages.add(packageName);
    }
    
    unscannedPackages.addAll(packages);
    disabledImportClasses.addAll(localImportClasses.whereType<DisabledImportClass>());
    importedConfigurations.addAll(importConfigurationClasses.where((i) => i.hasDirectAnnotation<AutoConfiguration>()));

    if (logger.getIsTraceEnabled()) {
      logger.trace('✅ Processed @Import for ${configClass.type.getQualifiedName()}');
    }

    return;
  }

  /// Creates type filters from filter configurations
  /// 
  /// This method creates type filters from filter configurations by:
  /// - Processing @ComponentScan annotations
  /// 
  /// ### Parameters
  /// - `filterConfigs`: The filter configurations to process.
  /// 
  /// ### Returns
  /// A `List<TypeFilter>`.
  /// 
  /// ### Example
  /// ```dart
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final parser = ConfigurationClassParser(env, factory);
  ///
  /// final configClass = await parser.parse(PodDefinition(type: ConfigurationClass));
  /// await parser._processConfigurationClass(configClass);
  /// ```
  List<TypeFilter> _createTypeFilters(List<ComponentScanFilter> filterConfigs) {
    final filters = <TypeFilter>[];
    
    for (final config in filterConfigs) {
      if (config.typeFilter != null) {
        filters.add(config.typeFilter!);
      }

      switch(config.type) {
        case FilterType.ANNOTATION:
          if (config.classes.isNotEmpty) {
            config.classes.process((cls) => filters.add(AnnotationTypeFilter(cls.toClass())));
          }
          break;
        case FilterType.ASSIGNABLE:
          if (config.classes.isNotEmpty) {
            config.classes.process((cls) => filters.add(AssignableTypeFilter(cls.toClass())));
          }
          break;
        case FilterType.REGEX:
          if (config.pattern != null) {
            filters.add(RegexPatternTypeFilter(RegExp(config.pattern!)));
          }
          break;
        default:
          break;
      }
    }
    
    return filters;
  }
}

/// {@template abstract_configuration_class_definition_support}
/// Base class providing utility methods for identifying and processing
/// configuration-related pod definitions within the JetLeaf container.
///
/// This class is typically extended by higher-level configuration processors
/// that participate in the **pod definition post-processing phase** — such as
/// configuration class enhancers, import processors, or auto-configuration
/// scanners.
///
/// ### Responsibilities
/// - Scans the pod factory for **configuration candidates** annotated with
///   [`@Configuration`] or [`@AutoConfiguration`].
/// - Evaluates inclusion conditions using a [ConditionEvaluator].
/// - Provides structured and traceable logging for diagnostics.
/// - Serves as a reusable support class for other `PodFactoryPostProcessor`s
///   that need to inspect or modify configuration-related definitions.
///
/// ### Key Concepts
/// - **Configuration Candidates** — Pod definitions annotated with
///   [`@Configuration`] or [`@AutoConfiguration`].
/// - **Condition Evaluation** — Each candidate is passed through a
///   [ConditionEvaluator] to determine if it should be included based on
///   environment or annotation-based conditions.
/// - **Trace Logging** — Detailed trace-level logs provide visibility into
///   configuration discovery and filtering processes.
///
/// ### Example
/// ```dart
/// final support = MyConfigurationProcessor(); // extends ConfigurationClassDefinitionSupport
/// final definitions = await support.getConfigDefinitions(podFactory, evaluator);
///
/// for (final def in definitions) {
///   print('Found configuration: ${def.type.getQualifiedName()}');
/// }
/// ```
///
/// ### Extending This Class
/// Subclasses should implement [PodFactoryPostProcessor] behavior and may use
/// [getConfigDefinitions] to easily retrieve all configuration-related
/// definitions discovered in the current pod factory.
///
/// {@endtemplate}
abstract class ConfigurationClassDefinitionSupport implements PodFactoryPostProcessor {
  /// Logger instance for this class.
  ///
  /// Used to emit trace-level diagnostic messages during configuration scanning
  /// and evaluation. Logging is automatically controlled by the active
  /// `jetleaf_logging` configuration.
  @protected
  final Log logger = LogFactory.getLog(ConfigurationClassDefinitionSupport);

  /// Retrieves all configuration class definitions from the provided [podFactory].
  ///
  /// This method:
  /// - Iterates over all pod definitions in the factory.
  /// - Evaluates each definition for configuration eligibility.
  /// - Filters only those annotated with [`@Configuration`] or [`@AutoConfiguration`].
  /// - Respects conditional inclusion via [ConditionEvaluator].
  ///
  /// Returns a list of valid configuration candidate [PodDefinition]s.
  ///
  /// Logs detailed trace messages if tracing is enabled.
  @protected
  Future<List<PodDefinition>> getConfigDefinitions(ConfigurableListablePodFactory podFactory, ConditionEvaluator evaluator) async {
    final candidates = <PodDefinition>[];
    final processedNames = <String>{};

    if (logger.getIsTraceEnabled()) {
      logger.trace('🔍 Searching for configuration candidates ...');
    }
    
    for (final podName in podFactory.getDefinitionNames()) {
      if (processedNames.contains(podName)) {
        if (logger.getIsTraceEnabled()) {
          logger.trace('⏭️ Skipping already processed pod: $podName');
        }

        continue;
      }
      
      final definition = podFactory.getDefinition(podName);
      
      // Check if this is a configuration candidate
      if (await isConfigurationCandidate(definition, evaluator)) {
        candidates.add(definition);
        processedNames.add(podName);

        if (logger.getIsTraceEnabled()) {
          logger.trace('✅ Found configuration candidate: $podName (${definition.type.getQualifiedName()})');
        }
      }
    }

    if (logger.getIsTraceEnabled()) {
      logger.trace('🧩 Completed _getConfigDefinitions(): Found ${candidates.length} candidate(s).');
    }
    
    return candidates;
  }

  /// Determines whether the given [candidate] represents a configuration class.
  ///
  /// Checks for the presence of:
  /// - [`@Configuration`] annotation, or
  /// - [`@AutoConfiguration`] annotation
  ///
  /// If the candidate is a [PodDefinition], the method also applies conditional
  /// evaluation through the provided [ConditionEvaluator].
  ///
  /// Returns `true` if the candidate should be treated as a configuration class;
  /// otherwise, returns `false`.
  ///
  /// Logs detailed trace-level information during evaluation when enabled.
  @protected
  Future<bool> isConfigurationCandidate(Object candidate, ConditionEvaluator evaluator) async {
    if (logger.getIsTraceEnabled()) {
      logger.trace('🔎 Checking if candidate is configuration: $candidate');
    }

    if (candidate is Class) {
      final result = candidate.hasDirectAnnotation<Configuration>() || candidate.hasDirectAnnotation<AutoConfiguration>();

      if (logger.getIsTraceEnabled()) {
        logger.trace('📘 Candidate ${candidate.getQualifiedName()} is ${result ? "" : "not "}a configuration class.');
      }

      return result;
    } else if (candidate is PodDefinition) {
      final type = candidate.type;
    
      // Check for @Configuration annotation
      if (candidate.hasAnnotation<Configuration>()) {
        final include = await evaluator.shouldInclude(type);
        
        if (logger.getIsTraceEnabled()) {
          logger.trace('📘 PodDefinition ${type.getQualifiedName()} has @Configuration (include=$include).');
        }

        return include;
      }
      
      // Check for @AutoConfiguration annotation
      if (candidate.hasAnnotation<AutoConfiguration>()) {
        final include = await evaluator.shouldInclude(type);

        if (logger.getIsTraceEnabled()) {
          logger.trace('📗 PodDefinition ${type.getQualifiedName()} has @AutoConfiguration (include=$include).');
        }

        return include;
      }
    }
    
    if (logger.getIsTraceEnabled()) {
      logger.trace('🚫 Candidate is not a configuration type: $candidate');
    }

    return false;
  }
}