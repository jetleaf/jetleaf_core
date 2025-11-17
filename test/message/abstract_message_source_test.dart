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

import 'package:jetleaf_core/src/message/abstract_message_source.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

class TestMessageSource extends AbstractMessageSource {
  final Map<Locale, Map<String, String>> messages;

  TestMessageSource({super.defaultLocale, required this.messages});

  @override
  String? resolveMessage(String code, Locale locale) {
    return messages[locale]?[code];
  }
}

void main() {
  group('AbstractMessageSource', () {
    late TestMessageSource messageSource;
    final defaultLocale = Locale('en', 'US');
    final frLocale = Locale('fr');
    final frCALocale = Locale('fr', 'CA');
    final frCAQuebecLocale = Locale('fr', 'CA', 'Quebec');

    setUp(() {
      messageSource = TestMessageSource(
        defaultLocale: defaultLocale,
        messages: {
          defaultLocale: {
            'greeting': 'Hello',
            'welcome': 'Welcome {0}',
            'message.count': 'You have {0} messages',
          },
          frLocale: {
            'greeting': 'Bonjour',
            'welcome': 'Bienvenue {0}',
          },
          frCALocale: {
            'greeting': 'Bonjour Canada',
          },
        },
      );
    });

    test('should return default locale', () {
      expect(messageSource.getDefaultLocale(), equals(defaultLocale));
    });

    test('should resolve message with exact locale match', () {
      expect(
        messageSource.getMessage('greeting', locale: frLocale),
        equals('Bonjour'),
      );
    });

    test('should fallback to language when country variant not found', () {
      expect(
        messageSource.getMessage('welcome', locale: frCALocale),
        equals('Bienvenue {0}'),
      );
    });

    test('should fallback to default locale when locale not found', () {
      expect(
        messageSource.getMessage('greeting', locale: Locale('es')),
        equals('Hello'),
      );
    });

    test('should return code itself when message not found anywhere', () {
      expect(
        messageSource.getMessage('nonexistent', locale: Locale('es')),
        equals('nonexistent'),
      );
    });

    test('should format message with arguments', () {
      expect(
        messageSource.getMessage('welcome', args: ['John'], locale: frLocale),
        equals('Bienvenue John'),
      );
    });

    test('should format message with multiple arguments', () {
      expect(
        messageSource.getMessage('message.count', args: [5], locale: defaultLocale),
        equals('You have 5 messages'),
      );
    });

    test('should handle empty arguments list', () {
      expect(
        messageSource.getMessage('welcome', args: [], locale: defaultLocale),
        equals('Welcome {0}'),
      );
    });

    test('should return default message when provided and message not found', () {
      expect(
        messageSource.getMessage(
          'nonexistent',
          locale: Locale('es'),
          defaultMessage: 'Default message',
        ),
        equals('Default message'),
      );
    });

    test('should prioritize found message over default message', () {
      expect(
        messageSource.getMessage(
          'greeting',
          locale: frLocale,
          defaultMessage: 'Default greeting',
        ),
        equals('Bonjour'),
      );
    });

    test('should get fallback locales chain', () {
      final fallbacks = messageSource.getFallbackLocales(frCAQuebecLocale);
      
      expect(fallbacks, hasLength(4));
      expect(fallbacks[0], equals(frCAQuebecLocale));
      expect(fallbacks[1], equals(frCALocale));
      expect(fallbacks[2], equals(frLocale));
      expect(fallbacks[3], equals(defaultLocale));
    });

    test('should get fallback locales for locale without variant', () {
      final fallbacks = messageSource.getFallbackLocales(frCALocale);
      
      expect(fallbacks, hasLength(3));
      expect(fallbacks[0], equals(frCALocale));
      expect(fallbacks[1], equals(frLocale));
      expect(fallbacks[2], equals(defaultLocale));
    });

    test('should get fallback locales for locale without country', () {
      final fallbacks = messageSource.getFallbackLocales(frLocale);
      
      expect(fallbacks, hasLength(2));
      expect(fallbacks[0], equals(frLocale));
      expect(fallbacks[1], equals(defaultLocale));
    });

    test('should get fallback locales for default locale', () {
      final fallbacks = messageSource.getFallbackLocales(defaultLocale);
      
      expect(fallbacks, hasLength(1));
      expect(fallbacks[0], equals(defaultLocale));
    });

    test('should handle null locale by using default locale', () {
      expect(
        messageSource.getMessage('greeting'),
        equals('Hello'),
      );
    });

    test('should handle message with curly braces but no placeholders', () {
      const messageWithCurlyBraces = 'Message with {curly} braces';
      messageSource.messages[defaultLocale]!['curly'] = messageWithCurlyBraces;
      
      expect(
        messageSource.getMessage('curly', args: ['test']),
        equals(messageWithCurlyBraces),
      );
    });

    test('should handle message with mixed placeholders and text', () {
      const complexMessage = 'Hello {0}, your balance is {1} dollars';
      messageSource.messages[defaultLocale]!['complex'] = complexMessage;
      
      expect(
        messageSource.getMessage('complex', args: ['John', 100]),
        equals('Hello John, your balance is 100 dollars'),
      );
    });

    test('should handle message with out-of-order placeholders', () {
      const outOfOrderMessage = '{1} comes before {0}';
      messageSource.messages[defaultLocale]!['outoforder'] = outOfOrderMessage;
      
      expect(
        messageSource.getMessage('outoforder', args: ['first', 'second']),
        equals('second comes before first'),
      );
    });

    test('should handle message with duplicate placeholders', () {
      const duplicateMessage = 'Hello {0}, hello again {0}';
      messageSource.messages[defaultLocale]!['duplicate'] = duplicateMessage;
      
      expect(
        messageSource.getMessage('duplicate', args: ['John']),
        equals('Hello John, hello again John'),
      );
    });

    test('should handle more arguments than placeholders', () {
      expect(
        messageSource.getMessage('welcome', args: ['John', 'extra', 'args']),
        equals('Welcome John'),
      );
    });

    test('should handle fewer arguments than placeholders', () {
      const messageWithMultiple = 'Hello {0}, your ID is {1}';
      messageSource.messages[defaultLocale]!['multiple'] = messageWithMultiple;
      
      expect(
        messageSource.getMessage('multiple', args: ['John']),
        equals('Hello John, your ID is {1}'),
      );
    });

    test('should handle complex objects in arguments', () {
      final complexObject = _TestObject('test value');
      
      expect(
        messageSource.getMessage('welcome', args: [complexObject]),
        equals('Welcome Test Object: test value'),
      );
    });

    test('should handle empty string arguments', () {
      expect(
        messageSource.getMessage('welcome', args: ['']),
        equals('Welcome '),
      );
    });
  });
}

class _TestObject {
  final String value;

  _TestObject(this.value);

  @override
  String toString() => 'Test Object: $value';
}