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

import '../annotations/others.dart';
import 'scope_metadata_resolver.dart';

/// {@template annotatedScopeMetadataResolver}
/// A Jetleaf-provided implementation of [ScopeMetadataResolver] that
/// determines scope metadata based on the presence of the `@Scope` annotation.
///
/// If a class is annotated with `@Scope`, its declared value will be used
/// as the lifecycle scope (e.g., `"singleton"`, `"prototype"`, `"request"`).
/// If no annotation is found, the default scope `"singleton"` is applied.
///
/// ### Key Features:
/// - Honors custom scope definitions declared with `@Scope`.
/// - Provides sensible defaults (singleton scope).
/// - Lightweight and efficient — only inspects annotations.
///
/// ### Example:
/// ```dart
/// @Scope('prototype')
/// class PrototypeService {}
///
/// void main() {
///   final resolver = AnnotatedScopeMetadataResolver();
///
///   final scope1 = resolver.resolve(Class<PrototypeService>());
///   print(scope1); // "prototype"
///
///   final scope2 = resolver.resolve(Class<Object>());
///   print(scope2); // "singleton"
/// }
/// ```
///
/// This resolver is the **default choice** in Jetleaf when using annotation-driven configuration.
/// {@endtemplate}
final class AnnotatedScopeMetadataResolver implements ScopeMetadataResolver {
  /// {@macro annotatedScopeMetadataResolver}
  const AnnotatedScopeMetadataResolver();

  @override
  String resolve(Class classType) {
    if (classType.hasDirectAnnotation<Scope>()) {
      final scope = classType.getDirectAnnotation<Scope>();
      if (scope != null) {
        return scope.value;
      }
    }
    
    return 'singleton';
  }

  @override
  ScopeDesign resolveScopeDescriptor(Class classType) {
    if (classType.hasDirectAnnotation<Scope>()) {
      final scope = classType.getDirectAnnotation<Scope>();
      if (scope != null) {
        return ScopeDesign.type(scope.value);
      }
    }
    
    return ScopeDesign.type(ScopeType.SINGLETON.name);
  }
}