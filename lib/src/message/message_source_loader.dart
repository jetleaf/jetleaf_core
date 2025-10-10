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

/// {@template message_loader}
/// Interface for loading messages from different resource formats.
/// 
/// This abstraction allows the MessageSource system to support multiple
/// file formats (JSON, YAML, Properties) through pluggable loaders.
/// Each loader is responsible for parsing its specific format and
/// returning a flat map of message keys to values.
/// 
/// ### Example implementation:
/// ```dart
/// class JsonMessageLoader implements MessageSourceLoader {
///   @override
///   Future<Map<String, String>> load(AssetPathResource resource) async {
///     final parser = JsonParser();
///     final data = parser.parse(resource.getContentAsString());
///     return _flattenMap(data);
///   }
/// }
/// ```
/// {@endtemplate}
abstract class MessageSourceLoader {
  /// {@template message_loader_load}
  /// Load messages from the given resource.
  /// 
  /// This method should parse the resource content according to the
  /// loader's format and return a flat map where keys are message
  /// codes and values are message templates.
  /// 
  /// Parameters:
  /// - [resource]: The resource to load messages from
  /// 
  /// Returns a Future that resolves to a map of message codes to templates.
  /// 
  /// Example:
  /// ```dart
  /// final resource = AssetPathResource('messages.json');
  /// final messages = await loader.load(resource);
  /// print(messages['greeting']); // "Hello {0}!"
  /// ```
  /// {@endtemplate}
  Future<Map<String, String>> load(AssetPathResource resource);

  /// {@template message_loader_flatten_map}
  /// Flattens a nested map into dot-notation keys.
  /// 
  /// This utility method converts nested structures like:
  /// ```json
  /// {
  ///   "user": {
  ///     "greeting": "Hello",
  ///     "profile": {
  ///       "name": "Name: {0}"
  ///     }
  ///   }
  /// }
  /// ```
  /// 
  /// Into flat keys:
  /// ```dart
  /// {
  ///   "user.greeting": "Hello",
  ///   "user.profile.name": "Name: {0}"
  /// }
  /// ```
  /// {@endtemplate}
  Map<String, String> flattenMap(Map<String, dynamic> nested, {String prefix = ''}) {
    final result = <String, String>{};
    
    nested.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      
      if (value is Map<String, dynamic>) {
        result.addAll(flattenMap(value, prefix: fullKey));
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map<String, dynamic>) {
            result.addAll(flattenMap(item, prefix: '$fullKey[$i]'));
          } else {
            result['$fullKey[$i]'] = item.toString();
          }
        }
      } else {
        result[fullKey] = value.toString();
      }
    });
    
    return result;
  }
}