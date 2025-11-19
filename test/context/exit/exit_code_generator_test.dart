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

// test/event/exit_code_generators_test.dart
import 'package:jetleaf_core/src/context/exit_code/exit_code.dart';
import 'package:jetleaf_core/src/context/exit_code/exit_code_generator.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../../_dependencies.dart';

class TestException extends RuntimeException {
  TestException(super.message);

  @override
  String toString() => 'TestException: $message';
}

class TestExitCodeGenerator implements ExitCodeGenerator {
  final int code;
  
  TestExitCodeGenerator(this.code);
  
  @override
  int getExitCode() => code;

  @override
  String getPackageName() => "test";
}

class TestExitCodeExceptionHandler implements ExitCodeExceptionHandler {
  final int code;
  
  TestExitCodeExceptionHandler(this.code);
  
  @override
  int getExitCode(Exception exception) => code;
}

class OrderedExitCodeGenerator implements ExitCodeGenerator, Ordered {
  final int code;
  final int order;
  
  OrderedExitCodeGenerator(this.code, this.order);
  
  @override
  int getExitCode() => code;

  @override
  int getOrder() => order;

  @override
  String getPackageName() => "test";
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });
  
  group('ExitCodeGenerators', () {
    late ExitCodeGenerators generators;

    setUp(() {
      generators = ExitCodeGenerators();
    });

    test('should be iterable', () {
      final generator = TestExitCodeGenerator(0);
      generators.addGenerator(generator);
      
      expect(generators, contains(generator));
      expect(generators.iterator, isA<Iterator<ExitCodeGenerator>>());
    });

    test('should add single mapper', () {
      final exception = TestException("");
      final mapper = TestExitCodeExceptionHandler(42);
      
      generators.add(exception, mapper);
      
      final exitCode = generators.getExitCode();
      expect(exitCode, 42);
    });

    test('should add multiple mappers', () {
      final exception = TestException("");
      final mappers = [
        TestExitCodeExceptionHandler(0),
        TestExitCodeExceptionHandler(1),
      ];
      
      generators.addAll(exception, mappers);
      
      final exitCode = generators.getExitCode();
      expect(exitCode, 1); // First non-zero
    });

    test('should add all generators', () {
      final generatorList = [
        TestExitCodeGenerator(0),
        TestExitCodeGenerator(2),
      ];
      
      generators.addAllGenerators(generatorList);
      
      final exitCode = generators.getExitCode();
      expect(exitCode, 2);
    });

    test('should order generators by priority', () {
      final lowPriority = OrderedExitCodeGenerator(1, 100);
      final highPriority = OrderedExitCodeGenerator(2, -100);
      
      generators.addGenerator(lowPriority);
      generators.addGenerator(highPriority);
      
      // Should return first non-zero (high priority first due to ordering)
      final exitCode = generators.getExitCode();
      expect(exitCode, 2);
    });

    test('should return 0 when all generators return 0', () {
      generators.addGenerator(TestExitCodeGenerator(0));
      generators.addGenerator(TestExitCodeGenerator(0));
      
      expect(generators.getExitCode(), 0);
    });

    test('should return first non-zero exit code', () {
      generators.addGenerator(TestExitCodeGenerator(0));
      generators.addGenerator(TestExitCodeGenerator(3));
      generators.addGenerator(TestExitCodeGenerator(5));
      
      expect(generators.getExitCode(), 3);
    });

    test('should handle generator exceptions and return 1', () {
      final throwingGenerator = _ThrowingExitCodeGenerator();
      generators.addGenerator(throwingGenerator);
      
      expect(generators.getExitCode(), 1);
    });

    test('should handle empty generators', () {
      expect(generators.getExitCode(), 0);
    });
  });
}

class _ThrowingExitCodeGenerator implements ExitCodeGenerator {
  @override
  int getExitCode() {
    throw TestException('Generator failed');
  }

  @override
  String getPackageName() => "test";
}