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
  group('Version', () {
    test('should create version with correct values', () {
      const version = Version(1, 2, 3);
      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
    });

    test('should parse version string correctly', () {
      expect(Version.parse('1.2.3'), const Version(1, 2, 3));
      expect(Version.parse('0.0.0'), const Version(0, 0, 0));
      expect(Version.parse('10.20.30'), const Version(10, 20, 30));
    });

    test('should parse version string with missing parts (defaults to 0)', () {
      expect(Version.parse('1'), const Version(1, 0, 0));
      expect(Version.parse('1.2'), const Version(1, 2, 0));
      expect(Version.parse('1.2.3'), const Version(1, 2, 3));
    });

    test('should throw FormatException when parsing invalid version string', () {
      expect(() => Version.parse(''), throwsFormatException);
      expect(() => Version.parse('a.b.c'), throwsFormatException);
      expect(() => Version.parse('1.2.a'), throwsFormatException);
      expect(() => Version.parse('1.a.3'), throwsFormatException);
      expect(() => Version.parse('a.2.3'), throwsFormatException);
    });

    test('should compare versions correctly', () {
      const v1 = Version(1, 0, 0);
      const v2 = Version(1, 0, 0);
      const v3 = Version(1, 0, 1);
      const v4 = Version(1, 1, 0);
      const v5 = Version(2, 0, 0);

      expect(v1.compareTo(v2), 0);
      expect(v1.compareTo(v3), -1);
      expect(v3.compareTo(v1), 1);
      expect(v1.compareTo(v4), -1);
      expect(v1.compareTo(v5), -1);
      expect(v5.compareTo(v1), 1);
    });

    test('should implement equality operators correctly', () {
      const v1 = Version(1, 0, 0);
      const v2 = Version(1, 0, 0);
      const v3 = Version(1, 0, 1);
      const v4 = Version(2, 0, 0);

      expect(v1 == v2, isTrue);
      expect(v1 == v3, isFalse);
      
      expect(v1 < v3, isTrue);
      expect(v1 < v4, isTrue);
      expect(v4 > v1, isTrue);
      
      expect(v1 <= v2, isTrue);
      expect(v1 <= v3, isTrue);
      expect(v3 <= v1, isFalse);
      
      expect(v1 >= v2, isTrue);
      expect(v3 >= v1, isTrue);
      expect(v1 >= v3, isFalse);
    });

    test('should convert to string correctly', () {
      expect(const Version(1, 2, 3).toString(), '1.2.3');
      expect(const Version(0, 0, 0).toString(), '0.0.0');
      expect(const Version(10, 20, 30).toString(), '10.20.30');
    });

    test('should handle edge cases with zero values', () {
      const zeroVersion = Version(0, 0, 0);
      const version1 = Version(0, 0, 1);
      
      expect(zeroVersion < version1, isTrue);
      expect(zeroVersion.toString(), '0.0.0');
    });

    test('should handle large version numbers', () {
      const largeVersion = Version(999999, 999999, 999999);
      expect(largeVersion.toString(), '999999.999999.999999');
    });

    test('should be comparable with different version types', () {
      const majorDiff = Version(2, 0, 0);
      const minorDiff = Version(1, 1, 0);
      const patchDiff = Version(1, 0, 1);
      const base = Version(1, 0, 0);
      
      expect(base < majorDiff, isTrue);
      expect(base < minorDiff, isTrue);
      expect(base < patchDiff, isTrue);
    });
  });
}