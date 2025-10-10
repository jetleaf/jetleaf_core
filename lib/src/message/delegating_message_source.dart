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
import 'configurable_message_source.dart';
import 'message_source.dart';

/// A [MessageSource] implementation that delegates message resolution
/// to one or more underlying [MessageSource]s.
///
/// The typical use case is when you have multiple sources of messages,
/// such as:
/// - Default application messages
/// - Module-specific resource bundles
/// - Database-backed messages
///
/// The [DelegatingMessageSource] will try each configured delegate in order
/// until a message is found, or throw a [MessageSourceException] if none match.
///
/// ### Example
/// ```dart
/// final source = DelegatingMessageSource([
///   ResourceBundleMessageSource("messages"),
///   ResourceBundleMessageSource("errors"),
/// ]);
///
/// final msg = source.getMessage("greeting", locale: Locale("en"));
/// print(msg); // -> "Hello"
/// ```
class DelegatingMessageSource extends ConfigurableMessageSource {
  final List<MessageSource> _delegates;

  DelegatingMessageSource([List<MessageSource>? delegates]) : _delegates = delegates ?? [];

  /// Add another [MessageSource] to the delegation chain.
  void addDelegate(MessageSource source) => _delegates.add(source);

  @override
  String getMessage(String code, {List<Object>? args, Locale? locale, String? defaultMessage}) {
    for (final delegate in _delegates) {
      try {
        return delegate.getMessage(code, args: args, locale: locale, defaultMessage: defaultMessage);
      } on MessageSourceException {
        // Try next delegate
      }
    }

    if (defaultMessage != null) return defaultMessage;

    throw MessageSourceException(
      "Message with code '$code' not found in any delegate",
      code: code,
      locale: locale,
      resource: runtimeType.toString(),
    );
  }
}
