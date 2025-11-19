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

import 'package:jetleaf_env/env.dart';

/// {@template application_environment}
/// A concrete environment for standard JetLeaf applications.
///
/// This class extends [GlobalEnvironment] and serves as the default
/// runtime environment for most JetLeaf-based applications unless explicitly overridden.
///
/// It inherits all behavior from [GlobalEnvironment], including support for:
/// - System environment variables
/// - System properties (if available)
/// - Default property sources
/// - Active and default profiles
///
/// ### Example:
/// ```dart
/// final env = ApplicationEnvironment();
/// final port = env.getProperty('server.port');
/// print('Running on port: $port');
/// ```
///
/// You can customize this environment by registering new property sources or profiles
/// during the boot phase.
///
/// {@endtemplate}
class ApplicationEnvironment extends GlobalEnvironment {
  /// {@macro application_environment}
  ApplicationEnvironment() : super();
}