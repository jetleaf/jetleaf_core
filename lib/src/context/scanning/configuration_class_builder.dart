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
import '../../scope/annotated_scope_metadata_resolver.dart';
import '../../scope/scope_metadata_resolver.dart';
import 'annotated_pod_name_generator.dart';
import 'configuration_class.dart';

/// {@macro processingClasses}
/// Set of classes currently being processed for cycle detection.
///
/// This prevents infinite recursion when configuration classes have
/// circular dependencies or self-references during parsing.
final Set<Class> _processingClasses = {};

/// {@template configurationClassBuilder}
/// Parser for configuration classes that processes pod definitions and converts them
/// into [ConfigurationClass] instances with proper annotation handling and validation.
///
/// This parser handles the detection and processing of configuration classes
/// annotated with [@Configuration] or [@AutoConfiguration], extracting metadata
/// such as proxy behavior, scope resolution, and pod naming. It includes
/// cycle detection to prevent infinite recursion during configuration processing.
///
/// **Example:**
/// ```dart
/// final factory = DefaultPodFactory();
/// final parser = ConfigurationClassBuilder(factory);
///
/// // Parse a configuration class definition
/// final configClass = await parser.parse(PodDefinition(
///   type: MyConfigurationClass,
///   annotations: [Configuration(proxyPodMethods: true)]
/// ));
///
/// if (configClass != null) {
///   print('Configuration class parsed: ${configClass.podName}');
/// }
/// ```
/// {@endtemplate}
final class ConfigurationClassBuilder {
  final Log _logger = LogFactory.getLog(ConfigurationClassBuilder);

  /// The pod factory to use for configuration parsing and pod name generation.
  final ConfigurableListablePodFactory podFactory;

  /// {@macro configurationClassBuilder}
  ConfigurationClassBuilder(this.podFactory);

  /// {@template parse_configuration_class}
  /// Parses a pod definition into a [ConfigurationClass] if it represents a configuration.
  /// 
  /// This method processes configuration annotations, determines proxy behavior,
  /// resolves scope metadata, and generates appropriate pod names. It includes
  /// cycle detection to prevent infinite recursion during configuration processing.
  /// 
  /// **Parameters:**
  /// - `definition`: The pod definition to parse.
  /// 
  /// **Returns:**
  /// A [ConfigurationClass] instance if the class is a configuration class, or null otherwise.
  /// 
  /// **Example:**
  /// ```dart
  /// final factory = DefaultPodFactory();
  /// final parser = ConfigurationClassBuilder(factory);
  ///
  /// // Parse configuration with custom proxy behavior
  /// final configClass = await parser.parse(PodDefinition(
  ///   type: DatabaseConfiguration,
  ///   annotations: [Configuration(proxyPodMethods: false)]
  /// ));
  /// 
  /// // Parse auto-configuration class
  /// final autoConfigClass = await parser.parse(PodDefinition(
  ///   type: SecurityAutoConfiguration,
  ///   annotations: [AutoConfiguration()]
  /// ));
  /// 
  /// // Parse with custom scope resolver
  /// final scopedConfigClass = await parser.parse(PodDefinition(
  ///   type: RequestScopedConfiguration,
  ///   annotations: [Configuration(scopeResolver: RequestScopeResolver())]
  /// ));
  /// ```
  /// {@endtemplate}
  Future<ConfigurationClass?> build(PodDefinition definition) async {
    final type = definition.type;
    final qualifiedName = type.getQualifiedName();

    if (_logger.getIsTraceEnabled()) {
      _logger.trace('🔍 Parsing configuration class candidate: $qualifiedName');
    }

    // Detect recursive parsing
    if (_processingClasses.contains(type) ||
        _processingClasses.any((e) => e.getQualifiedName().equals(qualifiedName))) {
      if (_logger.getIsWarnEnabled()) {
        _logger.warn('⚠️ Cycle detected while parsing $qualifiedName — skipping to prevent recursion.');
      }
      return null;
    }

    _processingClasses.add(type);

    try {
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('➡️ Processing configuration annotations for $qualifiedName');
      }

      // Determine proxy semantics
      bool proxyPodMethods = true;
      if (definition.hasAnnotation<Configuration>()) {
        final configAnn = definition.getAnnotation<Configuration>()!;
        proxyPodMethods = configAnn.proxyPodMethods;

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🧩 @Configuration found on $qualifiedName (proxyPodMethods=$proxyPodMethods)');
        }
      } else if (definition.hasAnnotation<AutoConfiguration>()) {
        final autoConfigAnn = definition.getAnnotation<AutoConfiguration>()!;
        proxyPodMethods = autoConfigAnn.proxyPodMethods;

        if (_logger.getIsTraceEnabled()) {
          _logger.trace('⚙️ @AutoConfiguration found on $qualifiedName (proxyPodMethods=$proxyPodMethods)');
        }
      } else {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('ℹ️ $qualifiedName has no @Configuration or @AutoConfiguration annotation.');
        }
      }

      // Determine scope resolver semantics
      ScopeMetadataResolver? scopeMetadataResolver;
      if (definition.hasAnnotation<Configuration>()) {
        scopeMetadataResolver = definition.getAnnotation<Configuration>()?.scopeResolver;
      } else if (definition.hasAnnotation<AutoConfiguration>()) {
        scopeMetadataResolver = definition.getAnnotation<AutoConfiguration>()?.scopeResolver;
      }

      if (_logger.getIsTraceEnabled()) {
        final resolverName = scopeMetadataResolver?.runtimeType ?? AnnotatedScopeMetadataResolver;
        _logger.trace('🔧 Scope resolver for $qualifiedName: $resolverName');
      }

      // Determine pod name
      String podName = definition.name;
      if (podName.isEmpty) {
        podName = AnnotatedPodNameGenerator().generate(definition, podFactory);
        definition.name = podName;
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🏷️ Generated pod name for $qualifiedName → $podName');
        }
      } else {
        if (_logger.getIsTraceEnabled()) {
          _logger.trace('🏷️ Using existing pod name for $qualifiedName → $podName');
        }
      }

      final resolvedScope = scopeMetadataResolver ?? AnnotatedScopeMetadataResolver();
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('✅ Successfully parsed configuration class: $qualifiedName');
      }

      return ConfigurationClass(podName, type, definition, proxyPodMethods, resolvedScope);
    } catch (e, stack) {
      if (_logger.getIsErrorEnabled()) {
        _logger.error('❌ Error parsing configuration class $qualifiedName: $e\n$stack');
      }
      rethrow;
    } finally {
      _processingClasses.remove(type);
      if (_logger.getIsTraceEnabled()) {
        _logger.trace('↩️ Finished processing configuration class: $qualifiedName');
      }
    }
  }
}