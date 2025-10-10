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

// ========================================= MESSAGE SOURCE EXCEPTION ========================================

/// {@template message_source_exception}
/// An exception that occurs when resolving messages from a [MessageSource].
///
/// This exception provides additional context beyond a simple error message:
/// - [code]: the message key that failed to resolve.
/// - [locale]: the locale that was requested when the error occurred.
/// - [resource]: the underlying resource (e.g., file, bundle, or database) involved.
/// - [cause]: the original exception that triggered this error, if any.
///
/// This is especially useful in internationalization (i18n) and configuration
/// systems where message lookup may fail due to missing keys, unsupported locales,
/// or inaccessible resources.
///
/// ### Example
/// ```dart
/// void loadMessage(String key, Locale locale) {
///   throw MessageSourceException(
///     "Message key not found",
///     code: key,
///     locale: locale,
///     resource: "messages_en.properties",
///   );
/// }
///
/// try {
///   loadMessage("missing.key", Locale("en"));
/// } catch (e) {
///   print(e);
///   // Output:
///   // MessageSourceException: Message key not found [code=missing.key] [locale=en] [resource=messages_en.properties]
/// }
/// ```
/// {@endtemplate}
class MessageSourceException extends RuntimeException {
  /// The message code (key) that failed to resolve.
  final String? code;

  /// The locale in which the message was being resolved.
  final Locale? locale;

  /// The resource (e.g., properties file, database, etc.)
  /// that was queried during resolution.
  final String? resource;

  /// {@macro message_source_exception}
  MessageSourceException(
    String message, {
    this.code,
    this.locale,
    this.resource,
    Object? cause,
  }) : super(message, cause: cause);

  @override
  String toString() {
    final buf = StringBuffer('MessageSourceException: $message');
    if (code != null) buf.write(' [code=$code]');
    if (locale != null) buf.write(' [locale=$locale]');
    if (resource != null) buf.write(' [resource=$resource]');
    if (cause != null) buf.write(' (cause=$cause)');
    return buf.toString();
  }
}

// ========================================= JSON PARSING EXCEPTION ========================================

/// {@template json_parsing_exception}
/// An exception that occurs during JSON parsing.
///
/// This exception is thrown when there is an error in parsing a JSON string
/// into a Dart object, or when a Dart object cannot be serialized into a JSON string.
///
/// ### Example
/// ```dart
/// void parseJson(String json) {
///   try {
///     final object = jsonDecode(json);
///   } catch (e) {
///     throw JsonParsingException("Failed to parse JSON", cause: e);
///   }
/// }
/// ```
/// {@endtemplate}
class JsonParsingException extends RuntimeException {
  /// {@macro json_parsing_exception}
  JsonParsingException(String message, {Object? cause}) : super(message, cause: cause);
}