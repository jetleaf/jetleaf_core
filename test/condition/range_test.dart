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

import 'package:jetleaf_core/src/condition/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('Range', () {
    test('should create range with start and end', () {
      const start = Version(1, 0, 0);
      const end = Version(2, 0, 0);
      const range = VersionRange(start: start, end: end);
      
      expect(range.start, start);
      expect(range.end, end);
    });

    test('should create range with only start', () {
      const start = Version(1, 0, 0);
      const range = VersionRange(start: start);
      
      expect(range.start, start);
      expect(range.end, isNull);
    });

    test('should create range with only end', () {
      const end = Version(2, 0, 0);
      const range = VersionRange(end: end);
      
      expect(range.start, isNull);
      expect(range.end, end);
    });

    test('should create range with no bounds', () {
      const range = VersionRange();
      
      expect(range.start, isNull);
      expect(range.end, isNull);
    });

    group('contains', () {
      test('should contain version within bounded range', () {
        const range = VersionRange(start: Version(1, 0, 0), end: Version(2, 0, 0));
        expect(range.contains(Version(1, 0, 0)), isTrue);
        expect(range.contains(Version(1, 5, 0)), isTrue);
        expect(range.contains(Version(1, 9, 9)), isTrue);
      });

      test('should not contain version outside bounded range', () {
        const range = VersionRange(start: Version(1, 0, 0), end: Version(2, 0, 0));
        expect(range.contains(Version(0, 9, 9)), isFalse);
        expect(range.contains(Version(2, 0, 0)), isFalse);
        expect(range.contains(Version(2, 0, 1)), isFalse);
      });

      test('should contain version in start-only range', () {
        const range = VersionRange(start: Version(1, 0, 0));
        expect(range.contains(Version(1, 0, 0)), isTrue);
        expect(range.contains(Version(2, 0, 0)), isTrue);
        expect(range.contains(Version(999, 0, 0)), isTrue);
      });

      test('should not contain version in start-only range', () {
        const range = VersionRange(start: Version(1, 0, 0));
        expect(range.contains(Version(0, 9, 9)), isFalse);
      });

      test('should contain version in end-only range', () {
        const range = VersionRange(end: Version(2, 0, 0));
        expect(range.contains(Version(0, 0, 0)), isTrue);
        expect(range.contains(Version(1, 9, 9)), isTrue);
      });

      test('should not contain version in end-only range', () {
        const range = VersionRange(end: Version(2, 0, 0));
        expect(range.contains(Version(2, 0, 0)), isFalse);
        expect(range.contains(Version(2, 0, 1)), isFalse);
      });

      test('should contain any version in unbounded range', () {
        const range = VersionRange();
        expect(range.contains(Version(0, 0, 0)), isTrue);
        expect(range.contains(Version(1, 0, 0)), isTrue);
        expect(range.contains(Version(999, 999, 999)), isTrue);
      });

      test('should handle edge cases with exact bounds', () {
        const range = VersionRange(start: Version(1, 0, 0), end: Version(2, 0, 0));
        expect(range.contains(Version(1, 0, 0)), isTrue); // inclusive start
        expect(range.contains(Version(2, 0, 0)), isFalse); // exclusive end
      });

      test('should handle zero version correctly', () {
        const rangeWithZero = VersionRange(start: Version(0, 0, 0), end: Version(1, 0, 0));
        expect(rangeWithZero.contains(Version(0, 0, 0)), isTrue);
        expect(rangeWithZero.contains(Version(0, 0, 1)), isTrue);
        expect(rangeWithZero.contains(Version(0, 1, 0)), isTrue);
      });
    });

    group('toString', () {
      test('should format bounded range correctly', () {
        const range = VersionRange(start: Version(1, 0, 0), end: Version(2, 0, 0));
        expect(range.toString(), '1.0.0 - 2.0.0');
      });

      test('should format start-only range correctly', () {
        const range = VersionRange(start: Version(1, 0, 0));
        expect(range.toString(), '>= 1.0.0');
      });

      test('should format end-only range correctly', () {
        const range = VersionRange(end: Version(2, 0, 0));
        expect(range.toString(), '< 2.0.0');
      });

      test('should format unbounded range correctly', () {
        const range = VersionRange();
        expect(range.toString(), 'any');
      });

      test('should format ranges with different version formats', () {
        const range1 = VersionRange(start: Version(0, 0, 0), end: Version(1, 2, 3));
        const range2 = VersionRange(start: Version(10, 20, 30));
        
        expect(range1.toString(), '0.0.0 - 1.2.3');
        expect(range2.toString(), '>= 10.20.30');
      });
    });

    test('should handle null bounds in contains method', () {
      const rangeWithNullStart = VersionRange(start: null, end: Version(2, 0, 0));
      const rangeWithNullEnd = VersionRange(start: Version(1, 0, 0), end: null);
      const rangeWithBothNull = VersionRange(start: null, end: null);
      
      expect(rangeWithNullStart.contains(Version(0, 0, 0)), isTrue);
      expect(rangeWithNullStart.contains(Version(2, 0, 0)), isFalse);
      
      expect(rangeWithNullEnd.contains(Version(1, 0, 0)), isTrue);
      expect(rangeWithNullEnd.contains(Version(0, 9, 9)), isFalse);
      
      expect(rangeWithBothNull.contains(Version(0, 0, 0)), isTrue);
      expect(rangeWithBothNull.contains(Version(999, 999, 999)), isTrue);
    });
  });
}