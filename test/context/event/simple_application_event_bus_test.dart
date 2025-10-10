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

// // test/event/simple_application_event_bus_test.dart
// import 'package:jetleaf_core/src/context/event/application_event.dart';
// import 'package:jetleaf_core/src/context/event/event_listener.dart';
// import 'package:jetleaf_core/src/context/event/simple_application_event_bus.dart';
// import 'package:test/test.dart';

// import '../mock_pod_factory.dart';

// class TestApplicationEvent extends ApplicationEvent {
//   TestApplicationEvent(super.source, [super.timestamp]);
// }

// class TestEventListener implements ApplicationEventListener<TestApplicationEvent> {
//   List<TestApplicationEvent> receivedEvents = [];

//   @override
//   void onApplicationEvent(TestApplicationEvent event) {
//     receivedEvents.add(event);
//   }

//   @override
//   bool supportsEventOf(ApplicationEvent event) => event is TestApplicationEvent;
// }

// void main() {
//   group('SimpleApplicationEventBus', () {
//     late SimpleApplicationEventBus bus;
//     late MockPodFactory podFactory;
//     late TestEventListener listener;
//     late TestApplicationEvent event;

//     setUp(() {
//       podFactory = MockPodFactory();
//       bus = SimpleApplicationEventBus(podFactory);
//       listener = TestEventListener();
//       event = TestApplicationEvent(Object());
//     });

//     test('should add listener directly', () async {
//       await bus.addApplicationListener(listener: listener);
      
//       await bus.onEvent(event);
//       expect(listener.receivedEvents, contains(event));
//     });

//     test('should add listener by pod name', () async {
//       final podListener = TestEventListener();
//       podFactory.addSingleton('testListener', podListener);
      
//       await bus.addApplicationListener(podName: 'testListener');
      
//       await bus.onEvent(event);
//       expect(podListener.receivedEvents, contains(event));
//     });

//     test('should handle both listener and podName parameters', () async {
//       final directListener = TestEventListener();
//       final podListener = TestEventListener();
//       podFactory.addSingleton('testListener', podListener);
      
//       await bus.addApplicationListener(listener: directListener);
//       await bus.addApplicationListener(podName: 'testListener');
      
//       await bus.onEvent(event);
//       expect(directListener.receivedEvents, contains(event));
//       expect(podListener.receivedEvents, contains(event));
//     });

//     test('should remove direct listener', () async {
//       await bus.addApplicationListener(listener: listener);
//       await bus.removeApplicationListener(listener: listener);
      
//       await bus.onEvent(event);
//       expect(listener.receivedEvents, isEmpty);
//     });

//     test('should remove listener by pod name', () async {
//       final podListener = TestEventListener();
//       podFactory.addSingleton('testListener', podListener);
      
//       await bus.addApplicationListener(podName: 'testListener');
//       await bus.removeApplicationListener(podName: 'testListener');
      
//       await bus.onEvent(event);
//       expect(podListener.receivedEvents, isEmpty);
//     });

//     test('should remove all listeners', () async {
//       final listener1 = TestEventListener();
//       final listener2 = TestEventListener();
      
//       await bus.addApplicationListener(listener: listener1);
//       await bus.addApplicationListener(listener: listener2);
//       await bus.removeAllListeners();
      
//       await bus.onEvent(event);
//       expect(listener1.receivedEvents, isEmpty);
//       expect(listener2.receivedEvents, isEmpty);
//     });

//     test('should only notify supporting listeners', () async {
//       final supportingListener = TestEventListener();
//       final nonSupportingListener = _NonSupportingEventListener();
      
//       await bus.addApplicationListener(listener: supportingListener);
//       await bus.addApplicationListener(listener: nonSupportingListener);
      
//       await bus.onEvent(event);
//       expect(supportingListener.receivedEvents, contains(event));
//       expect(nonSupportingListener.receivedEvents, isEmpty);
//     });

//     test('should handle null pod factory when adding by pod name', () {
//       final busWithoutFactory = SimpleApplicationEventBus(null);
      
//       expect(() => busWithoutFactory.addApplicationListener(podName: 'test'), returnsNormally);
//     });

//     test('should handle pod factory errors gracefully', () async {
//       final failingPodFactory = MockPodFactory();
//       final busWithFailingFactory = SimpleApplicationEventBus(failingPodFactory);
      
//       expect(() => busWithFailingFactory.addApplicationListener(podName: 'nonexistent'), returnsNormally);
//     });
//   });
// }

// class _NonSupportingEventListener implements ApplicationEventListener<ApplicationEvent> {
//   List<ApplicationEvent> receivedEvents = [];

//   @override
//   void onApplicationEvent(ApplicationEvent event) {
//     receivedEvents.add(event);
//   }

//   @override
//   bool supportsEventOf(ApplicationEvent event) => false;
// }