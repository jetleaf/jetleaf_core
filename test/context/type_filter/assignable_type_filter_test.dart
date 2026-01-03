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

// Test interfaces and base classes
abstract class Cache {
  void put(String key, Object value);
  Object? get(String key);
}

abstract class Repository<T> {
  Future<T?> findById(String id);
}

abstract class Service {}

// Test implementations
final class MemoryCache implements Cache {
  @override
  void put(String key, Object value) {}
  
  @override
  Object? get(String key) => null;
}

final class UserRepository implements Repository<String> {
  @override
  Future<String?> findById(String id) async => null;
}

final class UserService implements Service {}

final class PlainClass {}

void main() {
  setUpAll(() async {
    await setupRuntime();
  });

  group('AssignableTypeFilter', () {
    test('should match class implementing target interface', () {
      final filter = AssignableTypeFilter(Class<Cache>());
      final memoryCacheClass = Class<MemoryCache>();
      final plainClass = Class<PlainClass>();

      expect(filter.matches(memoryCacheClass), isTrue);
      expect(filter.matches(plainClass), isFalse);
    });

    test('should match class implementing generic interface', () {
      final filter = AssignableTypeFilter(Class<Repository>());
      final repoClass = Class<UserRepository>();
      final plainClass = Class<PlainClass>();

      expect(filter.matches(repoClass), isTrue);
      expect(filter.matches(plainClass), isFalse);
    });

    test('should match class implementing Service', () {
      final filter = AssignableTypeFilter(Class<Service>());
      final serviceClass = Class<UserService>();
      final cacheClass = Class<MemoryCache>();

      expect(filter.matches(serviceClass), isTrue);
      expect(filter.matches(cacheClass), isFalse);
    });

    test('should match same class type', () {
      final filter = AssignableTypeFilter(Class<PlainClass>());
      final plainClass = Class<PlainClass>();

      expect(filter.matches(plainClass), isTrue);
    });

    test('should not match unrelated classes', () {
      final filter = AssignableTypeFilter(Class<Cache>());
      final serviceClass = Class<UserService>();
      final repoClass = Class<UserRepository>();

      expect(filter.matches(serviceClass), isFalse);
      expect(filter.matches(repoClass), isFalse);
    });
  });
}