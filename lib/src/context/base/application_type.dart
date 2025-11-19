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

/// {@template application_type}
/// Enumeration of types of applications that can be run in a JetLeaf
/// environment.
///
/// This enum helps determine whether the application context should be
/// bootstrapped with web-specific configurations (such as servlet or filter
/// mappings), or treated as a non-web application.
///
/// Example usage:
/// ```dart
/// void main() {
///   final type = ApplicationType.WEB;
///   print(type.getName()); // WEB
///   print(type.getEmoji()); // 🌐
/// }
/// ```
/// {@endtemplate}
enum ApplicationType {
  /// {@macro application_type}
  NONE("CLI", "💻"),

  /// {@macro application_type}
  WEB("WEB", "🌐");

  /// {@template application_type_fields}
  /// Internal string name representing the type.
  /// {@endtemplate}
  final String _name;

  /// {@template application_type_fields}
  /// Emoji representing the type, for visual identification.
  /// {@endtemplate}
  final String _emoji;

  /// {@template application_type_constructor}
  /// Creates an instance of [ApplicationType] with a name and an emoji.
  ///
  /// Typically, this constructor is used internally by the enum values and
  /// not called directly.
  /// {@endtemplate}
  const ApplicationType(this._name, this._emoji);

  /// {@template application_type_getName}
  /// Returns the string name of this [ApplicationType].
  ///
  /// Example:
  /// ```dart
  /// final type = ApplicationType.WEB;
  /// print(type.getName()); // WEB
  /// ```
  /// {@endtemplate}
  String getName() => _name;

  /// {@template application_type_getEmoji}
  /// Returns the emoji representing this [ApplicationType].
  ///
  /// Example:
  /// ```dart
  /// final type = ApplicationType.NONE;
  /// print(type.getEmoji()); // 💻
  /// ```
  /// {@endtemplate}
  String getEmoji() => _emoji;

  /// {@template application_type_fromString}
  /// Returns the [ApplicationType] that matches the given [name].
  ///
  /// The comparison is case-insensitive. If no match is found, it returns
  /// [ApplicationType.NONE].
  ///
  /// Example:
  /// ```dart
  /// final type = ApplicationType.fromString('web');
  /// print(type); // ApplicationType.WEB
  ///
  /// final unknownType = ApplicationType.fromString('mobile');
  /// print(unknownType); // ApplicationType.NONE
  /// ```
  /// {@endtemplate}
  static ApplicationType fromString(String name) {
    return ApplicationType.values.firstWhere(
      (e) => e.name.equalsIgnoreCase(name), 
      orElse: () => ApplicationType.NONE
    );
  }
}