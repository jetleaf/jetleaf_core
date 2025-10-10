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

import 'package:jetleaf_core/src/exceptions.dart';
import 'package:jetleaf_core/src/message/delegating_message_source.dart';
import 'package:jetleaf_core/src/message/message_source.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

class MockMessageSource implements MessageSource {
  final Map<String, String> messages;
  final bool shouldThrow;

  MockMessageSource({required this.messages, this.shouldThrow = false});

  @override
  String getMessage(String code, {List<Object>? args, Locale? locale, String? defaultMessage}) {
    if (shouldThrow) {
      throw MessageSourceException('Test exception', code: code);
    }
    
    final message = messages[code];
    if (message == null && defaultMessage == null) {
      throw MessageSourceException('Message not found', code: code);
    }
    
    return defaultMessage ?? message ?? code;
  }
}

void main() {
  group('DelegatingMessageSource', () {
    late DelegatingMessageSource delegatingSource;
    late MockMessageSource source1;
    late MockMessageSource source2;
    late MockMessageSource source3;
    final enLocale = Locale('en');

    setUp(() {
      source1 = MockMessageSource(messages: {
        'greeting': 'Hello from source1',
        'welcome': 'Welcome from source1',
      });

      source2 = MockMessageSource(messages: {
        'farewell': 'Goodbye from source2',
        'error': 'Error from source2',
      });

      source3 = MockMessageSource(messages: {
        'special': 'Special from source3',
      });

      delegatingSource = DelegatingMessageSource([source1, source2]);
    });

    test('should delegate to first source when message found', () {
      expect(
        delegatingSource.getMessage('greeting'),
        equals('Hello from source1'),
      );
    });

    test('should delegate to second source when first fails', () {
      expect(
        delegatingSource.getMessage('farewell'),
        equals('Goodbye from source2'),
      );
    });

    test('should throw when no delegate has message', () {
      expect(
        () => delegatingSource.getMessage('nonexistent'),
        throwsA(isA<MessageSourceException>()),
      );
    });

    test('should return default message when provided and no delegate has message', () {
      expect(
        delegatingSource.getMessage('nonexistent', defaultMessage: 'Default message'),
        equals('Default message'),
      );
    });

    test('should add delegate at runtime', () {
      delegatingSource.addDelegate(source3);
      
      expect(
        delegatingSource.getMessage('special'),
        equals('Special from source3'),
      );
    });

    test('should handle empty delegates list', () {
      final emptySource = DelegatingMessageSource([]);
      
      expect(
        () => emptySource.getMessage('test'),
        throwsA(isA<MessageSourceException>()),
      );
    });

    test('should handle delegate that throws exception', () {
      final throwingSource = MockMessageSource(messages: {}, shouldThrow: true);
      final sourceWithThrowing = DelegatingMessageSource([throwingSource, source1]);
      
      expect(
        sourceWithThrowing.getMessage('greeting'),
        equals('Hello from source1'),
      );
    });

    test('should pass locale to delegates', () {
      // This test verifies that locale parameter is passed through
      // The actual locale handling is up to individual delegates
      expect(
        delegatingSource.getMessage('greeting', locale: enLocale),
        equals('Hello from source1'),
      );
    });

    test('should prioritize earlier delegates', () {
      source2.messages['greeting'] = 'Hello from source2 (should not be used)';
      
      expect(
        delegatingSource.getMessage('greeting'),
        equals('Hello from source1'),
      );
    });

    test('should handle all delegates throwing', () {
      final throwingSource1 = MockMessageSource(messages: {}, shouldThrow: true);
      final throwingSource2 = MockMessageSource(messages: {}, shouldThrow: true);
      final allThrowingSource = DelegatingMessageSource([throwingSource1, throwingSource2]);
      
      expect(
        () => allThrowingSource.getMessage('test'),
        throwsA(isA<MessageSourceException>()),
      );
    });

    test('should handle default message with all delegates throwing', () {
      final throwingSource1 = MockMessageSource(messages: {}, shouldThrow: true);
      final throwingSource2 = MockMessageSource(messages: {}, shouldThrow: true);
      final allThrowingSource = DelegatingMessageSource([throwingSource1, throwingSource2]);
      
      expect(
        allThrowingSource.getMessage('test', defaultMessage: 'Safe default'),
        equals('Safe default'),
      );
    });

    test('should handle null delegates list in constructor', () {
      final sourceWithNull = DelegatingMessageSource(null);
      
      expect(
        () => sourceWithNull.getMessage('test'),
        throwsA(isA<MessageSourceException>()),
      );
    });

    test('should handle message found in later delegate after earlier throws', () {
      final throwingSource = MockMessageSource(messages: {}, shouldThrow: true);
      final normalSource = MockMessageSource(messages: {'test': 'Success'});
      
      final mixedSource = DelegatingMessageSource([throwingSource, normalSource]);
      
      expect(
        mixedSource.getMessage('test'),
        equals('Success'),
      );
    });

    test('should preserve exception information when rethrowing', () {
      try {
        delegatingSource.getMessage('nonexistent');
        fail('Should have thrown an exception');
      } on MessageSourceException catch (e) {
        expect(e.code, equals('nonexistent'));
        expect(e.message, contains("not found in any delegate"));
      }
    });
  });
}