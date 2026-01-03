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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

// Test classes with various naming patterns
final class UserController {}
final class UserService {}
final class UserServiceTest {}
final class StringUtils {}
final class DatabaseHelper {}
final class MyCustomImpl {}

void main() {
  setUpAll(() async {
    await setupRuntime();
  });

  group('RegexPatternTypeFilter', () {
    test('should match classes ending with Controller', () {
      final filter = RegexPatternTypeFilter(RegExp(r'Controller$'));
      final controllerClass = Class<UserController>();
      final serviceClass = Class<UserService>();

      expect(filter.matches(controllerClass), isTrue);
      expect(filter.matches(serviceClass), isFalse);
    });

    test('should match classes ending with Test', () {
      final filter = RegexPatternTypeFilter(RegExp(r'Test$'));
      final testClass = Class<UserServiceTest>();
      final serviceClass = Class<UserService>();

      expect(filter.matches(testClass), isTrue);
      expect(filter.matches(serviceClass), isFalse);
    });

    test('should match classes with Utils or Helper suffix', () {
      final filter = RegexPatternTypeFilter(RegExp(r'(Utils?|Helper)$'));
      final utilsClass = Class<StringUtils>();
      final helperClass = Class<DatabaseHelper>();
      final serviceClass = Class<UserService>();

      expect(filter.matches(utilsClass), isTrue);
      expect(filter.matches(helperClass), isTrue);
      expect(filter.matches(serviceClass), isFalse);
    });

    test('should match classes with Impl suffix', () {
      final filter = RegexPatternTypeFilter(RegExp(r'Impl$'));
      final implClass = Class<MyCustomImpl>();
      final serviceClass = Class<UserService>();

      expect(filter.matches(implClass), isTrue);
      expect(filter.matches(serviceClass), isFalse);
    });

    test('should support case-insensitive matching', () {
      final filter = RegexPatternTypeFilter(RegExp(r'service', caseSensitive: false));
      final serviceClass = Class<UserService>();
      final utilsClass = Class<StringUtils>();

      expect(filter.matches(serviceClass), isTrue);
      expect(filter.matches(utilsClass), isFalse);
    });
  });
}