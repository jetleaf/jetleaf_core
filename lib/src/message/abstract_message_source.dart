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
import 'package:meta/meta.dart';

import 'message_source.dart';

/// {@template abstract_message_source}
/// Base implementation of MessageSource providing common functionality.
/// 
/// This abstract class implements shared behavior like placeholder
/// substitution and fallback locale resolution, allowing concrete
/// implementations to focus on message loading and storage.
/// 
/// ### Key features:
/// - Placeholder substitution with {0}, {1}, etc.
/// - Locale fallback chain resolution
/// - Message formatting utilities
/// 
/// ### Example subclass:
/// ```dart
/// class MyMessageSource extends AbstractMessageSource {
///   @override
///   String? resolveMessage(String code, Locale locale) {
///     // Custom message resolution logic
///     return myMessages[locale]?[code];
///   }
/// }
/// ```
/// {@endtemplate}
abstract class AbstractMessageSource implements MessageSource {
  final Locale _defaultLocale;

  /// {@macro abstract_message_source}
  AbstractMessageSource({Locale? defaultLocale}) : _defaultLocale = defaultLocale ?? Locale.DEFAULT_LOCALE;

  /// Get the default locale
  Locale getDefaultLocale() => _defaultLocale;

  @override
  String getMessage(String code, {List<Object>? args, Locale? locale, String? defaultMessage}) {
    final targetLocale = locale ?? _defaultLocale;
    
    // Try to resolve message with fallback chain
    String? message = _resolveMessageWithFallback(code, targetLocale);
    
    // If not found, use defaultMessage if provided, else fall back to code
    message ??= defaultMessage ?? code;
    
    // Apply placeholder substitution if args provided
    if (args != null && args.isNotEmpty) {
      message = formatMessage(message, args);
    }
    
    return message;
  }

  /// {@template abstract_message_source_resolve_message}
  /// Resolve a message for the given code and locale.
  /// 
  /// Subclasses must implement this method to provide the actual
  /// message lookup logic. This method should return null if the
  /// message is not found for the given locale.
  /// 
  /// Parameters:
  /// - [code]: The message code to resolve
  /// - [locale]: The locale to resolve for
  /// 
  /// Returns the message template or null if not found.
  /// {@endtemplate}
  String? resolveMessage(String code, Locale locale);

  /// {@template abstract_message_source_resolve_message_with_fallback}
  /// Resolve message with locale fallback chain.
  /// 
  /// This method implements the fallback strategy:
  /// 1. Try exact locale (language-country-variant)
  /// 2. Try language-country (if variant was specified)
  /// 3. Try language only
  /// 4. Try default locale (if different from target)
  /// 
  /// Example fallback chain for Locale('en', 'US', 'POSIX'):
  /// 1. en-US-POSIX
  /// 2. en-US  
  /// 3. en
  /// 4. Default locale (if not 'en')
  /// {@endtemplate}
  String? _resolveMessageWithFallback(String code, Locale locale) {
    // Try exact locale first
    String? message = resolveMessage(code, locale);
    if (message != null) return message;

    // Try without variant if present
    if (locale.hasVariant()) {
      final withoutVariant = Locale(locale.getLanguage(), locale.getCountry());
      message = resolveMessage(code, withoutVariant);
      if (message != null) return message;
    }

    // Try language only if country was present
    if (locale.hasCountry()) {
      final languageOnly = Locale(locale.getLanguage());
      message = resolveMessage(code, languageOnly);
      if (message != null) return message;
    }

    // Try default locale if different from current
    if (!locale.matches(_defaultLocale)) {
      message = resolveMessage(code, _defaultLocale);
      if (message != null) return message;
    }

    return null;
  }

  /// {@template abstract_message_source_format_message}
  /// Format message by substituting placeholders with arguments.
  /// 
  /// Supports numbered placeholders like {0}, {1}, {2}, etc.
  /// Arguments are substituted in order, with toString() called
  /// on each argument.
  /// 
  /// Example:
  /// ```dart
  /// final formatted = _formatMessage("Hello {0}, you have {1} messages", 
  ///                                  ["Alice", 5]);
  /// // Result: "Hello Alice, you have 5 messages"
  /// ```
  /// {@endtemplate}
  @protected
  String formatMessage(String template, List<Object> args) {
    String result = template;
    
    for (int i = 0; i < args.length; i++) {
      final placeholder = '{$i}';
      final replacement = args[i].toString();
      result = result.replaceAll(placeholder, replacement);
    }
    
    return result;
  }

  /// {@template abstract_message_source_get_fallback_locales}
  /// Get the fallback locale chain for the given locale.
  /// 
  /// This method returns the ordered list of locales to try
  /// when resolving messages, implementing the fallback strategy.
  /// 
  /// Example for Locale('fr', 'CA', 'Quebec'):
  /// 1. fr-CA-Quebec
  /// 2. fr-CA
  /// 3. fr
  /// 4. Default locale (if different)
  /// {@endtemplate}
  List<Locale> getFallbackLocales(Locale locale) {
    // If locale is the default, return only that
    if (locale.matches(_defaultLocale)) {
      return [locale];
    }

    final fallbacks = <Locale>[locale];

    // Add variant fallback
    if (locale.hasVariant()) {
      fallbacks.add(Locale(locale.getLanguage(), locale.getCountry()));
    }

    // Add country fallback  
    if (locale.hasCountry()) {
      fallbacks.add(Locale(locale.getLanguage()));
    }

    // Add default locale fallback
    if (!locale.matches(_defaultLocale)) {
      fallbacks.add(_defaultLocale);
    }

    return fallbacks;
  }
}