// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2026 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/context.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

class TestModule implements ApplicationModule {
  bool configured = false;

  @override
  Future<void> configure(ApplicationContext context) async {
    configured = true;
  }

  @override
  List<Object?> equalizedProperties() => [TestModule];
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('ApplicationModule', () {
    test('should configure context', () async {
      final customizer = TestModule();
      final context = AnnotationConfigApplicationContext();

      await customizer.configure(context);

      expect(customizer.configured, isTrue);
    });
  });
}