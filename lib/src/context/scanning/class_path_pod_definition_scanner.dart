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

import '../../condition/condition_evaluator.dart';
import '../../scope/annotated_scope_metadata_resolver.dart';
import '../../scope/scope_metadata_resolver.dart';
import '../type_filters/type_filter.dart';
import 'annotated_pod_definition_reader.dart';
import 'annotated_pod_name_generator.dart';

/// {@template classpath_pod_definition_scanner}
/// Scans the classpath for pod definitions based on configured filters and conditions.
///
/// This scanner discovers classes in specified packages, applies include/exclude filters,
/// evaluates conditional annotations, and creates pod definitions for matching classes.
/// It maintains state to avoid duplicate scanning and provides configurable filtering
/// and naming strategies.
///
/// **Example:**
/// ```dart
/// final conditionEvaluator = ConditionEvaluator();
/// final podFactory = DefaultPodFactory();
/// final entryApp = Class<MyApplication>(null, 'package:example/test.dart');
/// 
/// final scanner = ClassPathPodDefinitionScanner(
///   conditionEvaluator,
///   podFactory,
///   entryApp
/// );
/// 
/// // Configure filters
/// scanner.addIncludeFilter(AnnotationTypeFilter(Class<Component>(null, PackageNames.CORE)));
/// scanner.addExcludeFilter(AnnotationTypeFilter(Class<Deprecated>(null, PackageNames.DART)));
/// 
/// // Scan package
/// final definitions = await scanner.doScan('package:example/test.dart');
/// print('Found ${definitions.length} pod definitions');
/// ```
/// {@endtemplate}
final class ClassPathPodDefinitionScanner {
  /// The condition evaluator to use for evaluating @Conditional annotations
  final ConditionEvaluator _conditionEvaluator;
  
  /// The pod factory to use for creating pod definitions
  final ConfigurableListablePodFactory _podFactory;

  /// The entry application class
  final Class<Object> _entryApplication;

  /// The logger to use for logging
  final Log _logger = LogFactory.getLog(ClassPathPodDefinitionScanner);
  
  /// Include filters for component scanning
  final List<TypeFilter> _includeFilters = [];
  
  /// Exclude filters for component scanning
  final List<TypeFilter> _excludeFilters = [];
  
  /// Custom scope resolver
  ScopeMetadataResolver? _scopeResolver;
  
  /// Custom name generator
  PodNameGenerator? _nameGenerator;

  /// Tracks already scanned classes by their qualified name
  final Set<String> _scannedClasses = {};
  
  /// Tracks already scanned packages
  final Set<String> _scannedPackages = {};
  
  /// Tracks already scanned methods by their qualified signature
  final Set<String> _scannedMethods = {};

  /// {@macro classpath_pod_definition_scanner}
  ClassPathPodDefinitionScanner(this._conditionEvaluator, this._podFactory, this._entryApplication);

  /// {@template doScan}
  /// Scans a base package for pod definitions.
  ///
  /// This method discovers all classes in the specified package, applies
  /// filters and conditions, and creates pod definitions for matching classes.
  /// It maintains scanning state to avoid duplicate processing.
  ///
  /// **Parameters:**
  /// - `basePackage`: The base package to scan
  ///
  /// **Returns:**
  /// - A list of [PodDefinition] instances discovered in the package
  ///
  /// **Example:**
  /// ```dart
  /// // Scan a single package
  /// final definitions = await scanner.doScan('package:example/test.dart.controllers');
  /// 
  /// // Scan multiple packages sequentially
  /// final controllerDefs = await scanner.doScan('package:example/test.dart.controllers');
  /// final serviceDefs = await scanner.doScan('package:example/test.dart.services');
  /// final allDefs = [...controllerDefs, ...serviceDefs];
  /// 
  /// // Scan with custom configuration
  /// scanner.setScopeResolver(CustomScopeResolver());
  /// scanner.setNameGenerator(CustomNameGenerator());
  /// final customDefs = await scanner.doScan('package:example/test.dart.custom');
  /// ```
  /// {@endtemplate}
  Future<List<PodDefinition>> doScan(String basePackage) async {
    if (_scannedPackages.contains(basePackage)) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('📦 Package [$basePackage] already scanned, skipping.');
      }

      return [];
    }

    _scannedPackages.add(basePackage);
    final scannedDefinitions = <PodDefinition>[];

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🚀 Starting component scan for package: [$basePackage]');
    }

    final libraries = Runtime.getAllLibraries().where((lib) => lib.getPackage().getName() == basePackage);
    final classes = libraries.flatMap((lib) => lib.getClasses()).toSet();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔍 Discovered ${classes.length} class(es) in package [$basePackage]');
    }

    int processed = 0;
    for (final classDecl in classes) {
      final cls = Class.declared(classDecl, ProtectionDomain.current());
      final qualifiedName = cls.getQualifiedName();

      if (Class<ReflectableAnnotation>(null, PackageNames.LANG).isAssignableFrom(cls)) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('↩️ Class [$qualifiedName] is a reflectable annotation, skipping.');
        }
        continue;
      }

      if (_scannedClasses.contains(qualifiedName)) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('↩️ Class [$qualifiedName] already processed, skipping.');
        }
        continue;
      }

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('⚙️ Evaluating class [$qualifiedName] against filters and conditions...');
      }

      if (await _shouldIncludeClass(cls)) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ Class [$qualifiedName] passed all filters, creating pod definition.');
        }

        final definition = _createPodDefinition(cls);
        _scannedClasses.add(qualifiedName);
        scannedDefinitions.add(definition);
        processed++;

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('📦 Created pod definition: [${definition.name}] → ${cls.getName()}');
        }
      } else {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🚫 Class [$qualifiedName] did not match include/exclude filters.');
        }
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🏁 Completed scan for [$basePackage]. Processed: $processed, Total definitions: ${scannedDefinitions.length}');
    }

    return scannedDefinitions;
  }

  /// {@macro shouldIncludeClass}
  /// Determines if a class should be included based on filters and conditions.
  ///
  /// This method evaluates conditional annotations first, then applies
  /// exclude filters, and finally include filters to determine if the
  /// class should be processed.
  ///
  /// **Parameters:**
  /// - `cls`: The class to evaluate
  ///
  /// **Returns:**
  /// - `true` if the class should be included, `false` otherwise
  Future<bool> _shouldIncludeClass(Class cls) async {
    // Check conditional annotations
    final className = cls.getQualifiedName();

    // Evaluate conditional annotations
    if (!await _conditionEvaluator.shouldInclude(cls)) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('⏩ Skipping [$className] due to failed condition evaluation.');
      }

      return false;
    }

    // Apply exclude filters first
    for (final excludeFilter in _excludeFilters) {
      excludeFilter.setEntryApplication(_entryApplication);
      if (excludeFilter.matches(cls)) {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🚫 Class [$className] excluded by ${excludeFilter.runtimeType}.');
        }

        return false;
      }
    }

    // Apply include filters
    bool matchesInclude = _includeFilters.isEmpty;
    for (final includeFilter in _includeFilters) {
      includeFilter.setEntryApplication(_entryApplication);
      if (includeFilter.matches(cls)) {
        matchesInclude = true;

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('✅ Class [$className] matched include filter ${includeFilter.runtimeType}.');
        }
        break;
      }
    }

    if (!matchesInclude) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🚫 Class [$className] did not match any include filters.');
      }

      return false;
    }

    return true;
  }
  
  /// {@macro createPodDefinition}
  /// Creates a pod definition for a scanned class.
  /// 
  /// This method:
  /// 1. Creates a RootPodDefinition instance for the scanned class
  /// 2. Generates a pod name using AnnotatedPodNameGenerator
  /// 3. Resolves scope using AnnotatedScopeMetadataResolver
  /// 4. Processes common annotations using AnnotatedPodDefinitionReader
  /// 
  /// **Parameters:**
  /// - `type`: The class to create a pod definition for.
  /// 
  /// **Returns:**
  /// A RootPodDefinition instance for the scanned class, or null if an error occurs.
  /// 
  /// **Example:**
  /// ```dart
  /// final scanner = ClassPathPodDefinitionScanner(conditionEvaluator, podFactory, entryApp);
  /// final definitions = await scanner.doScan('package:example/test.dart');
  /// ```
  RootPodDefinition _createPodDefinition(Class type) {
    final definition = RootPodDefinition(type: type);

    // Name generation
    final nameGenerator = _nameGenerator ?? AnnotatedPodNameGenerator();
    definition.name = nameGenerator.generate(definition, _podFactory);
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Assigned pod name "${definition.name}" to ${type.getQualifiedName()}');
    }

    // Scope resolution
    final resolver = _scopeResolver ?? AnnotatedScopeMetadataResolver();
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
  
  /// {@macro clearScannedTracking}
  /// Clears all scanned tracking data.
  ///
  /// This method resets the internal state tracking scanned classes,
  /// packages, and methods, allowing the scanner to be reused.
  void clearScannedTracking() {
    _scannedClasses.clear();
    _scannedPackages.clear();
    _scannedMethods.clear();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧹 Cleared all scanned tracking data.');
    }
  }
  
  /// {@macro addIncludeFilter}
  /// Adds an include filter.
  ///
  /// **Parameters:**
  /// - `filter`: The type filter to add for inclusion
  void addIncludeFilter(TypeFilter filter) {
    _includeFilters.add(filter);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('➕ Added include filter: ${filter.runtimeType}');
    }
  }
  
  /// {@macro addExcludeFilter}
  /// Adds an exclude filter.
  ///
  /// **Parameters:**
  /// - `filter`: The type filter to add for exclusion
  void addExcludeFilter(TypeFilter filter) {
    _excludeFilters.add(filter);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🚫 Added exclude filter: ${filter.runtimeType}');
    }
  }
  
  /// {@macro clearFilters}
  /// Clears all filters.
  void clearFilters() {
    _includeFilters.clear();
    _excludeFilters.clear();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧽 Cleared all include and exclude filters.');
    }
  }
  
  /// {@macro setScopeResolver}
  /// Sets custom scope resolver.
  ///
  /// **Parameters:**
  /// - `resolver`: The scope resolver to use
  void setScopeResolver(ScopeMetadataResolver resolver) {
    _scopeResolver = resolver;

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('📘 Custom scope resolver set: ${resolver.runtimeType}');
    }
  }
  
  /// {@macro setNameGenerator}
  /// Sets custom name generator.
  ///
  /// **Parameters:**
  /// - `generator`: The name generator to use
  void setNameGenerator(PodNameGenerator generator) {
    _nameGenerator = generator;

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧠 Custom name generator set: ${generator.runtimeType}');
    }
  }
}