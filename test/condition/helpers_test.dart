import 'package:jetleaf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Version', () {
    test('should parse version strings correctly', () {
      expect(Version.parse('3.1.4'), equals(Version(3, 1, 4)));
      expect(Version.parse('2.0'), equals(Version(2, 0, 0)));
      expect(Version.parse('1'), equals(Version(1, 0, 0)));
    });

    test('should compare versions correctly', () {
      final v1 = Version(3, 1, 4);
      final v2 = Version(3, 2, 0);
      final v3 = Version(3, 1, 4);

      expect(v1 < v2, isTrue);
      expect(v2 > v1, isTrue);
      expect(v1 == v3, isTrue);
      expect(v1 >= v3, isTrue);
      expect(v1 <= v3, isTrue);
    });

    test('should handle major version differences', () {
      expect(Version(4, 0, 0) > Version(3, 9, 9), isTrue);
      expect(Version(2, 0, 0) < Version(3, 0, 0), isTrue);
    });

    test('should handle minor version differences', () {
      expect(Version(3, 2, 0) > Version(3, 1, 9), isTrue);
      expect(Version(3, 0, 0) < Version(3, 1, 0), isTrue);
    });

    test('should handle patch version differences', () {
      expect(Version(3, 1, 5) > Version(3, 1, 4), isTrue);
      expect(Version(3, 1, 0) < Version(3, 1, 1), isTrue);
    });

    test('should convert to string correctly', () {
      expect(Version(3, 1, 4).toString(), equals('3.1.4'));
      expect(Version(2, 0, 0).toString(), equals('2.0.0'));
    });

    test('should implement equality correctly', () {
      final v1 = Version(3, 1, 4);
      final v2 = Version(3, 1, 4);
      final v3 = Version(3, 1, 5);

      expect(v1, equals(v2));
      expect(v1, isNot(equals(v3)));
      expect(v1.hashCode, equals(v2.hashCode));
    });
  });

  group('VersionRange', () {
    test('should create range with start and end', () {
      final range = VersionRange(
        start: Version(3, 0, 0),
        end: Version(4, 0, 0),
      );

      expect(range.contains(Version(3, 5, 0)), isTrue);
      expect(range.contains(Version(4, 0, 0)), isFalse);
      expect(range.contains(Version(2, 9, 0)), isFalse);
    });

    test('should handle open-ended ranges', () {
      final rangeStart = VersionRange(start: Version(3, 0, 0));
      expect(rangeStart.contains(Version(5, 0, 0)), isTrue);
      expect(rangeStart.contains(Version(2, 9, 0)), isFalse);

      final rangeEnd = VersionRange(end: Version(4, 0, 0));
      expect(rangeEnd.contains(Version(3, 5, 0)), isTrue);
      expect(rangeEnd.contains(Version(4, 0, 0)), isFalse);
    });

    test('should parse caret ranges (^3.0.0)', () {
      final range = VersionRange.parse('^3.0.0');
      
      expect(range.contains(Version(3, 0, 0)), isTrue);
      expect(range.contains(Version(3, 5, 9)), isTrue);
      expect(range.contains(Version(3, 9, 9)), isTrue);
      expect(range.contains(Version(4, 0, 0)), isFalse);
      expect(range.contains(Version(2, 9, 9)), isFalse);
    });

    test('should parse tilde ranges (~3.0.0)', () {
      final range = VersionRange.parse('~3.0.0');
      
      expect(range.contains(Version(3, 0, 0)), isTrue);
      expect(range.contains(Version(3, 0, 9)), isTrue);
      expect(range.contains(Version(3, 1, 0)), isFalse);
      expect(range.contains(Version(2, 9, 9)), isFalse);
    });

    test('should parse dash ranges (2.9.0 - 3.1.0)', () {
      final range = VersionRange.parse('2.9.0 - 3.1.0');
      
      expect(range.contains(Version(2, 9, 0)), isTrue);
      expect(range.contains(Version(3, 0, 0)), isTrue);
      expect(range.contains(Version(3, 1, 0)), isFalse);
      expect(range.contains(Version(2, 8, 9)), isFalse);
    });

    test('should parse >= operator', () {
      final range = VersionRange.parse('>=2.9.0');
      
      expect(range.contains(Version(2, 9, 0)), isTrue);
      expect(range.contains(Version(3, 0, 0)), isTrue);
      expect(range.contains(Version(2, 8, 9)), isFalse);
    });

    test('should parse < operator', () {
      final range = VersionRange.parse('<3.1.0');
      
      expect(range.contains(Version(3, 0, 9)), isTrue);
      expect(range.contains(Version(3, 1, 0)), isFalse);
      expect(range.contains(Version(3, 2, 0)), isFalse);
    });

    test('should parse combined operators (>=2.9.0 <3.1.0)', () {
      final range = VersionRange.parse('>=2.9.0 <3.1.0');
      
      expect(range.contains(Version(2, 9, 0)), isTrue);
      expect(range.contains(Version(3, 0, 0)), isTrue);
      expect(range.contains(Version(3, 1, 0)), isFalse);
      expect(range.contains(Version(2, 8, 9)), isFalse);
    });

    test('should parse exact version (=3.0.0)', () {
      final range = VersionRange.parse('=3.0.0');
      
      expect(range.contains(Version(3, 0, 0)), isTrue);
      expect(range.contains(Version(3, 0, 1)), isFalse);
      expect(range.contains(Version(2, 9, 9)), isFalse);
    });

    test('should handle whitespace in range strings', () {
      final range1 = VersionRange.parse('  >=2.9.0   <3.1.0  ');
      expect(range1.contains(Version(3, 0, 0)), isTrue);

      final range2 = VersionRange.parse('  ^3.0.0  ');
      expect(range2.contains(Version(3, 5, 0)), isTrue);
    });

    test('should convert to string correctly', () {
      expect(
        VersionRange(start: Version(3, 0, 0), end: Version(4, 0, 0)).toString(),
        equals('3.0.0 - 4.0.0'),
      );
      expect(
        VersionRange(start: Version(3, 0, 0)).toString(),
        equals('>= 3.0.0'),
      );
      expect(
        VersionRange(end: Version(4, 0, 0)).toString(),
        equals('< 4.0.0'),
      );
      expect(
        VersionRange().toString(),
        equals('any'),
      );
    });

    test('should implement equality correctly', () {
      final r1 = VersionRange(start: Version(3, 0, 0), end: Version(4, 0, 0));
      final r2 = VersionRange(start: Version(3, 0, 0), end: Version(4, 0, 0));
      final r3 = VersionRange(start: Version(3, 0, 0), end: Version(5, 0, 0));

      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3)));
      expect(r1.hashCode, equals(r2.hashCode));
    });
  });
}