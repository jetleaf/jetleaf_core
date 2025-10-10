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

/// {@template message_source}
/// Interface for resolving messages, with support for parameterization and
/// internationalization.
/// 
/// This is the main interface that applications will use to retrieve
/// localized messages. It provides a clean API for message resolution
/// with placeholder substitution and locale fallback support.
/// 
/// ### Example usage:
/// ```dart
/// final messageSource = ConfigurableMessageSource();
/// 
/// // Get a simple message
/// final greeting = messageSource.getMessage('greeting');
/// 
/// // Get a message with parameters
/// final welcome = messageSource.getMessage('welcome', args: ['John']);
/// 
/// // Get a message for a specific locale
/// final bonjour = messageSource.getMessage('greeting', locale: Locale('fr'));
/// ```
/// {@endtemplate}
abstract class MessageSource {
  /// {@template message_source_get_message}
  /// Retrieve a message for the given code.
  /// 
  /// Parameters:
  /// - [code]: The message code to look up
  /// - [args]: Optional arguments for placeholder substitution
  /// - [locale]: Optional locale for message resolution
  /// 
  /// Returns the resolved message string, or the code itself if not found.
  /// 
  /// Example:
  /// ```dart
  /// // Simple message
  /// final msg1 = getMessage('hello'); // "Hello"
  /// 
  /// // Message with parameters
  /// final msg2 = getMessage('welcome', args: ['Alice']); // "Welcome Alice!"
  /// 
  /// // Message for specific locale
  /// final msg3 = getMessage('hello', locale: Locale('es')); // "Hola"
  /// ```
  /// {@endtemplate}
  String getMessage(String code, {List<Object>? args, Locale? locale, String? defaultMessage});
}