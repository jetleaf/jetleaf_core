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
import 'package:jetleaf_utils/utils.dart';

import 'message_source_loader.dart';

/// {@template json_message_loader}
/// MessageSourceLoader implementation for JSON format files.
/// 
/// This loader uses the JsonParser to parse JSON message files and
/// converts nested structures into flat dot-notation keys for
/// easy message resolution.
/// 
/// ### Example usage:
/// ```dart
/// final loader = JsonMessageLoader();
/// final resource = AssetPathResource('messages_en.json');
/// final messages = await loader.load(resource);
/// ```
/// 
/// ### Supported JSON structure:
/// ```json
/// {
///   "greeting": "Hello {0}!",
///   "user": {
///     "welcome": "Welcome back, {0}",
///     "profile": {
///       "updated": "Profile updated successfully"
///     }
///   }
/// }
/// ```
/// 
/// Results in message keys:
/// - `greeting`
/// - `user.welcome`  
/// - `user.profile.updated`
/// {@endtemplate}
class JsonMessageLoader extends MessageSourceLoader {
  final JsonParser _parser = JsonParser();

  /// {@macro json_message_loader}
  JsonMessageLoader();

  @override
  Future<Map<String, String>> load(AssetPathResource resource) async {
    try {
      final content = resource.getContentAsString();
      final data = _parser.parse(content);
      return flattenMap(data);
    } catch (e) {
      throw InvalidArgumentException('Failed to load JSON messages from ${resource.getResourcePath()}: $e');
    }
  }
}

/// {@template properties_message_loader}
/// MessageSourceLoader implementation for Java-style properties files.
/// 
/// This loader uses the PropertiesParser to parse properties message files
/// and converts nested dot-notation keys into a flat structure for
/// easy message resolution.
/// 
/// ### Example usage:
/// ```dart
/// final loader = PropertiesMessageLoader();
/// final resource = AssetPathResource('messages_en.properties');
/// final messages = await loader.load(resource);
/// ```
/// 
/// ### Supported properties structure:
/// ```properties
/// greeting=Hello {0}!
/// user.welcome=Welcome back, {0}
/// user.profile.updated=Profile updated successfully
/// ```
/// 
/// Results in message keys:
/// - `greeting`
/// - `user.welcome`
/// - `user.profile.updated`
/// {@endtemplate}
class PropertiesMessageLoader extends MessageSourceLoader {
  final PropertiesParser _parser = PropertiesParser();

  /// {@macro properties_message_loader}
  PropertiesMessageLoader();

  @override
  Future<Map<String, String>> load(AssetPathResource resource) async {
    try {
      final content = resource.getContentAsString();
      final data = _parser.parse(content);
      return flattenMap(data);
    } catch (e) {
      throw InvalidArgumentException('Failed to load Properties messages from ${resource.getResourcePath()}: $e');
    }
  }
}

/// {@template yaml_message_loader}
/// MessageSourceLoader implementation for YAML format files.
/// 
/// This loader uses the YamlParser to parse YAML message files and
/// converts nested structures into flat dot-notation keys for
/// easy message resolution.
/// 
/// ### Example usage:
/// ```dart
/// final loader = YamlMessageLoader();
/// final resource = AssetPathResource('messages_en.yaml');
/// final messages = await loader.load(resource);
/// ```
/// 
/// ### Supported YAML structure:
/// ```yaml
/// greeting: "Hello {0}!"
/// user:
///   welcome: "Welcome back, {0}"
///   profile:
///     updated: "Profile updated successfully"
/// ```
/// 
/// Results in message keys:
/// - `greeting`
/// - `user.welcome`
/// - `user.profile.updated`
/// {@endtemplate}
class YamlMessageLoader extends MessageSourceLoader {
  final YamlParser _parser = YamlParser();

  /// {@macro yaml_message_loader}
  YamlMessageLoader();

  @override
  Future<Map<String, String>> load(AssetPathResource resource) async {
    try {
      final content = resource.getContentAsString();
      final data = _parser.parse(content);
      return flattenMap(data);
    } catch (e) {
      throw InvalidArgumentException('Failed to load YAML messages from ${resource.getResourcePath()}: $e');
    }
  }
}