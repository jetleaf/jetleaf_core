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

import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_lang/mock.dart';
import 'package:jetleaf_lang/reflection.dart';

Future<void> setupRuntime({List<String> packagesToExclude = const [], List<String> filesToLoad = const []}) async {
  final scan = await MockRuntimeScanner(
    onInfo: (msg) => print('[MOCK INFO] $msg'),
    onWarning: (msg) => print('[MOCK WARNING] $msg'),
    onError: (msg) => print('[MOCK ERROR] $msg'),
    forceLoadFiles: filesToLoad.map((file) => File(file).absolute).toList(),
    libraryGeneratorFactory: (params) => InternalMockLibraryGenerator(
      mirrorSystem: params.mirrorSystem,
      forceLoadedMirrors: params.forceLoadedMirrors,
      onInfo: (msg) => print('[MOCK INFO] $msg'),
      onWarning: (msg) => print('[MOCK WARNING] $msg'),
      onError: (msg) => print('[MOCK ERROR] $msg'),
      configuration: params.configuration,
      packages: params.packages
    )
  ).scan('output', RuntimeScannerConfiguration(
    skipTests: true,
    packagesToExclude: [
      "test",
      "lints",
      "args",
      "path",
      "source_span",
      "stack_trace",
      "stream_channel",
      "pool",
      "test_api",
      "test_core",
      "boolean_selector",
      "term_glyph",
      "string_scanner",
      "package:collection/src/list_extensions.dart",
      ...packagesToExclude
    ],
    // enableTreeShaking: true,
    // writeDeclarationsToFiles: true
  ));
  Runtime.register(scan.getContext());
}