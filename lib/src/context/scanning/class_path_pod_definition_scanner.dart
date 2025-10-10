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
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../../annotations/stereotype.dart';
import '../../condition/condition_evaluator.dart';
import '../../scope/annotated_scope_metadata_resolver.dart';
import '../../scope/scope_metadata_resolver.dart';
import 'annotated_pod_definition_reader.dart';
import 'annotated_pod_name_generator.dart';

/// {@template classpath_pod_definition_scanner}
/// Scans the classpath for component classes and creates pod definitions.
/// 
/// This scanner:
/// 1. Uses Runtime.getAllLibraries() to discover classes in specified packages
/// 2. Applies include/exclude filters to determine which classes to process
/// 3. Creates RootPodDefinition instances for discovered components
/// 4. Handles conditional processing via @Conditional annotations
/// 5. Tracks scanned classes to prevent duplicates
/// 
/// ### Example
/// ```dart
/// final scanner = ClassPathPodDefinitionScanner(conditionEvaluator, podFactory);
/// final definitions = await scanner.doScan('com.example');
/// ```
/// {@endtemplate}
final class ClassPathPodDefinitionScanner {
  /// The condition evaluator to use for evaluating @Conditional annotations
  final ConditionEvaluator conditionEvaluator;
  
  /// The pod factory to use for creating pod definitions
  final ConfigurableListablePodFactory podFactory;

  /// The entry application class
  final Class<Object> entryApplication;

  /// The logger to use for logging
  final Log _logger = LogFactory.getLog(ClassPathPodDefinitionScanner);
  
  /// Include filters for component scanning
  final List<TypeFilter> includeFilters = [];
  
  /// Exclude filters for component scanning
  final List<TypeFilter> excludeFilters = [];
  
  /// Custom scope resolver
  ScopeMetadataResolver? scopeResolver;
  
  /// Custom name generator
  PodNameGenerator? nameGenerator;

  /// Tracks already scanned classes by their qualified name
  final Set<String> _scannedClasses = {};
  
  /// Tracks already scanned packages
  final Set<String> _scannedPackages = {};
  
  /// Tracks already scanned methods by their qualified signature
  final Set<String> _scannedMethods = {};

  /// {@macro classpath_pod_definition_scanner}
  ClassPathPodDefinitionScanner(this.conditionEvaluator, this.podFactory, this.entryApplication);

  /// {@template do_scan}
  /// Performs the actual classpath scanning for the given base package.
  /// 
  /// This method:
  /// 1. Checks if the package has already been scanned
  /// 2. Finds all libraries in the specified package using Runtime.getAllLibraries()
  /// 3. Extracts class declarations from those libraries
  /// 4. Applies include/exclude filters
  /// 5. Creates pod definitions for matching classes
  /// 6. Evaluates conditions and registers valid definitions
  /// {@endtemplate}
  Future<List<PodDefinition>> doScan(String basePackage) async {
    if (_scannedPackages.contains(basePackage)) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Package $basePackage already scanned, skipping');
      }
      return [];
    }
    
    _scannedPackages.add(basePackage);
    
    final scannedDefinitions = <PodDefinition>[];
    
    // Find libraries in the base package
    final libraries = Runtime.getAllLibraries().where((lib) => lib.getPackage().getName() == basePackage);
    final classes = libraries.flatMap((library) => library.getClasses()).toSet();
    
    for (final classDeclaration in classes) {
      final cls = Class.declared(classDeclaration, ProtectionDomain.current());
      final qualifiedName = cls.getQualifiedName();

      if (_scannedClasses.contains(qualifiedName)) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Class $qualifiedName already scanned, skipping');
        }
        continue;
      }

      // Apply filters to determine if this class should be processed
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('Applying filters to class $qualifiedName');
      }

      if (await _shouldIncludeClass(cls)) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('Class $qualifiedName included, creating pod definition');
        }
        
        final definition = _createPodDefinition(cls);
        if (definition != null) {
          _scannedClasses.add(qualifiedName);
          scannedDefinitions.add(definition);
        }
      }
    }
    
    return scannedDefinitions;
  }
  
  /// Determines if a class should be included based on filters and conditions
  /// 
  /// This method:
  /// 1. Checks exclude filters first
  /// 2. Checks include filters
  /// 3. Checks conditional annotations
  /// 
  /// ### Parameters
  /// - `cls`: The class to check.
  /// 
  /// ### Returns
  /// A boolean indicating whether the class should be included.
  /// 
  /// ### Example
  /// ```dart
  /// final scanner = ClassPathPodDefinitionScanner(conditionEvaluator, podFactory);
  /// final definitions = await scanner.doScan('com.example');
  /// ```
  Future<bool> _shouldIncludeClass(Class cls) async {
    // Check conditional annotations
    if (await conditionEvaluator.shouldInclude(cls)) {
      // Check exclude filters first
      for (final excludeFilter in excludeFilters) {
        excludeFilter.setEntryApplication(entryApplication);

        if (excludeFilter.matches(cls)) {
          return false;
        }
      }
      
      // Check include filters
      bool matchesIncludeFilter = includeFilters.isEmpty; // If no include filters, include by default
      for (final includeFilter in includeFilters) {
        includeFilter.setEntryApplication(entryApplication);

        if (includeFilter.matches(cls)) {
          matchesIncludeFilter = true;
          break;
        }
      }
      
      if (!matchesIncludeFilter) {
        return false;
      }

      return true;
    }
    
    return false;
  }
  
  /// Creates a pod definition for a scanned class
  /// 
  /// This method:
  /// 1. Creates a RootPodDefinition instance for the scanned class
  /// 2. Generates a pod name using AnnotatedPodNameGenerator
  /// 3. Resolves scope using AnnotatedScopeMetadataResolver
  /// 4. Processes common annotations using AnnotatedPodDefinitionReader
  /// 
  /// ### Parameters
  /// - `type`: The class to create a pod definition for.
  /// 
  /// ### Returns
  /// A RootPodDefinition instance for the scanned class, or null if an error occurs.
  /// 
  /// ### Example
  /// ```dart
  /// final scanner = ClassPathPodDefinitionScanner(conditionEvaluator, podFactory);
  /// final definitions = await scanner.doScan('com.example');
  /// ```
  RootPodDefinition? _createPodDefinition(Class type) {
    try {
      final definition = RootPodDefinition(type: type);
      
      // Generate pod name
      final podName = AnnotatedPodNameGenerator().generate(definition, podFactory);
      definition.name = podName;
      
      // Resolve scope
      ScopeDesign scopeMetadata = AnnotatedScopeMetadataResolver().resolveScopeDescriptor(definition.type);
      definition.scope = scopeMetadata;
      
      // Process common annotations
      AnnotatedPodDefinitionReader.processCommonDefinitionAnnotations(definition);
      
      return definition;
    } catch (e) {
      if(_logger.getIsErrorEnabled()) {
        _logger.error('Error creating pod definition for ${type.getName()}: $e');
      }

      return null;
    }
  }
  
  /// Checks if a method has already been scanned
  bool hasScannedMethod(Method method) {
    final signature = '${method.getDeclaringClass().getQualifiedName()}.${method.getName()}';
    return _scannedMethods.contains(signature);
  }
  
  /// Marks a method as scanned
  void markMethodScanned(Method method) {
    final signature = '${method.getDeclaringClass().getQualifiedName()}.${method.getName()}';
    _scannedMethods.add(signature);
  }
  
  /// Checks if a class has already been scanned
  bool hasScannedClass(Class cls) {
    return _scannedClasses.contains(cls.getQualifiedName());
  }
  
  /// Checks if a package has already been scanned
  bool hasScannedPackage(String packageName) {
    return _scannedPackages.contains(packageName);
  }
  
  /// Clears all scanned tracking data
  void clearScannedTracking() {
    _scannedClasses.clear();
    _scannedPackages.clear();
    _scannedMethods.clear();
  }
  
  /// Adds an include filter
  void addIncludeFilter(TypeFilter filter) {
    includeFilters.add(filter);
  }
  
  /// Adds an exclude filter
  void addExcludeFilter(TypeFilter filter) {
    excludeFilters.add(filter);
  }
  
  /// Clears all filters
  void clearFilters() {
    includeFilters.clear();
    excludeFilters.clear();
  }
  
  /// Sets custom scope resolver
  void setScopeResolver(ScopeMetadataResolver resolver) {
    scopeResolver = resolver;
  }
  
  /// Sets custom name generator
  void setNameGenerator(PodNameGenerator generator) {
    nameGenerator = generator;
  }
}