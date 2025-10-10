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

// // test/event/application_context_event_test.dart
// import 'package:jetleaf_core/src/context/application_context.dart';
// import 'package:jetleaf_core/src/context/event/application_event.dart';
// import 'package:test/test.dart';

// import '../mock_application_context.dart';

// class TestApplicationContextEvent extends ApplicationContextEvent {
//   TestApplicationContextEvent(super.source);
// }

// void main() {
//   group('ApplicationContextEvent', () {
//     test('should require ApplicationContext source', () {
//       final context = MockApplicationContext();
//       final event = TestApplicationContextEvent(context);
      
//       expect(event.source, same(context));
//       expect(event.getSource(), same(context));
//     });

//     test('getApplicationContext should return the context', () {
//       final context = MockApplicationContext();
//       final event = TestApplicationContextEvent(context);
      
//       expect(event.getApplicationContext(), same(context));
//     });

//     test('getSource should return ApplicationContext', () {
//       final context = MockApplicationContext();
//       final event = TestApplicationContextEvent(context);
      
//       expect(event.getSource(), isA<ApplicationContext>());
//       expect(event.getSource(), same(context));
//     });

//     test('should inherit from ApplicationEvent', () {
//       final context = MockApplicationContext();
//       final event = TestApplicationContextEvent(context);
      
//       expect(event, isA<ApplicationEvent>());
//       expect(event, isA<EventObject>());
//     });
//   });
// }