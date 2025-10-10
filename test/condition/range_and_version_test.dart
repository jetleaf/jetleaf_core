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
  group('Version and Range Integration', () {
    test('should work together correctly for complex scenarios', () {
      // Test various range scenarios
      const range1 = VersionRange(start: Version(1, 0, 0), end: Version(2, 0, 0));
      const range2 = VersionRange(start: Version(2, 0, 0)); // >= 2.0.0
      const range3 = VersionRange(end: Version(1, 0, 0)); // < 1.0.0

      expect(range1.contains(Version(1, 5, 0)), isTrue);
      expect(range1.contains(Version(2, 0, 0)), isFalse);
      
      expect(range2.contains(Version(2, 0, 0)), isTrue);
      expect(range2.contains(Version(3, 0, 0)), isTrue);
      expect(range2.contains(Version(1, 9, 9)), isFalse);
      
      expect(range3.contains(Version(0, 9, 9)), isTrue);
      expect(range3.contains(Version(1, 0, 0)), isFalse);
    });

    test('should handle edge cases with version comparison in ranges', () {
      const exactVersionRange = VersionRange(start: Version(1, 2, 3), end: Version(1, 2, 4));
      expect(exactVersionRange.contains(Version(1, 2, 3)), isTrue);
      expect(exactVersionRange.contains(Version(1, 2, 4)), isFalse);
    });

    test('should handle multiple range types with same versions', () {
      const version = Version(1, 0, 0);
      
      const rangeInclusive = VersionRange(start: version, end: Version(2, 0, 0));
      const rangeExclusive = VersionRange(end: version);
      
      expect(rangeInclusive.contains(version), isTrue);
      expect(rangeExclusive.contains(version), isFalse);
    });
  });
}