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

import 'package:jetleaf_core/message.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

class TestMessageLoader extends MessageSourceLoader {
  @override
  Future<Map<String, String>> load(AssetPathResource resource) async {
    return {'test.message': 'Test message'};
  }
}

void main() {
  group('MessageSourceLoader', () {
    late TestMessageLoader loader;

    setUp(() {
      loader = TestMessageLoader();
    });

    test('should flatten simple map', () {
      final nested = {
        'key1': 'value1',
        'key2': 'value2',
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals(nested));
    });

    test('should flatten nested map with dot notation', () {
      final nested = {
        'parent': {
          'child': {
            'grandchild': 'value'
          }
        }
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'parent.child.grandchild': 'value'
      }));
    });

    test('should flatten map with mixed types', () {
      final nested = {
        'string': 'value',
        'number': 42,
        'boolean': true,
        'nullValue': null,
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'string': 'value',
        'number': '42',
        'boolean': 'true',
        'nullValue': 'null',
      }));
    });

    test('should flatten map with array of primitives', () {
      final nested = {
        'array': ['item1', 'item2', 'item3'],
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'array[0]': 'item1',
        'array[1]': 'item2',
        'array[2]': 'item3',
      }));
    });

    test('should flatten map with array of objects', () {
      final nested = {
        'users': [
          {'name': 'John', 'age': 30},
          {'name': 'Jane', 'age': 25},
        ],
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'users[0].name': 'John',
        'users[0].age': '30',
        'users[1].name': 'Jane',
        'users[1].age': '25',
      }));
    });

    test('should flatten with custom prefix', () {
      final nested = {
        'child': 'value',
      };

      final flattened = loader.flattenMap(nested, prefix: 'parent');
      
      expect(flattened, equals({
        'parent.child': 'value',
      }));
    });

    test('should handle empty map', () {
      final flattened = loader.flattenMap({});
      
      expect(flattened, isEmpty);
    });

    test('should handle map with empty arrays', () {
      final nested = {
        'emptyArray': [],
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, isEmpty);
    });

    test('should handle complex nested structure', () {
      final nested = {
        'app': {
          'name': 'MyApp',
          'version': '1.0.0',
          'settings': {
            'theme': 'dark',
            'language': 'en',
          },
          'users': [
            {
              'id': 1,
              'name': 'Alice',
              'permissions': ['read', 'write'],
            },
            {
              'id': 2,
              'name': 'Bob',
              'permissions': ['read'],
            },
          ],
        },
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'app.name': 'MyApp',
        'app.version': '1.0.0',
        'app.settings.theme': 'dark',
        'app.settings.language': 'en',
        'app.users[0].id': '1',
        'app.users[0].name': 'Alice',
        'app.users[0].permissions[0]': 'read',
        'app.users[0].permissions[1]': 'write',
        'app.users[1].id': '2',
        'app.users[1].name': 'Bob',
        'app.users[1].permissions[0]': 'read',
      }));
    });

    test('should handle array with mixed types', () {
      final nested = {
        'mixed': [
          'string',
          42,
          true,
          null,
          {'nested': 'object'},
        ],
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'mixed[0]': 'string',
        'mixed[1]': '42',
        'mixed[2]': 'true',
        'mixed[3]': 'null',
        'mixed[4].nested': 'object',
      }));
    });

    test('should handle very deep nesting', () {
      final nested = {
        'level1': {
          'level2': {
            'level3': {
              'level4': {
                'value': 'deep',
              },
            },
          },
        },
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'level1.level2.level3.level4.value': 'deep',
      }));
    });

    test('should handle keys with dots', () {
      final nested = {
        'key.with.dots': 'value',
        'normal': {
          'nested.with.dots': 'nested value',
        },
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'key.with.dots': 'value',
        'normal.nested.with.dots': 'nested value',
      }));
    });

    test('should handle keys with special characters', () {
      final nested = {
        'key-with-dashes': 'dash value',
        'key_with_underscores': 'underscore value',
        'keyWithCamelCase': 'camel value',
        'key with spaces': 'space value',
      };

      final flattened = loader.flattenMap(nested);
      
      expect(flattened, equals({
        'key-with-dashes': 'dash value',
        'key_with_underscores': 'underscore value',
        'keyWithCamelCase': 'camel value',
        'key with spaces': 'space value',
      }));
    });
  });
}