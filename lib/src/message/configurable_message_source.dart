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

import '../exceptions.dart';
import 'abstract_message_source.dart';
import 'message_source_loader.dart';

/// {@template configurable_message_source}
/// Main implementation of MessageSource that supports loading messages
/// from multiple resources and formats.
/// 
/// This class allows you to configure message sources by loading
/// different message files for different locales using pluggable
/// loaders for various formats (JSON, YAML, Properties).
/// 
/// ### Example usage:
/// ```dart
/// final messageSource = ConfigurableMessageSource(
///   defaultLocale: Locale('en', 'US')
/// );
/// 
/// // Load English messages from JSON
/// await messageSource.loadMessages(
///   Locale('en'),
///   AssetPathResource('messages_en.json'),
///   loader: JsonMessageLoader(),
/// );
/// 
/// // Load French messages from YAML  
/// await messageSource.loadMessages(
///   Locale('fr'),
///   AssetPathResource('messages_fr.yaml'),
///   loader: YamlMessageLoader(),
/// );
/// 
/// // Use the messages
/// print(messageSource.getMessage('greeting', locale: Locale('fr')));
/// ```
/// {@endtemplate}
class ConfigurableMessageSource extends AbstractMessageSource {
  final Map<Locale, Map<String, String>> _messages = {};

  /// {@macro configurable_message_source}
  ConfigurableMessageSource({Locale? defaultLocale}) : super(defaultLocale: defaultLocale);

  /// {@template configurable_message_source_load_messages}
  /// Load messages for a specific locale from a resource.
  /// 
  /// This method uses the provided loader to parse the resource
  /// and stores the resulting messages for the given locale.
  /// Multiple calls for the same locale will merge the messages.
  /// 
  /// Parameters:
  /// - [locale]: The locale to load messages for
  /// - [resource]: The resource containing the messages
  /// - [loader]: The loader to use for parsing the resource
  /// 
  /// Example:
  /// ```dart
  /// await messageSource.loadMessages(
  ///   Locale('es', 'MX'),
  ///   AssetPathResource('messages_es_MX.properties'),
  ///   PropertiesMessageLoader(),
  /// );
  /// ```
  /// {@endtemplate}
  Future<void> loadMessages(Locale locale, AssetPathResource resource, MessageSourceLoader loader) async {
    try {
      final messages = await loader.load(resource);
      
      // Initialize locale map if not exists
      _messages[locale] ??= <String, String>{};
      
      // Merge messages (later loaded messages override earlier ones)
      _messages[locale]?.addAll(messages);
      
    } catch (e) {
      throw MessageSourceException(
        'Failed to load messages for locale ${locale.getLanguageTag()}',
        code: locale.getLanguageTag(),
        locale: locale,
        resource: resource.getResourcePath(),
      );
    }
  }

  /// {@template configurable_message_source_add_message}
  /// Add a single message for a specific locale.
  /// 
  /// This method allows programmatic addition of messages without
  /// loading from a resource file.
  /// 
  /// Parameters:
  /// - [locale]: The locale for the message
  /// - [code]: The message code
  /// - [message]: The message template
  /// 
  /// Example:
  /// ```dart
  /// messageSource.addMessage(
  ///   Locale('en'),
  ///   'dynamic.greeting',
  ///   'Hello {0}, welcome to our app!'
  /// );
  /// ```
  /// {@endtemplate}
  void addMessage(Locale locale, String code, String message) {
    _messages[locale] ??= <String, String>{};
    _messages[locale]?[code] = message;
  }

  /// {@template configurable_message_source_add_messages}
  /// Add multiple messages for a specific locale.
  /// 
  /// This method allows bulk addition of messages without loading
  /// from a resource file.
  /// 
  /// Parameters:
  /// - [locale]: The locale for the messages
  /// - [messages]: Map of message codes to templates
  /// 
  /// Example:
  /// ```dart
  /// messageSource.addMessages(Locale('en'), {
  ///   'app.title': 'My Application',
  ///   'app.version': 'Version {0}',
  ///   'user.greeting': 'Hello {0}!'
  /// });
  /// ```
  /// {@endtemplate}
  void addMessages(Locale locale, Map<String, String> messages) {
    _messages[locale] ??= <String, String>{};
    _messages[locale]?.addAll(messages);
  }

  /// {@template configurable_message_source_remove_messages}
  /// Remove all messages for a specific locale.
  /// 
  /// This method clears all loaded messages for the given locale.
  /// 
  /// Parameters:
  /// - [locale]: The locale to clear messages for
  /// 
  /// Example:
  /// ```dart
  /// messageSource.removeMessages(Locale('fr'));
  /// ```
  /// {@endtemplate}
  void removeMessages(Locale locale) {
    _messages.remove(locale);
  }

  /// {@template configurable_message_source_get_loaded_locales}
  /// Get all locales that have messages loaded.
  /// 
  /// Returns a set of all locales for which messages have been loaded.
  /// 
  /// Example:
  /// ```dart
  /// final locales = messageSource.getLoadedLocales();
  /// print('Supported locales: ${locales.map((l) => l.getLanguageTag()).join(', ')}');
  /// ```
  /// {@endtemplate}
  Set<Locale> getLoadedLocales() => Set.from(_messages.keys);

  /// {@template configurable_message_source_has_messages}
  /// Check if messages are loaded for a specific locale.
  /// 
  /// Parameters:
  /// - [locale]: The locale to check
  /// 
  /// Returns true if messages are loaded for the locale.
  /// 
  /// Example:
  /// ```dart
  /// if (messageSource.hasMessages(Locale('de'))) {
  ///   print('German messages are available');
  /// }
  /// ```
  /// {@endtemplate}
  bool hasMessages(Locale locale) => _messages.containsKey(locale) && _messages[locale]!.isNotEmpty;

  /// {@template configurable_message_source_get_message_count}
  /// Get the number of messages loaded for a specific locale.
  /// 
  /// Parameters:
  /// - [locale]: The locale to count messages for
  /// 
  /// Returns the number of messages, or 0 if no messages are loaded.
  /// 
  /// Example:
  /// ```dart
  /// final count = messageSource.getMessageCount(Locale('en'));
  /// print('English messages loaded: $count');
  /// ```
  /// {@endtemplate}
  int getMessageCount(Locale locale) => _messages[locale]?.length ?? 0;

  @override
  String? resolveMessage(String code, Locale locale) => _messages[locale]?[code];

  /// {@template configurable_message_source_clear}
  /// Clear all loaded messages.
  /// 
  /// This method removes all messages for all locales.
  /// 
  /// Example:
  /// ```dart
  /// messageSource.clear();
  /// ```
  /// {@endtemplate}
  void clear() {
    _messages.clear();
  }

  /// {@template configurable_message_source_to_string}
  /// Get a string representation of the message source.
  /// 
  /// Returns information about loaded locales and message counts.
  /// {@endtemplate}
  @override
  String toString() {
    final localeInfo = _messages.entries
        .map((e) => '${e.key.getLanguageTag()}(${e.value.length})')
        .join(', ');
    return 'ConfigurableMessageSource[default: ${getDefaultLocale().getLanguageTag()}, locales: $localeInfo]';
  }
}