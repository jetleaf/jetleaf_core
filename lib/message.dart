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

/// {@template message_library}
/// A comprehensive internationalization (i18n) and message management library 
/// for Dart applications that provides flexible message source abstraction 
/// and loading capabilities.
/// 
/// This library enables developers to externalize and manage application 
/// messages, labels, and internationalized text through a unified interface
/// with support for multiple message formats, reloading, and hierarchical
/// message source resolution.
/// 
/// ## Core Features
/// 
/// - **Unified Message Abstraction**: Consistent API for accessing messages
///   regardless of the underlying storage mechanism
/// - **Internationalization Support**: Built-in support for multiple locales
///   and language resolution
/// - **Hierarchical Message Sources**: Parent-child relationships for
///   overriding and fallback message resolution
/// - **Configurable Message Loading**: Flexible loading strategies for
///   different message formats and storage backends
/// - **Message Reloading**: Hot-reload capabilities for development and
///   runtime message updates
/// - **Parameterized Messages**: Support for dynamic message content with
///   parameter substitution
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:your_package/message.dart';
/// 
/// void main() async {
///   // Create a configurable message source
///   final messageSource = ConfigurableMessageSource();
///   
///   // Load messages from properties files
///   await messageSource.setBasenames(['messages', 'errors']);
///   await messageSource.setDefaultLocale(Locale('en', 'US'));
///   
///   // Retrieve messages
///   final welcomeMessage = messageSource.getMessage(
///     'welcome.message', 
///     null, 
///     Locale('en', 'US')
///   );
///   
///   print(welcomeMessage); // Outputs: Welcome to our application!
///   
///   // Parameterized messages
///   final greeting = messageSource.getMessage(
///     'user.greeting', 
///     ['John', 'Doe'], 
///     Locale('en', 'US')
///   );
///   
///   print(greeting); // Outputs: Hello, John Doe!
/// }
/// ```
/// 
/// ## Architecture Overview
/// 
/// The library follows a layered architecture with clear separation of concerns:
/// 
/// - **MessageSource**: Core interface defining message retrieval contract
/// - **AbstractMessageSource**: Base implementation with common functionality
/// - **ConfigurableMessageSource**: Full-featured implementation with
///   configuration capabilities
/// - **MessageSourceLoader**: Strategy interface for loading messages from
///   various sources
/// 
/// ## Module Exports
/// 
/// This library exports the following key components:
/// 
/// - [MessageSource]: Core interface for message retrieval operations
/// - [MessageSourceLoader]: Strategy for loading messages from specific sources
/// - [AbstractMessageSource]: Base class with common message source functionality
/// - [ConfigurableMessageSource]: Full implementation with configuration support
/// 
/// ## Core Components
/// 
/// ### MessageSource
/// The fundamental interface that defines the contract for message resolution.
/// Provides methods for retrieving messages with optional parameters and locale
/// support.
/// 
/// ### MessageSourceLoader  
/// Strategy interface for loading messages from various storage backends
/// (properties files, JSON, databases, etc.). Enables pluggable loading
/// implementations.
/// 
/// ### AbstractMessageSource
/// Base implementation that provides common functionality like parent message
/// source delegation, message formatting, and default implementations for
/// common operations.
/// 
/// ### ConfigurableMessageSource
/// The most commonly used implementation that supports configuration of
/// base names, default locale, cache settings, and reloading behavior.
/// 
/// ## Advanced Usage
/// 
/// ```dart
/// // Custom message source loader for JSON files
/// class JsonMessageSourceLoader implements MessageSourceLoader {
///   @override
///   Future<Map<String, String>> loadMessages(String baseName, Locale locale) async {
///     final fileName = '$baseName_${locale.languageCode}.json';
///     final file = File(fileName);
///     final content = await file.readAsString();
///     return Map<String, String>.from(json.decode(content));
///   }
///   
///   @override
///   bool supportsReloading() => true;
/// }
/// 
/// // Hierarchical message sources
/// void setupMessageHierarchy() {
///   final parentSource = ConfigurableMessageSource();
///   await parentSource.setBasenames(['common_messages']);
///   
///   final childSource = ConfigurableMessageSource();
///   childSource.setParentMessageSource(parentSource);
///   await childSource.setBasenames(['application_messages']);
///   
///   // Child source will fall back to parent for unresolved messages
///   final message = childSource.getMessage('common.button.submit', null, Locale('en'));
/// }
/// 
/// // Hot reloading in development
/// class DevelopmentMessageSource extends ConfigurableMessageSource {
///   @override
///   Future<void> reload() async {
///     await clearCache();
///     await refreshMessages();
///     notifyListeners(); // Notify UI to refresh
///   }
/// }
/// ```
/// 
/// ## Supported Message Formats
/// 
/// - **Properties Files**: Traditional .properties format
/// - **JSON Messages**: Structured JSON format with locale support
/// - **XML Properties**: XML-based message definitions
/// - **Database Storage**: Messages stored in database tables
/// - **Remote Services**: Messages fetched from remote configuration services
/// - **In-Memory Maps**: Programmatically defined message maps
/// 
/// ## Internationalization Patterns
/// 
/// ```dart
/// // Multi-locale application setup
/// class InternationalizedApp {
///   final ConfigurableMessageSource messages;
///   
///   String getWelcomeMessage(Locale userLocale) {
///     return messages.getMessage('welcome.title', null, userLocale);
///   }
///   
///   String getFormattedMessage(String code, List<Object> args, Locale locale) {
///     return messages.getMessage(code, args, locale);
///   }
/// }
/// 
/// // Fallback locale strategy
/// class SmartMessageSource extends ConfigurableMessageSource {
///   @override
///   String getMessage(String code, List<Object>? args, Locale locale) {
///     try {
///       return super.getMessage(code, args, locale);
///     } on MessageNotFoundException {
///       // Fallback to default locale
///       return super.getMessage(code, args, getDefaultLocale());
///     }
///   }
/// }
/// ```
/// 
/// ## Configuration Options
/// 
/// - **Base Names**: Configure multiple message base names for organization
/// - **Default Locale**: Set fallback locale for missing translations
/// - **Cache Settings**: Control message caching behavior and TTL
/// - **Reload Strategies**: Configure when and how messages are reloaded
/// - **Parent Sources**: Establish hierarchical message resolution
/// - **Formatting Rules**: Customize message parameter formatting
/// 
/// ## Integration Patterns
/// 
/// - **Web Applications**: Internationalize UI labels and messages
/// - **Mobile Apps**: Support multiple languages in Flutter applications
/// - **Microservices**: Consistent messaging across distributed services
/// - **Validation Messages**: Externalize validation error messages
/// - **Notification System**: Manage system notifications and alerts
/// - **API Responses**: Standardize API error messages and codes
/// 
/// ## Best Practices
/// 
/// - Use consistent message codes across the application
/// - Organize messages by feature or module using base names
/// - Implement proper fallback strategies for missing translations
/// - Use parameterized messages for dynamic content
/// - Cache messages appropriately for performance
/// - Monitor message resolution failures in production
/// - Version control message files alongside source code
/// - Test all supported locales during development
/// 
/// ## Performance Considerations
/// 
/// - Implement message caching for frequently accessed messages
/// - Use lazy loading for large message sets
/// - Consider memory usage when supporting many locales
/// - Optimize message file loading with appropriate formats
/// - Monitor cache hit rates and adjust cache strategies accordingly
/// - Use compression for large message bundles in mobile applications
/// 
/// {@endtemplate}
library;

/// Core interface for message retrieval and internationalization support.
export 'src/message/message_source.dart';

/// Strategy interface for loading messages from various sources and formats.
export 'src/message/message_source_loader.dart';

/// Base implementation with common message source functionality and parent-child support.
export 'src/message/abstract_message_source.dart';

/// Full-featured message source implementation with configuration capabilities.
export 'src/message/configurable_message_source.dart';