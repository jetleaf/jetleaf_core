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

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../annotation_aware_order_comparator.dart';
import '../aware.dart';
import 'application_context.dart';

/// {@template application_conversion_service}
/// A JetLeaf-managed, application-wide **conversion service** responsible for
/// managing and coordinating all registered type converters.
///
/// The [ApplicationConversionService] acts as the central conversion hub used
/// by the framework to translate between data types — particularly during:
/// - Property binding (e.g., environment → configuration)
/// - Method parameter resolution
/// - Serialization and deserialization processes
/// - Dynamic value adaptation in pods and components
///
/// This class extends [SimpleConversionService], automatically pre-registering
/// all JetLeaf-provided default converters via [DefaultConversionService],
/// and integrates with the application lifecycle as both:
/// - a [SmartInitializingSingleton] (for eager initialization after context setup), and
/// - an [ApplicationContextAware] (for contextual access to the running environment).
///
/// ### Initialization Behavior
/// During context startup:
/// 1. Default converters are loaded via [DefaultConversionService.addDefaultConverters].
/// 2. All [ConversionServiceConfigurer] pods are discovered from the
///    [ApplicationContext].
/// 3. Each configurer is sorted using [AnnotationAwareOrderComparator]
///    to ensure predictable configuration order.
/// 4. Their [ConversionServiceConfigurer.configure] methods are invoked to
///    register custom converters into this instance.
///
/// ### Lifecycle Integration
/// This service participates in the JetLeaf pod lifecycle:
/// - Declared as a **singleton** and available application-wide.
/// - Automatically invoked during the “post-pod-initialization” phase through
///   [SmartInitializingSingleton.onSingletonReady].
///
/// ### Order and Priority
/// Implements [PriorityOrdered] to ensure it initializes *after* all high-priority
/// system components but *before* low-level late initializers.
///
/// Returns [Ordered.LOWEST_PRECEDENCE] by default, allowing user-defined
/// conversion services (if any) to take precedence.
///
/// ### Example
/// ```dart
/// @Configuration("app.conversion")
/// final class AppConversionConfiguration {
///   @Pod("app.conversion.custom")
///   ConversionServiceConfigurer customConverters() => CustomConversionConfigurer();
/// }
///
/// final class CustomConversionConfigurer implements ConversionServiceConfigurer {
///   @override
///   void configure(ConverterRegistry registry) {
///     registry.addConverter(StringToEnumConverter());
///     registry.addConverter(DateTimeToStringConverter());
///   }
/// }
/// ```
///
/// The above setup ensures that all registered converters are
/// automatically integrated into the active [ApplicationConversionService].
///
/// ### Design Notes
/// - Provides a consistent, extensible conversion layer across JetLeaf subsystems.
/// - Plays a key role in property resolution, annotation processing,
///   and validation subsystems.
/// - Encourages modular, declarative converter registration.
/// - Can be extended or replaced if specialized conversion logic is required.
///
/// ### See Also
/// - [ConversionService]
/// - [SimpleConversionService]
/// - [DefaultConversionService]
/// - [ConversionServiceConfigurer]
/// - [ConverterRegistry]
/// - [ApplicationContext]
/// {@endtemplate}
class ApplicationConversionService extends SimpleConversionService implements SmartInitializingSingleton, ApplicationContextAware, PriorityOrdered {
  /// The current JetLeaf [ApplicationContext].
  ///
  /// Provides access to:
  /// - Registered pods and configuration pods.
  /// - The active [Environment] and runtime profiles.
  /// - Application event broadcasting and lifecycle management.
  late ApplicationContext _applicationContext;

  /// {@macro application_conversion_service}
  ///
  /// Initializes the conversion service by registering JetLeaf’s built-in
  /// default converters. Errors during this phase are silently ignored to
  /// maintain startup resilience.
  ApplicationConversionService() {
    try {
      DefaultConversionService.addDefaultConverters(this);
    } catch (_) { }
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE;

  @override
  String getPackageName() => PackageNames.CORE;

  @override
  Future<void> onSingletonReady() async {
    final type = Class<ConversionServiceConfigurer>(null, PackageNames.CORE);
    final pods = await _applicationContext.getPodsOf(type, allowEagerInit: true);

    if (pods.isNotEmpty) {
      final configurers = List<ConversionServiceConfigurer>.from(pods.values);
      AnnotationAwareOrderComparator.sort(configurers);

      for (final configurer in configurers) {
        configurer.configure(this);
      }
    }
  }
}

/// {@template jetleaf_conversion_service_configurer}
/// A JetLeaf **extension interface** for programmatically configuring
/// type conversion within the application’s [ConversionService].
///
/// Implementations of this interface allow registration of custom
/// [Converter], [ConverterFactory], or [GenericConverter] instances into the
/// active [ConverterRegistry].
///
/// ### Purpose
/// - Centralize conversion logic across application modules.
/// - Enable declarative or programmatic registration of type converters.
/// - Extend the default JetLeaf conversion system with domain-specific
///   or environment-aware converters.
///
/// ### Example
/// ```dart
/// final class CustomConversionConfigurer implements ConversionServiceConfigurer {
///   @override
///   void configure(ConverterRegistry registry) {
///     registry.addConverter(StringToDateTimeConverter());
///     registry.addConverterFactory(EnumToStringConverterFactory());
///   }
/// }
/// ```
///
/// ### Usage
/// Custom configurers are typically declared as pods inside a JetLeaf
/// configuration class:
/// ```dart
/// @Configuration("app.conversion.config")
/// final class AppConversionConfiguration {
///   @Pod("app.conversion.custom")
///   ConversionServiceConfigurer customConfigurer() => CustomConversionConfigurer();
/// }
/// ```
///
/// During application startup, all discovered [ConversionServiceConfigurer]
/// pods are invoked to contribute to the shared [ConversionService].
///
/// ### Design Notes
/// - Provides a **hook** for modules to extend core type conversion behavior.
/// - Promotes modular, reusable, and testable conversion logic.
/// - Works closely with JetLeaf’s conversion infrastructure in
///   `jetleaf_core.convert`.
///
/// ### See Also
/// - [ConverterRegistry]
/// - [Converter]
/// - [ConversionService]
/// - [ConverterFactory]
/// - [GenericConverter]
/// {@endtemplate}
abstract interface class ConversionServiceConfigurer {
  /// Configures the application-wide [ConverterRegistry] by registering
  /// custom converters, converter factories, or generic converters.
  ///
  /// This method is invoked automatically during context initialization
  /// by the JetLeaf [ConversionService] builder.
  ///
  /// ### Example
  /// ```dart
  /// void configure(ConverterRegistry registry) {
  ///   registry.addConverter(StringToIntConverter());
  /// }
  /// ```
  void configure(ConverterRegistry registry);
}