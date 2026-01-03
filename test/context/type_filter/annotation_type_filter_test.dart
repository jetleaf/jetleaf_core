// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2026 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

// Test annotations
final class TestAnnotation {
  const TestAnnotation();
}

@Component()
final class MyComponent {}

final class AnotherAnnotation {
  const AnotherAnnotation();
}

// Test classes with annotations
@TestAnnotation()
final class AnnotatedClass {}

@AnotherAnnotation()
final class DifferentAnnotatedClass {}

final class NonAnnotatedClass {}

@TestAnnotation()
@AnotherAnnotation()
final class MultiAnnotatedClass {}

void main() {
  setUpAll(() async {
    await setupRuntime();
  });

  group('AnnotationTypeFilter', () {
    test('should match class with target annotation', () {
      final filter = AnnotationTypeFilter(Class<TestAnnotation>());
      final annotatedClass = Class<AnnotatedClass>();
      final nonAnnotatedClass = Class<NonAnnotatedClass>();

      expect(filter.matches(annotatedClass), isTrue);
      expect(filter.matches(nonAnnotatedClass), isFalse);
    });

    test('should not match class with different annotation', () {
      final filter = AnnotationTypeFilter(Class<TestAnnotation>());
      final differentClass = Class<DifferentAnnotatedClass>();

      expect(filter.matches(differentClass), isFalse);
    });

    test('should match class with multiple annotations', () {
      final testFilter = AnnotationTypeFilter(Class<TestAnnotation>());
      final anotherFilter = AnnotationTypeFilter(Class<AnotherAnnotation>());
      final multiClass = Class<MultiAnnotatedClass>();

      expect(testFilter.matches(multiClass), isTrue);
      expect(anotherFilter.matches(multiClass), isTrue);
    });

    test('should match with considerMetaAnnotations=true by default', () {
      final filter = AnnotationTypeFilter(
        Class<TestAnnotation>(),
        considerMetaAnnotations: true,
      );
      final annotatedClass = Class<AnnotatedClass>();

      expect(filter.matches(annotatedClass), isTrue);
    });

    test('should respect considerMetaAnnotations=false', () {
      final filter = AnnotationTypeFilter(
        Class<TestAnnotation>(),
        considerMetaAnnotations: false,
      );
      final annotatedClass = Class<AnnotatedClass>();

      expect(filter.matches(annotatedClass), isTrue);
    });

    test('should match Component annotation', () {
      final filter = AnnotationTypeFilter(Class<Component>(null, PackageNames.POD));
      
      final componentClass = Class<MyComponent>();
      expect(filter.matches(componentClass), isTrue);
    });
  });
}