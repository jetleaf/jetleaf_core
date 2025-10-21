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

import '../../annotations/configuration.dart';
import '../../annotations/stereotype.dart';
import '../type_filters/annotation_type_filter.dart';
import 'class_path_pod_definition_scanner.dart';
import 'configuration_class.dart';

/// {@template componentScanAnnotationParser}
/// Parser for [@ComponentScan] annotation that discovers and processes pod definitions
/// from specified package locations with configurable filtering and scanning options.
///
/// This parser handles component scanning configuration, including base package resolution,
/// filter application, and duplicate detection. It works with [ClassPathPodDefinitionScanner]
/// to perform the actual classpath scanning and pod definition discovery.
///
/// **Example:**
/// ```dart
/// final scanner = ClassPathPodDefinitionScanner();
/// final parser = ComponentScanAnnotationParser(scanner);
///
/// // Parse component scan configuration
/// final scanConfig = ComponentScanConfiguration(
///   basePackages: ['package:jetleaf_framework/src/runtime/jet_runtime_scan.dart'],
///   basePackageClasses: [Application],
///   useDefaultFilters: true,
///   includeFilters: [AnnotationTypeFilter(CustomComponent)],
///   excludeFilters: [AnnotationTypeFilter(Deprecated)]
/// );
///
/// final podDefinitions = await parser.parse(scanConfig);
/// print('Discovered ${podDefinitions.length} pod definitions');
/// ```
/// {@endtemplate}
final class ComponentScanAnnotationParser {
  final Log _logger = LogFactory.getLog(ComponentScanAnnotationParser);
  
  /// The classpath pod definition scanner to use for configuration parsing.
  final ClassPathPodDefinitionScanner scanner;

  /// {@macro componentScanAnnotationParser}
  ComponentScanAnnotationParser(this.scanner);

  /// {@template parseComponentScan}
  /// Parses component scan configuration and discovers pod definitions.
  ///
  /// This method resolves base packages, configures the scanner with appropriate
  /// filters, performs the actual scanning, and returns unique pod definitions
  /// across all scanned packages.
  ///
  /// **Parameters:**
  /// - `scanConfig`: The component scan configuration specifying packages and filters
  ///
  /// **Returns:**
  /// - A list of unique [PodDefinition] instances discovered during scanning
  ///
  /// **Example:**
  /// ```dart
  /// final parser = ComponentScanAnnotationParser(scanner);
  ///
  /// // Scan with multiple base packages
  /// final definitions = await parser.parse(ComponentScanConfiguration(
  ///   basePackages: ['package:jetleaf_framework/src/runtime/jet_runtime_scan.dart', 'package:jetleaf_framework/src/runtime/jet_runtime_scan.dart'],
  ///   useDefaultFilters: true
  /// ));
  ///
  /// // Scan with base package classes
  /// final definitions = await parser.parse(ComponentScanConfiguration(
  ///   basePackageClasses: [MainApplication, ConfigClass],
  ///   includeFilters: [AnnotationTypeFilter(RestController)]
  /// ));
  ///
  /// // Scan with custom filters only
  /// final definitions = await parser.parse(ComponentScanConfiguration(
  ///   basePackages: ['package:jetleaf_framework/src/runtime/jet_runtime_scan.dart'],
  ///   useDefaultFilters: false,
  ///   includeFilters: [AnnotationTypeFilter(MyCustomAnnotation)]
  /// ));
  /// ```
  /// {@endtemplate}
  Future<List<PodDefinition>> parse(ComponentScanConfiguration scanConfig) async {
    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔍 Starting component scan parsing for configuration: $scanConfig');
    }

    // Resolve base packages
    final basePackages = _resolveBasePackages(scanConfig);

    if (basePackages.isEmpty) {
      if (_logger.getIsWarnEnabled()) {
        _logger.warn('⚠️ No base packages found in $scanConfig — skipping component scan.');
      }
      return [];
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('📦 Resolved ${basePackages.length} base package(s): $basePackages');
    }

    // Configure scanner
    _configureScanner(scanConfig);

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('⚙️ Scanner configured with '
          '${scanConfig.includeFilters.length} include filter(s), '
          '${scanConfig.excludeFilters.length} exclude filter(s), '
          'useDefaultFilters=${scanConfig.useDefaultFilters}');
    }

    final scannedDefinitions = <PodDefinition>[];
    int totalDiscovered = 0;

    for (final basePackage in basePackages) {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🚀 Scanning package: $basePackage');
      }

      final packageDefinitions = await scanner.doScan(basePackage);

      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ Found ${packageDefinitions.length} candidate(s) in package: $basePackage');
      }

      for (final definition in packageDefinitions) {
        final podName = definition.name;

        scannedDefinitions.add(definition);
        totalDiscovered++;

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('📦 Registered pod definition: $podName (${definition.type})');
        }
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧭 Component scan complete. Total discovered: $totalDiscovered');
    }

    return scannedDefinitions;
  }
  
  /// {@macro resolveBasePackages}
  /// Resolves base packages from component scan configuration.
  ///
  /// This method combines explicitly specified base packages with packages
  /// derived from base package classes, ensuring unique package names.
  ///
  /// **Parameters:**
  /// - `scanConfig`: The component scan configuration
  ///
  /// **Returns:**
  /// - A list of unique base package names to scan
  List<String> _resolveBasePackages(ComponentScanConfiguration scanConfig) {
    final basePackages = <String>[];

    basePackages.addAll(scanConfig.basePackages);

    for (final basePackageClass in scanConfig.basePackageClasses) {
      final packageName = basePackageClass.getPackage()?.getName();
      if (packageName != null && !basePackages.contains(packageName)) {
        basePackages.add(packageName);
      }
    }

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧩 Base packages resolved: $basePackages');
    }

    return basePackages.toSet().toList();
  }
  
  /// {@macro configureScanner}
  /// Configures the scanner with filters and resolvers from scan configuration.
  ///
  /// This method applies default filters, custom include/exclude filters,
  /// and configures scope resolver and name generator if specified.
  ///
  /// **Parameters:**
  /// - `scanConfig`: The component scan configuration
  void _configureScanner(ComponentScanConfiguration scanConfig) {
    // Clear existing filters
    scanner.clearFilters();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🧹 Cleared existing scanner filters.');
    }

    if (scanConfig.useDefaultFilters) {
      _addDefaultIncludeFilters();
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ Default include filters applied.');
      }
    }

    for (final filter in scanConfig.includeFilters) {
      scanner.addIncludeFilter(filter);
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('➕ Added include filter: $filter');
      }
    }

    for (final filter in scanConfig.excludeFilters) {
      scanner.addExcludeFilter(filter);
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🚫 Added exclude filter: $filter');
      }
    }

    if (scanConfig.scopeResolver != null) {
      scanner.setScopeResolver(scanConfig.scopeResolver!);
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('📘 Custom scope resolver configured: ${scanConfig.scopeResolver}');
      }
    }

    if (scanConfig.nameGenerator != null) {
      scanner.setNameGenerator(scanConfig.nameGenerator!);
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('🧠 Custom name generator configured: ${scanConfig.nameGenerator}');
      }
    }
  }
  
  /// {@macro addDefaultIncludeFilters}
  /// Adds default include filters for common component annotations.
  ///
  /// This method configures the scanner to include classes annotated with
  /// common stereotypes like [@Component], [@Service], [@Repository],
  /// [@Controller], and [@Configuration].
  void _addDefaultIncludeFilters() {
    // @Component and its meta-annotations
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Component>(null, PackageNames.CORE)));
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Service>(null, PackageNames.CORE)));
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Repository>(null, PackageNames.CORE)));
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Controller>(null, PackageNames.CORE)));
    scanner.addIncludeFilter(AnnotationTypeFilter(Class<Configuration>(null, PackageNames.CORE)));
  }
}