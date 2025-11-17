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
import 'package:jetleaf_pod/pod.dart';

import '../../annotations/configuration.dart';
import '../../annotations/others.dart';
import '../../annotations/stereotype.dart';

/// {@template annotatedPodNameGenerator}
/// A Jetleaf-provided [PodNameGenerator] that derives pod names
/// from annotations such as `@Component` and `@Service`.
///
/// If a pod definition is annotated with one of these stereotypes,
/// its declared `value` will be used as the pod name.
/// If no name is explicitly provided, this generator falls back to
/// [SimplePodNameGenerator].
///
/// ### Key Features:
/// - Supports `@Component` and `@Service` annotations.
/// - Respects explicitly declared annotation values as pod names.
/// - Provides graceful fallback to the default name generator.
/// - Central to annotation-driven pod registration in Jetleaf.
///
/// ### Example:
/// ```dart
/// @Component('customRepo')
/// class UserRepository {}
///
/// @Service()
/// class UserService {}
///
/// void main() {
///   final registry = DefaultPodDefinitionRegistry();
///   final generator = AnnotatedPodNameGenerator();
///
///   final repoDef = RootPodDefinition(type: Class<UserRepository>());
///   final repoName = generator.generate(repoDef, registry);
///   print(repoName); // "customRepo"
///
///   final serviceDef = RootPodDefinition(type: Class<UserService>());
///   final serviceName = generator.generate(serviceDef, registry);
///   print(serviceName); // "userService" (fallback to simple generator)
/// }
/// ```
///
/// This generator allows for both explicit and convention-based naming
/// of pods in Jetleaf.
/// {@endtemplate}
final class AnnotatedPodNameGenerator implements PodNameGenerator {
  /// {@macro annotatedPodNameGenerator}
  const AnnotatedPodNameGenerator();

  @override
  String generate(PodDefinition definition, PodDefinitionRegistry registry) {
    if (definition is RootPodDefinition) {
      final name = determinePodNameFromAnnotation(definition);
      if (name != null) {
        return name;
      }
    }

    return SimplePodNameGenerator().generate(definition, registry);
  }

  /// Determines the pod name from annotations on the given [apd].
  ///
  /// - Checks for a `@Component` annotation first.
  /// - If none is found or its value is empty, checks for a `@Service` annotation.
  /// - Returns `null` if no name could be derived.
  ///
  /// ### Example:
  /// ```dart
  /// final def = RootPodDefinition(type: Class<UserService>());
  /// final name = generator.determinePodNameFromAnnotation(def);
  /// print(name); // null (falls back to simple generator)
  /// ```
  String? determinePodNameFromAnnotation(RootPodDefinition apd) {
    String? name;

    if (apd.type.hasDirectAnnotation<Component>()) {
      name = apd.type.getDirectAnnotation<Component>()?.value;
    }

    if (apd.type.hasDirectAnnotation<Service>()) {
      name ??= apd.type.getDirectAnnotation<Service>()?.value;
    }

    if (apd.type.hasDirectAnnotation<Configuration>()) {
      name ??= apd.type.getDirectAnnotation<Configuration>()?.value;
    }

    final named = apd.type.getDirectAnnotation<Named>();
    if (named != null) {
      name = named.name;
    }

    return name;
  }

  @override
  String getPackageName() => PackageNames.CORE;
}