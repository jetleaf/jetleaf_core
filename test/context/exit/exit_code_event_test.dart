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

// test/event/exit_code_event_test.dart
import 'package:jetleaf_core/src/context/event/application_event.dart';
import 'package:jetleaf_core/src/context/exit_code/exit_code.dart';
import 'package:test/test.dart';

void main() {
  group('ExitCodeEvent', () {
    test('should create with source and exit code', () {
      final source = Object();
      const exitCode = 42;
      
      final event = ExitCodeEvent(source, exitCode);
      
      expect(event.getSource(), same(source));
      expect(event.getExitCode(), exitCode);
      expect(event, isA<ApplicationEvent>());
    });

    test('should handle zero exit code', () {
      final event = ExitCodeEvent(Object(), 0);
      expect(event.getExitCode(), 0);
    });

    test('should handle negative exit code', () {
      final event = ExitCodeEvent(Object(), -1);
      expect(event.getExitCode(), -1);
    });

    test('should handle maximum integer exit code', () {
      final event = ExitCodeEvent(Object(), 255);
      expect(event.getExitCode(), 255);
    });


    test('toString should include exit code', () {
      const exitCode = 127;
      final event = ExitCodeEvent(Object(), exitCode);
      
      expect(event.toString(), contains('ExitCodeEvent'));
      expect(event.toString(), contains('exitCode: $exitCode'));
    });
  });
}