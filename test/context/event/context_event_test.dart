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

// // test/event/context_events_test.dart
// import 'package:jetleaf_core/src/context/event/application_event.dart';
// import 'package:test/test.dart';

// import '../mock_application_context.dart';

// void main() {
//   group('Context Events', () {
//     final context = MockApplicationContext();

//     group('ContextClosedEvent', () {
//       test('should create with ApplicationContext source', () {
//         final event = ContextClosedEvent(context);
//         expect(event.source, same(context));
//         expect(event, isA<ApplicationContextEvent>());
//       });
//     });

//     group('ContextFailedEvent', () {
//       test('should create with ApplicationContext source', () {
//         final event = ContextFailedEvent(context);
//         expect(event.source, same(context));
//         expect(event, isA<ApplicationContextEvent>());
//       });
//     });

//     group('ContextReadyEvent', () {
//       test('should create with ApplicationContext source', () {
//         final event = ContextReadyEvent(context);
//         expect(event.source, same(context));
//         expect(event, isA<ApplicationContextEvent>());
//       });
//     });

//     group('ContextRefreshedEvent', () {
//       test('should create with ApplicationContext source', () {
//         final event = ContextRefreshedEvent(context);
//         expect(event.source, same(context));
//         expect(event, isA<ApplicationContextEvent>());
//       });
//     });

//     group('ContextRestartedEvent', () {
//       test('should create with ApplicationContext source', () {
//         final event = ContextRestartedEvent(context);
//         expect(event.source, same(context));
//         expect(event, isA<ApplicationContextEvent>());
//       });
//     });

//     group('ContextStartedEvent', () {
//       test('should create with ApplicationContext source', () {
//         final event = ContextStartedEvent(context);
//         expect(event.source, same(context));
//         expect(event, isA<ApplicationContextEvent>());
//       });
//     });

//     group('ContextStoppedEvent', () {
//       test('should create with ApplicationContext source', () {
//         final event = ContextStoppedEvent(context);
//         expect(event.source, same(context));
//         expect(event, isA<ApplicationContextEvent>());
//       });
//     });

//     test('all context events should have correct inheritance', () {
//       final events = [
//         ContextClosedEvent(context),
//         ContextFailedEvent(context),
//         ContextReadyEvent(context),
//         ContextRefreshedEvent(context),
//         ContextRestartedEvent(context),
//         ContextStartedEvent(context),
//         ContextStoppedEvent(context),
//       ];

//       for (final event in events) {
//         expect(event, isA<ApplicationContextEvent>());
//         expect(event, isA<ApplicationEvent>());
//         expect(event, isA<EventObject>());
//         expect(event.getSource(), same(context));
//         expect(event.getApplicationContext(), same(context));
//       }
//     });
//   });
// }