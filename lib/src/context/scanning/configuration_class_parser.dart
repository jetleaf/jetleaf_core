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
import '../../annotations/pod.dart';
import '../../annotations/stereotype.dart';
import '../../condition/condition_evaluator.dart';
import '../../scope/annotated_scope_metadata_resolver.dart';
import '../../scope/scope_metadata_resolver.dart';
import '../helpers.dart';
import 'annotated_pod_name_generator.dart';
import 'component_scan_annotation_parser.dart';
import 'configuration_class.dart';

/// Set of scanned packages to avoid duplicate scanning
final Set<String> _scannedPackages = {};

/// Set of scanned classes to avoid duplicate scanning
final Set<Class> _scannedClasses = {};

/// Set of scanned class qualified names to avoid duplicate scanning - fallback incase _scannedClasses does not catch it.
final Set<String> _scannedClassQualifiedNames = {};

/// Set of classes currently being processed (cycle detection)
final Set<Class> _processingClasses = {};

/// {@template configuration_class_parser}
/// Parses configuration classes and extracts their metadata.
/// 
/// This parser handles:
/// - @Pod methods → collects them into ConfigurationClass
/// - @Import annotations → registers additional configuration classes
/// - @ComponentScan → triggers classpath scanning
/// - Conditional processing via @Conditional annotations
/// 
/// It is used by ConfigurationClassPostProcessor to process @Configuration classes.
/// {@endtemplate}
final class ConfigurationClassParser {
  /// The environment to use for configuration parsing
  final Environment environment;
  
  /// The pod factory to use for configuration parsing
  final ConfigurableListablePodFactory podFactory;
  
  /// The condition evaluator to use for configuration parsing
  final ConditionEvaluator conditionEvaluator;
  
  /// The component scan annotation parser to use for configuration parsing
  final ComponentScanAnnotationParser componentScanParser;

  /// The entry application class
  final Class<Object> entryApplication;
  
  /// Stack to track import cycles
  final List<ConfigurationClass> importStack = [];

  /// {@macro configuration_class_parser}
  ConfigurationClassParser(this.environment, this.podFactory, this.conditionEvaluator, this.entryApplication) 
    : componentScanParser = ComponentScanAnnotationParser(podFactory, environment, conditionEvaluator, entryApplication);

  /// {@template parse_configuration_class}
  /// Parses a pod definition into a ConfigurationClass if it represents a configuration.
  /// 
  /// Returns null if the class should be skipped due to conditions or if it's not
  /// a valid configuration class.
  /// 
  /// ### Parameters
  /// - `definition`: The pod definition to parse.
  /// 
  /// ### Returns
  /// A `ConfigurationClass` instance if the class is a configuration class, or null otherwise.
  /// 
  /// ### Example
  /// ```dart
  /// final env = Environment();
  /// final factory = DefaultPodFactory();
  /// final parser = ConfigurationClassParser(env, factory);
  ///
  /// final configClass = await parser.parse(PodDefinition(type: ConfigurationClass));
  /// ```
  /// {@endtemplate}
  Future<ConfigurationClass?> parse(PodDefinition definition) async {
    final type = definition.type;
    
    // Avoid processing the same class multiple times
    if (_processingClasses.contains(type)) {
      return null; // Cycle detected
    }
    
    // Check conditions first
    if (!await conditionEvaluator.shouldInclude(type)) {
      return null; // Conditions not met
    }
    
    _processingClasses.add(type);
    
    try {
      // Determine proxy semantics from annotation
      bool proxyPodMethods = true;
      if (definition.hasAnnotation<Configuration>()) {
        proxyPodMethods = definition.getAnnotation<Configuration>()?.proxyPodMethods ?? false;
      } else if (definition.hasAnnotation<AutoConfiguration>()) {
        proxyPodMethods = definition.getAnnotation<AutoConfiguration>()?.proxyPodMethods ?? false;
      }

      // Determine scope resolver semantics from annotation
      ScopeMetadataResolver? scopeMetadataResolver;
      if (definition.hasAnnotation<Configuration>()) {
        scopeMetadataResolver = definition.getAnnotation<Configuration>()?.scopeResolver;
      } else if (definition.hasAnnotation<AutoConfiguration>()) {
        scopeMetadataResolver = definition.getAnnotation<AutoConfiguration>()?.scopeResolver;
      }

      // Determine pod name
      String podName = definition.name;
      if(podName.isEmpty) {
        podName = AnnotatedPodNameGenerator().generate(definition, podFactory);
      }
      definition.name = podName;

      final configClass = ConfigurationClass(podName, type, definition, proxyPodMethods, scopeMetadataResolver ?? AnnotatedScopeMetadataResolver());
      
      // Process the configuration class
      await _processConfigurationClass(configClass);
      
      return configClass;
    } finally {
      _processingClasses.remove(type);
    }
  }
  
  /// Main processing method for a configuration class
  /// 
  /// This method processes a configuration class by:
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
  Future<void> _processConfigurationClass(ConfigurationClass configClass) async {
    // Process @ComponentScan annotations
    await _processComponentScan(configClass);
    
    // Process @Import annotations
    await _processImports(configClass);
    
    // Process @Pod methods
    await _processPodMethods(configClass);
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
  Future<void> _processComponentScan(ConfigurationClass configClass) async {
    final componentScans = configClass.definition.getAnnotations<ComponentScan>().toSet();

    final imports = await _selectImports(configClass);
    
    for (final componentScan in componentScans) {
      // Check conditions on the @ComponentScan annotation itself
      if (!await conditionEvaluator.shouldInclude(componentScan.getClass())) {
        continue;
      }
      
      List<String> basePackages = List<String>.from(componentScan.basePackages);
      List<Class> basePackageClasses = List<Class>.from(componentScan.basePackageClasses.map((c) => c.toClass()));
      imports.process((import) {
        if (!import.isQualifiedName) {
          basePackages.add(import.name);
        } else {
          basePackageClasses.add(Class.fromQualifiedName(import.name));
        }
      });

      final packagesToScan = <String>{};
      for (final pkg in basePackages) {
        if (_scannedPackages.add(pkg)) {
          packagesToScan.add(pkg);
        }
      }

      final classesToScan = <Class>{};
      for (final pkg in basePackageClasses) {
        if (_scannedClasses.add(pkg) || _scannedClassQualifiedNames.add(pkg.getQualifiedName())) {
          classesToScan.add(pkg);
        }
      }
      
      final scanConfig = ComponentScanConfiguration(
        basePackages: packagesToScan.toList(),
        basePackageClasses: classesToScan.toList(),
        includeFilters: _createTypeFilters(componentScan.includeFilters),
        excludeFilters: _createTypeFilters(componentScan.excludeFilters),
        useDefaultFilters: componentScan.useDefaultFilters,
        scopeResolver: componentScan.scopeResolver,
        nameGenerator: componentScan.nameGenerator,
      );
      
      configClass.addComponentScan(scanConfig);
      
      // Trigger actual component scanning
      final scannedDefinitions = await componentScanParser.parse(scanConfig, configClass);
      
      // Process any scanned configuration classes recursively
      for (final scannedDef in scannedDefinitions) {
        if (await _isConfigurationCandidate(scannedDef)) {
          final nestedConfigClass = await parse(scannedDef);
          if (nestedConfigClass != null) {
            configClass.addImportedConfiguration(nestedConfigClass);
          }
        } else {
          podFactory.registerDefinition(scannedDef.name, scannedDef);
        }
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

  /// Helper method to check if a class is a configuration candidate
  /// 
  /// This method checks if a class is a configuration candidate by:
  /// - Checking if the class has a @Configuration annotation
  /// - Checking if the class has a @AutoConfiguration annotation
  /// 
  /// ### Parameters
  /// - `candidate`: The candidate to check.
  /// 
  /// ### Returns
  /// A `bool` indicating whether the candidate is a configuration candidate.
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
  Future<bool> _isConfigurationCandidate(Object candidate) async {
    if (candidate is Class) {
      return candidate.hasDirectAnnotation<Configuration>() || candidate.hasDirectAnnotation<AutoConfiguration>();
    } else if (candidate is PodDefinition) {
      return candidate.hasAnnotation<Configuration>() || candidate.hasAnnotation<AutoConfiguration>();
    } else {
      return false;
    }
  }

  /// Selects imports based on the configuration class
  /// 
  /// This method selects imports based on the configuration class by:
  /// - Checking if the configuration class has a @Import annotation
  /// - Processing @Import annotations
  /// 
  /// ### Parameters
  /// - `configClass`: The configuration class to process.
  /// 
  /// ### Returns
  /// A `Future<List<ImportClass>>`.
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
  Future<List<ImportClass>> _selectImports(ConfigurationClass configClass) async {
    final result = <ImportClass>[];
  
    final imports = configClass.definition.getAnnotations<Import>().toSet();
    final importClasses = imports.flatMap((i) => i.classes);
    
    for (final import in importClasses) {
      final type = import.toClass();

      if (type.isAssignableTo(Class<ImportSelector>(null, PackageNames.CORE))) {
        final selector = (type.getNoArgConstructor() ?? type.getBestConstructor([]))?.newInstance();
        if (selector != null && selector is ImportSelector) {
          result.addAll(selector.selects());
        }
      }
    }

    return result;
  }
  
  /// Processes @Import annotations on the configuration class
  /// 
  /// This method processes @Import annotations on the configuration class by:
  /// - Checking if the configuration class has a @Import annotation
  /// - Processing @Import annotations
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
  Future<void> _processImports(ConfigurationClass configClass) async {
    final imports = configClass.definition.getAnnotations<Import>().toSet();
    final importClasses = imports.flatMap((i) => i.classes);
    
    for (final import in importClasses) {
      await _processImport(configClass, import.toClass());
    }
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
  Future<void> _processImport(ConfigurationClass configClass, Class<Object> importedClass) async {
    // Avoid import cycles
    if (importStack.any((c) => c.type == importedClass)) {
      return; // Import cycle detected
    }

    if (!_scannedClasses.add(importedClass) || !_scannedClassQualifiedNames.add(importedClass.getQualifiedName())) {
      return;
    }
    
    importStack.add(configClass);
    
    try {
      // Check if imported class is a configuration
      if (await _isConfigurationCandidate(importedClass)) {
        final importedConfigClass = await _parseImportedConfiguration(importedClass);
        if (importedConfigClass != null) {
          configClass.addImportedConfiguration(importedConfigClass);
        }
      } else {
        // Register as a regular pod
        await _registerImportedPod(importedClass);
      }
    } finally {
      importStack.removeLast();
    }
  }

  /// Parses an imported configuration class
  /// 
  /// This method parses an imported configuration class by:
  /// - Creating a temporary pod definition for parsing
  /// - Parsing the imported configuration class
  /// 
  /// ### Parameters
  /// - `importedClass`: The imported class to parse.
  /// 
  /// ### Returns
  /// A `Future<ConfigurationClass?>`.
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
  Future<ConfigurationClass?> _parseImportedConfiguration(Class<Object> importedClass) async {
    if (!_scannedClasses.add(importedClass) || !_scannedClassQualifiedNames.add(importedClass.getQualifiedName())) {
      return null;
    }

    // Create a temporary pod definition for parsing
    final tempDefinition = RootPodDefinition(type: importedClass);
    return await parse(tempDefinition);
  }

  /// Registers an imported class as a regular pod
  /// 
  /// This method registers an imported class as a regular pod by:
  /// - Creating a temporary pod definition for parsing
  /// - Registering the imported class as a regular pod
  /// 
  /// ### Parameters
  /// - `importedClass`: The imported class to register.
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
  Future<void> _registerImportedPod(Class importedClass) async {
    final definition = RootPodDefinition(type: importedClass);
    final podName = AnnotatedPodNameGenerator().generate(definition, podFactory);
    
    if (!podFactory.containsDefinition(podName)) {
      await podFactory.registerDefinition(podName, definition);
    }
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
  Future<void> _processPodMethods(ConfigurationClass configClass) async {
    final methods = configClass.type.getMethods();
    
    for (final method in methods) {
      if (method.hasDirectAnnotation<Pod>()) {
        // Check conditions on the method
        if (!await conditionEvaluator.shouldInclude(method)) {
          continue;
        }
        
        final podMethod = PodMethod(configurationClass: configClass, method: method);
        configClass.addPodMethod(podMethod);
      }
    }
  }
}