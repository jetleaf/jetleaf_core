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

// // test/pod_spec_context_test.dart
// import 'package:jetleaf_core/src/context/pod_registrar.dart';
// import 'package:jetleaf_lang/lang.dart';
// import 'package:test/test.dart';

// import '../_dependencies.dart';

// class TestPod {}

// void main() {
//   setUpAll(() async {
//     await setupRuntime();
//     return Future<void>.value();
//   });
  
//   group('PodSpecContext', () {
//     late PodSpecContext context;

//     setUp(() {
//       context = PodSpecContext();
//     });

//     test('pod should throw UnimplementedError', () {
//       expect(
//         () => context.pod<TestPod>(Class<TestPod>()),
//         throwsA(isA<UnimplementedError>()),
//       );
//     });

//     test('pod with name should throw UnimplementedError', () {
//       expect(
//         () => context.pod<TestPod>(Class<TestPod>(), name: 'test'),
//         throwsA(isA<UnimplementedError>()),
//       );
//     });

//     test('provider should throw UnimplementedError', () {
//       expect(
//         () => context.provider<TestPod>(Class<TestPod>()),
//         throwsA(isA<UnimplementedError>()),
//       );
//     });

//     test('provider with name should throw UnimplementedError', () {
//       expect(
//         () => context.provider<TestPod>(Class<TestPod>(), name: 'test'),
//         throwsA(isA<UnimplementedError>()),
//       );
//     });
//   });
// }