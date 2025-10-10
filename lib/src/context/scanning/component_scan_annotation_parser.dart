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
import '../../annotations/stereotype.dart';
import '../../condition/condition_evaluator.dart';
import 'class_path_pod_definition_scanner.dart';
import 'configuration_class.dart';

/// {@template component_scan_annotation_parser}
/// Parses @ComponentScan annotations and triggers classpath scanning.
/// 
/// This parser:
/// 1. Reads @ComponentScan-like annotations from a config class
/// 2. Triggers classpath scanning using Runtime.getAllLibraries()
/// 3. Applies include/exclude filters using TypeFilter mechanism
/// 4. Produces a list of PodDefinitions for discovered annotated classes
/// 5. Deduplicates scanned definitions to prevent duplicate registration
/// 
/// It is used by ConfigurationClassParser to process @ComponentScan annotations.
/// {@endtemplate}
final class ComponentScanAnnotationParser {
  /// The pod factory to use for configuration parsing
  final ConfigurableListablePodFactory podFactory;
  
  /// The environment to use for configuration parsing
  final Environment environment;

  /// The entry application class
  final Class<Object> entryApplication;
  
  /// The condition evaluator to use for configuration parsing
  final ConditionEvaluator conditionEvaluator;
  
  /// The classpath pod definition scanner to use for configuration parsing
  final ClassPathPodDefinitionScanner scanner;

  /// {@macro component_scan_annotation_parser}
  ComponentScanAnnotationParser(this.podFactory, this.environment, this.conditionEvaluator, this.entryApplication)
    : scanner = ClassPathPodDefinitionScanner(conditionEvaluator, podFactory, entryApplication);

  /// {@template parse_component_scan}
  /// Parses a component scan configuration and returns discovered pod definitions.
  /// 
  /// This method:
  /// 1. Determines base packages to scan
  /// 2. Configures include/exclude filters
  /// 3. Delegates to ClassPathPodDefinitionScanner for actual scanning
  /// 4. Deduplicates results by pod name
  /// 5. Returns list of discovered pod definitions
  /// {@endtemplate}
  Future<List<PodDefinition>> parse(ComponentScanConfiguration scanConfig, ConfigurationClass configClass) async {
    // Determine base packages to scan
    final basePackages = _resolveBasePackages(scanConfig, configClass);
    
    if (basePackages.isEmpty) {
      return [];
    }
    
    // Configure scanner with filters
    _configureScanner(scanConfig);
    
    final scannedDefinitionsMap = <String, PodDefinition>{};
    
    for (final basePackage in basePackages) {
      final packageDefinitions = await scanner.doScan(basePackage);
      
      for (final definition in packageDefinitions) {
        final podName = definition.name;
        if (!scannedDefinitionsMap.containsKey(podName)) {
          scannedDefinitionsMap[podName] = definition;
        }
      }
    }
    
    return scannedDefinitionsMap.values.toList();
  }
  
  /// Resolves the base packages to scan from the configuration
  /// 
  /// This method:
  /// 1. Adds explicitly specified base packages
  /// 2. Adds packages from base package classes
  /// 3. If no base packages specified, uses the package of the configuration class
  /// 
  /// ### Parameters
  /// - `scanConfig`: The component scan configuration to resolve base packages from.
  /// - `configClass`: The configuration class to use for resolving base packages.
  /// 
  /// ### Returns
  /// A list of base packages to scan.
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
  List<String> _resolveBasePackages(ComponentScanConfiguration scanConfig, ConfigurationClass configClass) {
    final basePackages = <String>[];
    
    // Add explicitly specified base packages
    basePackages.addAll(scanConfig.basePackages);
    
    // Add packages from base package classes
    for (final basePackageClass in scanConfig.basePackageClasses) {
      final packageName = basePackageClass.getPackage()?.getName();
      if (packageName != null && !basePackages.contains(packageName)) {
        basePackages.add(packageName);
      }
    }
    
    // If no base packages specified, use the package of the configuration class
    if (basePackages.isEmpty) {
      final configPackage = configClass.type.getPackage()?.getName();
      if (configPackage != null) {
        basePackages.add(configPackage);
      }
    }
    
    return basePackages.toSet().toList();
  }
  
  /// Configures the scanner with include/exclude filters
  /// 
  /// This method:
  /// 1. Clears existing filters
  /// 2. Adds default filters if enabled
  /// 3. Adds custom include filters
  /// 4. Adds custom exclude filters
  /// 5. Configures scope resolver if specified
  /// 
  /// ### Parameters
  /// - `scanConfig`: The component scan configuration to configure the scanner with.
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
  void _configureScanner(ComponentScanConfiguration scanConfig) {
    // Clear existing filters
    scanner.clearFilters();
    
    // Add default filters if enabled
    if (scanConfig.useDefaultFilters) {
      _addDefaultIncludeFilters();
    }
    
    // Add custom include filters
    for (final filter in scanConfig.includeFilters) {
      scanner.addIncludeFilter(filter);
    }
    
    // Add custom exclude filters
    for (final filter in scanConfig.excludeFilters) {
      scanner.addExcludeFilter(filter);
    }
    
    // Configure scope resolver if specified
    if (scanConfig.scopeResolver != null) {
      scanner.setScopeResolver(scanConfig.scopeResolver!);
    }
    
    // Configure name generator if specified
    if (scanConfig.nameGenerator != null) {
      scanner.setNameGenerator(scanConfig.nameGenerator!);
    }
  }
  
  /// Adds default include filters for standard component annotations
  /// 
  /// This method:
  /// 1. Adds @Component and its meta-annotations
  /// 2. Adds @Service and its meta-annotations
  /// 3. Adds @Repository and its meta-annotations
  /// 4. Adds @Controller and its meta-annotations
  /// 5. Adds @Configuration and its meta-annotations
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
  void _addDefaultIncludeFilters() {
    // @Component and its meta-annotations
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Component>(null, PackageNames.CORE)));
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Service>(null, PackageNames.CORE)));
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Repository>(null, PackageNames.CORE)));
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Controller>(null, PackageNames.CORE)));
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Configuration>(null, PackageNames.CORE)));
  }
}