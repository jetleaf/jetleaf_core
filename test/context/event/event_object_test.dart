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

// test/event/event_object_test.dart
import 'package:jetleaf_core/src/context/event/application_event.dart';
import 'package:test/test.dart';

class TestEventObject extends EventObject {
  TestEventObject(super.source, [super.timestamp]);

  @override
  String getPackageName() => "test";
}

void main() {
  group('EventObject', () {
    test('should create with source and current timestamp', () {
      final source = Object();
      final event = TestEventObject(source);
      
      expect(event.getSource(), same(source));
      expect(event.getSource(), same(source));
      expect(event.getTimestamp(), isA<DateTime>());
      expect(event.getTimestamp(), isA<DateTime>());
      expect(event.getTimestamp().difference(DateTime.now()).inSeconds, lessThanOrEqualTo(1));
    });

    test('should create with custom timestamp', () {
      final source = Object();
      final customTimestamp = DateTime(2023, 1, 1, 12, 0, 0);
      final event = TestEventObject(source, customTimestamp);
      
      expect(event.getSource(), same(source));
      expect(event.getTimestamp(), customTimestamp);
    });

    test('toString should return formatted string', () {
      final source = Object();
      final timestamp = DateTime(2023, 1, 1, 12, 0, 0);
      final event = TestEventObject(source, timestamp);
      
      expect(event.toString(), contains('TestEventObject'));
      expect(event.toString(), contains('source: $source'));
      expect(event.toString(), contains('timestamp: $timestamp'));
    });

    test('should have different timestamps for sequential events', () async {
      final source = Object();
      final event1 = TestEventObject(source);
      await Future.delayed(const Duration(milliseconds: 10));
      final event2 = TestEventObject(source);
      
      expect(event2.getTimestamp().isAfter(event1.getTimestamp()), isTrue);
    });
  });
}