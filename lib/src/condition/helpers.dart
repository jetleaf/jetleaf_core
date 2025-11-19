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

import 'package:jetleaf_lang/lang.dart';

/// {@template range}
/// Represents a simple semantic version range in **Jetleaf**.
///
/// A [Range] defines an inclusive start version and an exclusive end version.
/// It is used by the framework to determine whether a certain version 
/// (for example, Dart SDK version) satisfies a condition.
///
/// ### Usage Example:
/// ```dart
/// final range = Range(
///   start: Version(3, 0, 0),
///   end: Version(4, 0, 0),
/// );
///
/// print(range.contains(Version(3, 2, 1))); // true
/// print(range.contains(Version(4, 0, 0))); // false
/// ```
/// {@endtemplate}
class VersionRange with EqualsAndHashCode {
  /// The inclusive start of the version range.
  final Version? start;

  /// The exclusive end of the version range.
  final Version? end;

  /// {@macro range}
  ///
  /// Both [start] and [end] are optional. If [start] is null, the range has 
  /// no lower bound. If [end] is null, the range has no upper bound.
  const VersionRange({this.start, this.end});

  /// {@template version_range_parse}
  /// Parses a semantic version range string into a [VersionRange].
  ///
  /// This factory constructor supports several common version range syntaxes,
  /// inspired by npm, Cargo, and pub versioning rules.  
  ///
  /// The parser understands the following formats:
  ///
  /// ---
  /// ### **1. Caret Ranges**
  ///  
  /// Syntax:
  /// ```
  /// ^3.0.0
  /// ```
  /// Meaning:
  /// - Start at `3.0.0` (inclusive)
  /// - Allow any compatible future minor/patch release
  /// - Stop before `4.0.0`
  ///
  /// Parses as:
  /// ```dart
  /// VersionRange(start: 3.0.0, end: 4.0.0)
  /// ```
  ///
  /// ---
  /// ### **2. Tilde Ranges**
  ///
  /// Syntax:
  /// ```
  /// ~3.0.0
  /// ```
  /// Meaning:
  /// - Start at `3.0.0`  
  /// - Allow any patch update within the same minor version  
  /// - Stop before `3.1.0`  
  ///
  /// Parses as:
  /// ```dart
  /// VersionRange(start: 3.0.0, end: 3.1.0)
  /// ```
  ///
  /// ---
  /// ### **3. Dash Ranges**
  ///
  /// Syntax:
  /// ```
  /// 2.9.0 - 3.1.0
  /// ```
  /// Meaning:
  /// - Start at `2.9.0`
  /// - End at `3.1.0`
  ///
  /// Parses as:
  /// ```dart
  /// VersionRange(start: 2.9.0, end: 3.1.0)
  /// ```
  ///
  /// ---
  /// ### **4. Comparator Ranges**
  ///
  /// Syntax:
  /// ```
  /// >=2.9.0 <3.1.0
  /// ```
  /// Supported operators:
  /// ```
  /// >=   >   <=   <   =
  /// ```
  ///
  /// Behavior:
  /// - `>=` and `>` set the `start` bound  
  /// - `<=` and `<` set the `end` bound  
  /// - `=` is interpreted as:  
  ///   *“equals this exact version, inclusive of patch bump”*,  
  ///   meaning:
  ///
  ///   ```
  ///   =3.0.0    →    >=3.0.0 <3.0.1
  ///   ```
  ///
  /// ---
  /// ### **5. Default Case**
  ///
  /// If no operators or special syntax is found, the method returns a range with
  /// whatever start/end constraints were successfully parsed.
  ///
  /// ---
  /// ### Example
  /// ```dart
  /// final range = VersionRange.parse(">=1.2.0 <2.0.0");
  /// print(range.start); // 1.2.0
  /// print(range.end);   // 2.0.0
  /// ```
  ///
  /// This parser is intentionally permissive and does not throw unless the
  /// underlying [Version.parse] fails. Unsupported formats simply return a
  /// `VersionRange` with the discovered constraints.
  ///
  /// {@endtemplate}
  factory VersionRange.parse(String rangeString) {
    final trimmed = rangeString.trim();
    
    // Handle caret ranges: ^3.0.0 means >=3.0.0 <4.0.0
    if (trimmed.startsWith('^')) {
      final version = Version.parse(trimmed.substring(1));
      return VersionRange(
        start: version,
        end: Version(version.major + 1, 0, 0),
      );
    }
    
    // Handle tilde ranges: ~3.0.0 means >=3.0.0 <3.1.0
    if (trimmed.startsWith('~')) {
      final version = Version.parse(trimmed.substring(1));
      return VersionRange(
        start: version,
        end: Version(version.major, version.minor + 1, 0),
      );
    }
    
    // Handle dash ranges: 2.9.0 - 3.1.0
    if (trimmed.contains(' - ')) {
      final parts = trimmed.split(' - ');
      return VersionRange(
        start: Version.parse(parts[0].trim()),
        end: Version.parse(parts[1].trim()),
      );
    }
    
    // Handle comparison operators: >=2.9.0 <3.1.0
    final operators = ['>=', '<=', '>', '<', '='];
    Version? start;
    Version? end;
    
    var remaining = trimmed;
    while (remaining.isNotEmpty) {
      remaining = remaining.trim();
      
      String? foundOp;
      for (final op in operators) {
        if (remaining.startsWith(op)) {
          foundOp = op;
          break;
        }
      }
      
      if (foundOp == null) break;
      
      remaining = remaining.substring(foundOp.length).trim();
      
      // Extract version number
      final versionMatch = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(remaining);
      if (versionMatch == null) break;
      
      final version = Version.parse(versionMatch.group(0)!);
      remaining = remaining.substring(versionMatch.group(0)!.length);
      
      // Apply operator
      switch (foundOp) {
        case '>=':
        case '>':
          start = version;
          break;
        case '<=':
        case '<':
          end = version;
          break;
        case '=':
          start = version;
          end = Version(version.major, version.minor, version.patch + 1);
          break;
      }
    }
    
    return VersionRange(start: start, end: end);
  }

  /// Checks if a [version] is within this range.
  ///
  /// Returns `true` if the version is greater than or equal to [start] (if provided)
  /// and less than [end] (if provided). Otherwise returns `false`.
  ///
  /// ### Example:
  /// ```dart
  /// final range = Range(start: Version(2,0,0), end: Version(3,0,0));
  /// print(range.contains(Version(2,5,0))); // true
  /// print(range.contains(Version(3,0,0))); // false
  /// ```
  bool contains(Version version) {
    final afterStart = start == null || version >= start!;
    final beforeEnd = end == null || version < end!;
    return afterStart && beforeEnd;
  }

  /// Returns `true` if two [VersionRange]s overlap.
  ///
  /// Overlap rules:
  /// - If both have `start` and `end`: intervals intersect
  /// - Open-ended ranges are treated as unbounded on that side
  /// - Exact-match ranges (`=1.2.3` → [1.2.3, 1.2.4)) work naturally
  ///
  /// Examples:
  ///   [>=1.0.0 <2.0.0] intersects [^1.5.0] → true
  ///   [>=2.0.0 <3.0.0] intersects [<1.0.0] → false
  ///   [^3.0.0] intersects [3.5.0] → true
  bool matches(VersionRange b) {
    final a = this;
  
    // Treat null start as "unbounded below"
    final aStart = a.start;
    final bStart = b.start;

    // Treat null end as "unbounded above"
    final aEnd = a.end;
    final bEnd = b.end;

    // Two ranges overlap if:
    //
    //   (a.start < b.end) AND (b.start < a.end)
    //
    // Null-end means infinite.
    final aStartsBeforeBEnds = bEnd == null || aStart == null || aStart < bEnd;
    final bStartsBeforeAEnds = aEnd == null || bStart == null || bStart < aEnd;

    return aStartsBeforeBEnds && bStartsBeforeAEnds;
  }

  @override
  List<Object?> equalizedProperties() => [start, end];

  @override
  String toString() {
    if (start != null && end != null) {
      return '${start.toString()} - ${end.toString()}';
    } else if (start != null) {
      return '>= ${start.toString()}';
    } else if (end != null) {
      return '< ${end.toString()}';
    }
    return 'any';
  }
}

/// {@template version}
/// Represents a semantic version in **Jetleaf** with major, minor, and patch 
/// components.
///
/// This class is used to define precise versions and to compare versions when 
/// evaluating version ranges or conditional processing.
///
/// ### Usage Example:
/// ```dart
/// final version = Version(3, 1, 4);
/// final other = Version.parse('3.2.0');
///
/// print(version < other); // true
/// print(version >= Version(3,1,0)); // true
/// ```
/// {@endtemplate}
class Version with EqualsAndHashCode implements Comparable<Version> {
  /// The major version component.
  final int major;

  /// The minor version component.
  final int minor;

  /// The patch version component.
  final int patch;

  /// {@macro version}
  const Version(this.major, this.minor, this.patch);

  /// Parses a version string (e.g., '3.1.4') into a [Version] instance.
  ///
  /// Missing minor or patch components default to 0.
  ///
  /// ### Example:
  /// ```dart
  /// final version = Version.parse('3.2'); // Version(3, 2, 0)
  /// ```
  factory Version.parse(String version) {
    final parts = version.split('.');
    return Version(
      int.parse(parts[0]),
      parts.length > 1 ? int.parse(parts[1]) : 0,
      parts.length > 2 ? int.parse(parts[2]) : 0,
    );
  }

  /// Returns `true` if this version is greater than or equal to [other].
  bool operator >=(Version other) => compareTo(other) >= 0;

  /// Returns `true` if this version is less than or equal to [other].
  bool operator <=(Version other) => compareTo(other) <= 0;

  /// Returns `true` if this version is strictly greater than [other].
  bool operator >(Version other) => compareTo(other) > 0;

  /// Returns `true` if this version is strictly less than [other].
  bool operator <(Version other) => compareTo(other) < 0;

  @override
  int compareTo(Version other) {
    if (major != other.major) return major - other.major;
    if (minor != other.minor) return minor - other.minor;
    return patch - other.patch;
  }

  @override
  List<Object?> equalizedProperties() => [major, minor, patch];

  @override
  String toString() => '$major.$minor.$patch';
}