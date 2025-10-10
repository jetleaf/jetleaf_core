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

import 'package:jetleaf_core/src/message/configurable_message_source.dart';
import 'package:jetleaf_core/src/message/message_source_loader.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

class MockMessageLoader extends MessageSourceLoader {
  final Map<String, String> messagesToReturn;
  final Exception? errorToThrow;

  MockMessageLoader({required this.messagesToReturn, this.errorToThrow});

  @override
  Future<Map<String, String>> load(AssetPathResource resource) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return messagesToReturn;
  }

  @override
  Map<String, String> flattenMap(Map<String, dynamic> nested, {String prefix = ''}) {
    return messagesToReturn; // Simplified for testing
  }
}

void main() {
  group('ConfigurableMessageSource', () {
    late ConfigurableMessageSource messageSource;
    final enLocale = Locale('en');
    final frLocale = Locale('fr');
    final esLocale = Locale('es');

    setUp(() {
      messageSource = ConfigurableMessageSource(defaultLocale: enLocale);
    });

    test('should resolve message after loading', () async {
      final loader = MockMessageLoader(messagesToReturn: {
        'greeting': 'Hello',
        'welcome': 'Welcome {0}',
      });

      await messageSource.loadMessages(enLocale, DefaultAssetPathResource('test.json'), loader);

      expect(messageSource.resolveMessage('greeting', enLocale), equals('Hello'));
      expect(messageSource.getMessage('welcome', args: ['John']), equals('Welcome John'));
    });

    test('should throw when loading fails', () async {
      final loader = MockMessageLoader(
        messagesToReturn: {},
        errorToThrow: Exception('Load failed'),
      );

      expect(
        () async => await messageSource.loadMessages(enLocale, DefaultAssetPathResource('test.json'), loader),
        throwsA(isA<Exception>()),
      );
    });

    test('should add single message', () {
      messageSource.addMessage(enLocale, 'test.message', 'Test message');
      
      expect(messageSource.resolveMessage('test.message', enLocale), equals('Test message'));
    });

    test('should add multiple messages', () {
      final messages = {
        'msg1': 'Message 1',
        'msg2': 'Message 2',
      };
      
      messageSource.addMessages(enLocale, messages);
      
      expect(messageSource.resolveMessage('msg1', enLocale), equals('Message 1'));
      expect(messageSource.resolveMessage('msg2', enLocale), equals('Message 2'));
    });

    test('should remove messages for locale', () {
      messageSource.addMessage(enLocale, 'test.message', 'Test message');
      messageSource.removeMessages(enLocale);
      
      expect(messageSource.resolveMessage('test.message', enLocale), isNull);
    });

    test('should get loaded locales', () {
      messageSource.addMessage(enLocale, 'en.msg', 'English');
      messageSource.addMessage(frLocale, 'fr.msg', 'French');
      
      final locales = messageSource.getLoadedLocales();
      
      expect(locales, containsAll([enLocale, frLocale]));
      expect(locales, hasLength(2));
    });

    test('should check if locale has messages', () {
      expect(messageSource.hasMessages(enLocale), isFalse);
      
      messageSource.addMessage(enLocale, 'test.message', 'Test message');
      
      expect(messageSource.hasMessages(enLocale), isTrue);
      expect(messageSource.hasMessages(frLocale), isFalse);
    });

    test('should get message count', () {
      expect(messageSource.getMessageCount(enLocale), equals(0));
      
      messageSource.addMessage(enLocale, 'msg1', 'Message 1');
      messageSource.addMessage(enLocale, 'msg2', 'Message 2');
      
      expect(messageSource.getMessageCount(enLocale), equals(2));
      expect(messageSource.getMessageCount(frLocale), equals(0));
    });

    test('should clear all messages', () {
      messageSource.addMessage(enLocale, 'msg1', 'Message 1');
      messageSource.addMessage(frLocale, 'msg2', 'Message 2');
      
      messageSource.clear();
      
      expect(messageSource.getLoadedLocales(), isEmpty);
      expect(messageSource.getMessageCount(enLocale), equals(0));
    });

    test('should merge messages when loading multiple times', () async {
      final loader1 = MockMessageLoader(messagesToReturn: {
        'msg1': 'Message 1',
        'msg2': 'Message 2',
      });

      final loader2 = MockMessageLoader(messagesToReturn: {
        'msg2': 'Updated Message 2',
        'msg3': 'Message 3',
      });

      await messageSource.loadMessages(enLocale, DefaultAssetPathResource('test1.json'), loader1);
      await messageSource.loadMessages(enLocale, DefaultAssetPathResource('test2.json'), loader2);

      expect(messageSource.resolveMessage('msg1', enLocale), equals('Message 1'));
      expect(messageSource.resolveMessage('msg2', enLocale), equals('Updated Message 2'));
      expect(messageSource.resolveMessage('msg3', enLocale), equals('Message 3'));
    });

    test('should handle null default locale', () {
      final sourceWithNullDefault = ConfigurableMessageSource();
      expect(sourceWithNullDefault.getDefaultLocale(), equals(Locale.DEFAULT_LOCALE));
    });

    test('should return proper string representation', () {
      messageSource.addMessage(enLocale, 'msg1', 'Message 1');
      messageSource.addMessage(frLocale, 'msg2', 'Message 2');
      messageSource.addMessage(frLocale, 'msg3', 'Message 3');
      
      final str = messageSource.toString();
      
      expect(str, contains('ConfigurableMessageSource'));
      expect(str, contains('en(1)'));
      expect(str, contains('fr(2)'));
    });

    test('should handle empty messages map for locale', () {
      messageSource.addMessages(enLocale, {});
      
      expect(messageSource.hasMessages(enLocale), isFalse);
      expect(messageSource.getMessageCount(enLocale), equals(0));
    });

    test('should handle adding message to non-existent locale', () {
      messageSource.addMessage(esLocale, 'test.message', 'Test message');
      
      expect(messageSource.hasMessages(esLocale), isTrue);
      expect(messageSource.resolveMessage('test.message', esLocale), equals('Test message'));
    });

    test('should handle removing non-existent locale', () {
      expect(() => messageSource.removeMessages(esLocale), returnsNormally);
    });

    test('should return null for non-existent message', () {
      messageSource.addMessage(enLocale, 'existing.msg', 'Existing');
      
      expect(messageSource.resolveMessage('non.existent', enLocale), isNull);
    });

    test('should handle messages with special characters', () {
      const specialMessage = 'Message with ñ, é, ç and 中文';
      messageSource.addMessage(enLocale, 'special', specialMessage);
      
      expect(messageSource.resolveMessage('special', enLocale), equals(specialMessage));
    });
  });
}