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

// test/event/application_event_test.dart
import 'package:jetleaf_core/src/context/event/application_event.dart';
import 'package:test/test.dart';

class TestApplicationEvent extends ApplicationEvent {
  TestApplicationEvent(super.source, [super.timestamp]);
  TestApplicationEvent.withClock(super.source, super.clock) : super.withClock();

  @override
  String getPackageName() => "test";
}

void main() {
  group('ApplicationEvent', () {
    test('should create with system clock', () {
      final source = Object();
      final event = TestApplicationEvent(source);
      
      expect(event.getSource(), same(source));
      expect(event.getTimestamp(), isA<DateTime>());
      expect(event.getTimestamp().difference(DateTime.now()).inSeconds, lessThanOrEqualTo(1));
    });

    test('should create with custom timestamp', () {
      final source = Object();
      final customTimestamp = DateTime(2023, 1, 1, 12, 0, 0);
      final event = TestApplicationEvent(source, customTimestamp);
      
      expect(event.getSource(), same(source));
      expect(event.getTimestamp(), customTimestamp);
    });

    test('should create with custom clock function', () {
      final source = Object();
      final fixedTime = DateTime(2023, 1, 1, 12, 0, 0);
      final event = TestApplicationEvent.withClock(source, () => fixedTime);
      
      expect(event.getSource(), same(source));
      expect(event.getTimestamp(), fixedTime);
    });

    test('should inherit from EventObject', () {
      final source = Object();
      final event = TestApplicationEvent(source);
      
      expect(event, isA<EventObject>());
      expect(event.getSource(), same(source));
      expect(event.getTimestamp(), isA<DateTime>());
    });

    test('toString should include runtime type', () {
      final source = Object();
      final event = TestApplicationEvent(source);
      
      expect(event.toString(), contains('TestApplicationEvent'));
    });
  });
}