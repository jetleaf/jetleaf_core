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