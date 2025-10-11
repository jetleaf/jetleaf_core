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

import '../../annotations/configuration.dart';
import '../../annotations/others.dart';
import '../../annotations/pod.dart';
import '../../annotations/stereotype.dart';
import '../../aware.dart';
import '../../condition/condition_evaluator.dart';
import '../../scope/annotated_scope_metadata_resolver.dart';
import '../helpers.dart';
import 'annotated_pod_definition_reader.dart';
import 'annotated_pod_name_generator.dart';
import 'class_path_pod_definition_scanner.dart';
import 'component_scan_annotation_parser.dart';
import 'configuration_class.dart';
import 'configuration_class_parser.dart';

/// Set of scanned packages to avoid duplicate scanning
final Set<String> _scannedPackages = {};

/// Set of scanned classes to avoid duplicate scanning
final Set<Class> _scannedClasses = {};

/// Set of scanned class qualified names to avoid duplicate scanning - fallback incase _scannedClasses does not catch it.
final Set<String> _scannedClassQualifiedNames = {};

/// Set of scanned class qualified names to avoid duplicate scanning - fallback incase _scannedClasses does not catch it.
final List<Class> _importStack = [];

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
  final Set<ConfigurationClass> _processedConfigurations = {};
  
  /// Set of pod definition names that have been processed
  final Set<String> _processedPodNames = {};

  /// The environment to use for configuration parsing
  late final Environment _environment;

  /// The condition evaluator to use for configuration parsing
  late final ConditionEvaluator _conditionEvaluator;

  late final ConfigurationClassParser _parser;

  late final ComponentScanAnnotationParser _componentScanParser;

  /// The pod factory to use for configuration parsing
  late final ConfigurableListablePodFactory _podFactory;

  /// The entry application class
  late final Class<Object> _entryApplication;

  final Log _logger = LogFactory.getLog(ConfigurationClassPostProcessor);

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
    this._entryApplication = entryApplication;
  }

  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔧 Starting postProcessFactory for podFactory: ${podFactory.runtimeType}');
    }

    this._podFactory = podFactory;

    _conditionEvaluator = ConditionEvaluator(_environment, podFactory, Runtime);
    _parser = ConfigurationClassParser(podFactory);
    final scanner = ClassPathPodDefinitionScanner(_conditionEvaluator, podFactory, _entryApplication);
    _componentScanParser = ComponentScanAnnotationParser(scanner);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔍 Initialized configuration components — ConditionEvaluator, Parser, Scanner, ComponentScanParser.');
    }

    // Find configuration candidates
    final candidates = await _findConfigurationCandidates();
    
    if (candidates.isEmpty) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('⚠️ No configuration candidates found. Exiting post-process early.');
      }

      return;
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Found ${candidates.length} configuration candidate(s).');
    }
    
    // Parse configuration classes and gather all of them
    // Keeps track of discovered pod definitions and methods
    final definitions = <PodDefinition>[];
    final podMethods = <PodMethod>[];
    final disabledImports = <ImportClass>[];

    // Queue for configuration classes to process
    final queue = <ConfigurationClass>[];

    // Step 1: Parse initial candidates
    for (final candidate in candidates) {
      final configClass = await _parser.parse(candidate);
      if (configClass != null && !_processedConfigurations.contains(configClass)) {
        queue.add(configClass);
        _processedConfigurations.add(configClass);
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ Parsed initial configuration class: ${configClass?.type.getQualifiedName()}');
      }
    }

    // Step 2: Process queue iteratively until empty
    var iteration = 0;
    while (queue.isNotEmpty) {
      iteration++;

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🔁 Iteration $iteration — Processing ${queue.length} configuration class(es).');
      }

      final localDefinitions = <PodDefinition>[];
      final localPodMethods = <PodMethod>[];
      final current = queue.removeLast();

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('⚙️ Processing configuration: ${current.type.getQualifiedName()}');
      }

      // Process imports, scans, and pods
      await _processImports(current, localDefinitions, disabledImports);
      await _processComponentScan(current, localDefinitions);
      await _processPodMethods(current, localPodMethods);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('📦 Processed ${localDefinitions.length} local pod definition(s) and ${localPodMethods.length} pod method(s).');
      }

      // Step 3: Check for new configuration candidates
      final newCandidates = <ConfigurationClass>[];
      for (final def in localDefinitions) {
        if (await _isConfigurationCandidate(def)) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('🔎 Found nested configuration candidate: ${def.type.getQualifiedName()}');
          }

          final nestedConfig = await _parser.parse(def);
          if (nestedConfig != null && !_processedConfigurations.contains(nestedConfig)) {
            newCandidates.add(nestedConfig);
            _processedConfigurations.add(nestedConfig);
          }
        }
      }

      if (_logger.getIsTraceEnabled() && newCandidates.isNotEmpty) {
        _logger.trace('🧭 Added ${newCandidates.length} new configuration class(es) to queue.');
      }

      // Add discovered configs to queue for next iteration
      queue.addAll(newCandidates);
      definitions.addAll(localDefinitions);
      podMethods.addAll(localPodMethods);
      definitions.add(current.definition);
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('📋 Finished processing configuration queue. Total definitions: ${definitions.length}, total pod methods: ${podMethods.length}.');
    }

    final definitionSet = <PodDefinition>{};
    final mappedPodMethods = <String, PodMethod>{};

    for (final podMethod in podMethods) {
      final definition = await _createPodDefinitionFromMethod(podMethod);
    
      // Check if pod name is already in use
      String finalPodName = definition.name;
      if (_podFactory.containsDefinition(finalPodName)) {
        finalPodName = SimplePodNameGenerator().generate(definition, _podFactory);
      }

      if (_podFactory.containsDefinition(finalPodName)) {
        finalPodName = podMethod.method.getName();
      }

      definition.name = finalPodName;
      definitionSet.add(definition);
      mappedPodMethods[finalPodName] = podMethod;

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🔧 Created pod definition from method: ${definition.name} (${definition.type.getQualifiedName()})');
      }
    }

    // Merge remaining definitions
    for (final definition in definitions) {
      // final notAdded = definitionSet.none((def) => def.name.equals(definition.name) && def.type.getQualifiedName().equals(definition.type.getQualifiedName()));
      final notRegistered = candidates.none((def) => def.name.equals(definition.name) && def.type.getQualifiedName().equals(definition.type.getQualifiedName()));

      if (notRegistered) {
        definitionSet.add(definition);

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🧱 Added standalone pod definition: ${definition.name} (${definition.type.getQualifiedName()})');
        }
      }
    }

    _conditionEvaluator.types = definitionSet.map((def) => def.type).toList();
    _conditionEvaluator.names = definitionSet.map((def) => def.name).toList();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧠 Updated ConditionEvaluator context — ${_conditionEvaluator.types.length} types, ${_conditionEvaluator.names.length} names.');
    }

    for (final def in definitionSet) {
      if (disabledImports.any((i) => i.isQualifiedName ? def.type.getQualifiedName().equals(i.name) : (def.type.getPackage()?.getName().equals(i.name) ?? false))) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🧱 Skipping disabled import of ${def.type}');
        }

        continue;
      }

      if (mappedPodMethods.containsKey(def.name)) {
        final source = mappedPodMethods[def.name]!;

        if (await _conditionEvaluator.shouldInclude(source.method)) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('✅ Registered pod from method: ${def.name}');
          }

          await _podFactory.registerDefinition(def.name, def);
        } else {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('🚫 Skipped pod (condition failed): ${def.name}');
          }
        }
      } else if (await _conditionEvaluator.shouldInclude(def.type)) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ Registered pod definition: ${def.name}');
        }

        await _podFactory.registerDefinition(def.name, def);
      } else {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🚫 Skipped pod (condition failed): ${def.name}');
        }
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧹 Clearing processed configuration state.');
    }

    // Clear processed state
    clearProcessedState();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🏁 Completed post-processing for [ConfigurationClassPostProcessor].');
    }
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

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔍 Searching for configuration candidates ...');
    }
    
    for (final podName in _podFactory.getDefinitionNames()) {
      if (_processedPodNames.contains(podName)) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('⏭️ Skipping already processed pod: $podName');
        }

        continue;
      }
      
      final definition = _podFactory.getDefinition(podName);
      
      // Check if this is a configuration candidate
      if (await _isConfigurationCandidate(definition)) {
        candidates.add(definition);
        _processedPodNames.add(podName);

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ Found configuration candidate: $podName (${definition.type.getQualifiedName()})');
        }
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Completed _findConfigurationCandidates(): Found ${candidates.length} candidate(s).');
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
  /// - `candidate`: The candidate to check.
  /// 
  /// ### Returns
  /// A boolean indicating whether the candidate is a configuration candidate.
  Future<bool> _isConfigurationCandidate(Object candidate) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔎 Checking if candidate is configuration: $candidate');
    }

    if (candidate is Class) {
      final result = candidate.hasDirectAnnotation<Configuration>() || candidate.hasDirectAnnotation<AutoConfiguration>();

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('📘 Candidate ${candidate.getQualifiedName()} is ${result ? "" : "not "}a configuration class.');
      }

      return result;
    } else if (candidate is PodDefinition) {
      final type = candidate.type;
    
      // Check for @Configuration annotation
      if (candidate.hasAnnotation<Configuration>()) {
        final include = await _conditionEvaluator.shouldInclude(type);
        
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('📘 PodDefinition ${type.getQualifiedName()} has @Configuration (include=$include).');
        }

        return include;
      }
      
      // Check for @AutoConfiguration annotation
      if (candidate.hasAnnotation<AutoConfiguration>()) {
        final include = await _conditionEvaluator.shouldInclude(type);

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('📗 PodDefinition ${type.getQualifiedName()} has @AutoConfiguration (include=$include).');
        }

        return include;
      }
    }
    
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🚫 Candidate is not a configuration type: $candidate');
    }

    return false;
  }
  
  /// Processes a single imported class
  /// 
  /// This method processes a single imported class by:
  /// - Avoiding import cycles
  /// - Checking if the imported class is a configuration candidate
  /// - Processing the imported class
  /// 
  /// ### Parameters
  /// - `configClass`: The configuration class to process.
  /// - `importedClass`: The imported class to process.
  /// 
  /// ### Returns
  /// A `Future<void>`.
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
  Future<void> _processImports(ConfigurationClass configClass, List<PodDefinition> definitions, List<ImportClass> disableImports) async {
    final imports = configClass.definition.getAnnotations<Import>().toSet().flatMap((i) => i.classes).toList();

    if (imports.isEmpty) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('ℹ️ No @Import annotations in ${configClass.type.getQualifiedName()}');
      }

      return;
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('📦 Processing @Import annotations for ${configClass.type.getQualifiedName()}');
    }

    final importClasses = <ImportClass>[];
    final importConfigurationClasses = <Class>[];
    
    for (final import in imports) {
      final type = import.toClass();

      // Avoid import cycles
      if (_importStack.any((c) => c == type || c.getQualifiedName() == type.getQualifiedName())) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('⚠️ Import cycle detected for ${type.getQualifiedName()}, skipping.');
        }

        return; // Import cycle detected
      }

      if (!_scannedClasses.add(type) || !_scannedClassQualifiedNames.add(type.getQualifiedName())) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('⏭️ Already scanned import class ${type.getQualifiedName()}, skipping.');
        }

        return;
      }
      
      _importStack.add(type);

      if (Class<ImportSelector>(null, PackageNames.CORE).isAssignableFrom(type)) {
        final selector = (type.getNoArgConstructor() ?? type.getBestConstructor([]))?.newInstance();
        if (selector != null && selector is ImportSelector) {
          if (_logger.getIsTraceEnabled()) {
            _logger.trace('🧭 ImportSelector selected ${selector.selects().length} classes.');
          }

          importClasses.addAll(selector.selects());
        }
      } else if (await _isConfigurationCandidate(type)) {
        importConfigurationClasses.add(type);

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('📘 Importing configuration class ${type.getQualifiedName()}');
        }
      }

      final basePackage = type.getPackage()?.getName();
      if (basePackage != null) {
        importClasses.add(ImportClass.package(basePackage));
      }
    }

    if (importConfigurationClasses.isEmpty && importClasses.isEmpty) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('ℹ️ No import configuration or classes found for ${configClass.type.getQualifiedName()}');
      }

      return;
    }

    List<String> basePackages = <String>[];
    List<Class> basePackageClasses = List<Class>.from(importConfigurationClasses);

    importClasses.where((i) => i.disable.equals(false)).process((import) {
      if (!import.isQualifiedName) {
        basePackages.add(import.name);
      } else {
        basePackageClasses.add(Class.fromQualifiedName(import.name));
      }
    });

    final scanConfig = ComponentScanConfiguration(
      basePackages: basePackages.filter((b) => _scannedPackages.add(b)).toList(),
      basePackageClasses: basePackageClasses.filter((b) => _scannedClasses.add(b)).toList(),
    );

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔬 Parsing imports: ${scanConfig.basePackages.length} packages, ${scanConfig.basePackageClasses.length} classes.');
    }

    definitions.addAll(await _componentScanParser.parse(scanConfig));

    for (final importedConfigClass in importConfigurationClasses) {
      if (importedConfigClass.hasDirectAnnotation<AutoConfiguration>()) {
        final definition = _createPodDefinition(importedConfigClass);
        final cc = ConfigurationClass(definition.name, importedConfigClass, definition);
        
        await _processComponentScan(cc, definitions);
        definitions.add(definition);
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('✅ Processed @Import for ${configClass.type.getQualifiedName()}');
    }
  }

  /// Creates a pod definition for the given class
  /// 
  /// This method creates a pod definition for the given class by:
  /// - Creating a root pod definition
  /// - Generating a pod name
  /// - Resolving a scope
  /// - Processing common annotations
  /// 
  /// ### Parameters
  /// - `type`: The class to create a pod definition for.
  /// 
  /// ### Returns
  /// A `RootPodDefinition`.
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
  RootPodDefinition _createPodDefinition(Class type) {
    final definition = RootPodDefinition(type: type);

    // Name generation
    final nameGenerator = AnnotatedPodNameGenerator();
    definition.name = nameGenerator.generate(definition, _podFactory);
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Assigned pod name "${definition.name}" to ${type.getQualifiedName()}');
    }

    // Scope resolution
    final resolver = AnnotatedScopeMetadataResolver();
    definition.scope = resolver.resolveScopeDescriptor(definition.type);
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🏷️ Resolved scope "${definition.scope.type}" for ${definition.name}');
    }

    // Common annotations
    AnnotatedPodDefinitionReader.processCommonDefinitionAnnotations(definition);
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🪶 Processed common annotations for ${definition.name}');
    }

    return definition;
  }

  /// Processes @ComponentScan annotations on the configuration class
  /// 
  /// This method processes @ComponentScan annotations on the configuration class by:
  /// - Processing @ComponentScan annotations
  /// - Processing @Import annotations
  /// - Processing @Pod methods
  /// 
  /// ### Parameters
  /// - `configClass`: The configuration class to process.
  /// 
  /// ### Returns
  /// A `Future<void>`.
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
  Future<void> _processComponentScan(ConfigurationClass configClass, List<PodDefinition> definitions) async {
    final componentScans = configClass.definition.getAnnotations<ComponentScan>().toSet();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('ℹ️ No @ComponentScan annotations in ${configClass.type.getQualifiedName()}');
    }
    
    for (final componentScan in componentScans) {
      List<String> basePackages = List<String>.from(componentScan.basePackages);
      List<Class> basePackageClasses = List<Class>.from(componentScan.basePackageClasses.map((c) => c.toClass()));

      final basePackage = configClass.type.getPackage()?.getName();
      if (basePackage != null) {
        basePackages.add(basePackage);
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🔎 Performing component scan in ${basePackages.length} package(s) for ${configClass.type.getQualifiedName()}');
      }
      
      final scanConfig = ComponentScanConfiguration(
        basePackages: basePackages.filter((b) => _scannedPackages.add(b)).toList(),
        basePackageClasses: basePackageClasses.filter((b) => _scannedClasses.add(b)).toList(),
        includeFilters: _createTypeFilters(componentScan.includeFilters),
        excludeFilters: _createTypeFilters(componentScan.excludeFilters),
        useDefaultFilters: componentScan.useDefaultFilters,
        scopeResolver: componentScan.scopeResolver,
        nameGenerator: componentScan.nameGenerator,
      );
      
      final parsed = await _componentScanParser.parse(scanConfig);
      definitions.addAll(parsed);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ Component scan completed for ${configClass.type.getQualifiedName()} — Found ${parsed.length} definitions.');
      }
    }
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
        case FilterType.CUSTOM:
          if(config.typeFilter != null) {
            filters.add(config.typeFilter!);
          } else {
            throw UnsupportedOperationException("Custom filter type requires explicit TypeFilter");
          }
          break;
      }
    }
    
    return filters;
  }

  /// Processes @Pod methods in the configuration class
  /// 
  /// This method processes @Pod methods in the configuration class by:
  /// - Checking if the configuration class has a @Pod annotation
  /// - Processing @Pod annotations
  /// 
  /// ### Parameters
  /// - `configClass`: The configuration class to process.
  /// 
  /// ### Returns
  /// A `Future<void>`.
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
  Future<void> _processPodMethods(ConfigurationClass configClass, List<PodMethod> podMethods) async {
    final methods = configClass.type.getMethods();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('⚙️ Scanning pod methods for ${configClass.type.getQualifiedName()}');
    }
    
    for (final method in methods) {
      if (method.hasDirectAnnotation<Pod>()) {
        podMethods.add(PodMethod(configurationClass: configClass, method: method));

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🧩 Found @Pod method: ${method.getName()}');
        }
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('✅ Completed pod method scan for ${configClass.type.getQualifiedName()}. Found ${podMethods.length} methods.');
    }
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

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('⚙️ Creating RootPodDefinition from method: ${method.getName()} in ${configClass.type.getQualifiedName()}');
    }
    
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

    if (_podFactory.containsDefinition(podName)) {
      final oldName = podName;
      podName = AnnotatedPodNameGenerator().generate(definition, _podFactory);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('⚠️ Pod name conflict detected for "$oldName", generated new name: "$podName"');
      }
    }

    podAnnotation ??= Pod();
    definition.name = podName;

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Assigned pod name: "$podName" (return type: ${definition.type.getQualifiedName()})');
    }

    // Determine pod description
    String description = 'Pod method ${podMethod.getMethodName()} in ${configClass.podName}';

    if (method.hasDirectAnnotation<Description>()) {
      final descriptionAnnotation = method.getDirectAnnotation<Description>();
      if(descriptionAnnotation != null) {
        description = descriptionAnnotation.value;
      }
    }
    definition.description = description;

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('📝 Pod description set to: "$description"');
    }
    
    // Configure scope
    Scope? scope;
    if (method.hasDirectAnnotation<Scope>()) {
      scope = method.getDirectAnnotation<Scope>();
    }

    if (scope != null) {
      definition.scope = ScopeDesign.type(scope.value);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🔍 Found method-level @Scope: ${scope.value}');
      }
    } else {
      if (configClass.type.hasAnnotation<Scope>()) {
        scope ??= configClass.type.getAnnotation<Scope>();

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🔍 Using class-level @Scope: ${scope?.value}');
        }
      }

      definition.scope = configClass.scopeResolver.resolveScopeDescriptor(configClass.type);
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🧭 Resolved scope descriptor: ${definition.scope}');
      }
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

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🎨 DesignDescriptor(role=${definition.design.role}, isPrimary=${definition.design.isPrimary}, order=${definition.design.order})');
    }
    
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

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔁 LifecycleDesign(isLazy=${definition.lifecycle.isLazy}, initMethods=${definition.lifecycle.initMethods}, destroyMethods=${definition.lifecycle.destroyMethods})');
    }

    // Configure autowire mode
    definition.autowireCandidate = AutowireCandidateDescriptor(
      autowireMode: podAnnotation.autowireMode,
      autowireCandidate: true,
    );

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔗 AutowireCandidateDescriptor(autowireMode=${definition.autowireCandidate.autowireMode})');
    }
    
    // Set factory method information
    definition.factoryMethod = FactoryMethodDesign(configClass.podName, podMethod.getMethodName(), configClass.type);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🏭 FactoryMethodDesign(factoryPod=${configClass.podName}, method=${podMethod.getMethodName()})');
    }
    
    // Configure dependencies
    DependsOn? dependsOn;
    if (method.hasDirectAnnotation<DependsOn>()) {
      dependsOn = method.getDirectAnnotation<DependsOn>();
    }
    
    if (dependsOn != null) {
      definition.dependsOn = dependsOn.value.map((dep) => DependencyDesign(name: dep)).toList();

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🧩 DependsOn: ${definition.dependsOn.map((d) => d.name).join(", ")}');
      }
    }

    if (configClass.proxyPodMethods) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🧬 ProxyPodMethods enabled — enhancing definition for ${definition.name}');
      }

      await _enhancePodDefinition(definition, configClass);
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('✅ Finished creating RootPodDefinition for "${definition.name}" (${definition.type.getQualifiedName()})');
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
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔧 Enhancing PodDefinition "${definition.name}" from configuration: ${configClass.type.getQualifiedName()}');
    }

    // Mark @Pod methods as singleton if proxyPodMethods is true or else, mark as prototype
    if (configClass.proxyPodMethods) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🧬 proxyPodMethods = true → forcing singleton scope for proxy compatibility');
        _logger.trace('   Previous scope: ${definition.scope.type}');
      }

      // Force singleton scope for proxy semantics
      definition.scope = ScopeDesign.type(ScopeType.SINGLETON.name);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('   Updated scope: ${definition.scope.type}');
        _logger.trace('✅ Enhancement complete for "${definition.name}"');
      }
    } else {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('ℹ️ proxyPodMethods = false → no enhancement applied to "${definition.name}"');
      }

      definition.scope = ScopeDesign.type(ScopeType.PROTOTYPE.name);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('   Updated scope: ${definition.scope.type}');
        _logger.trace('✅ Enhancement complete for "${definition.name}"');
      }
    }
  }
  
  /// Clears processed state (useful for testing or reprocessing)
  void clearProcessedState() {
    _processedConfigurations.clear();
    _processedPodNames.clear();

    _componentScanParser.scanner.clearScannedTracking();
  }
}