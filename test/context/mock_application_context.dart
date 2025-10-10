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
// import 'package:jetleaf_core/src/context/application_type.dart';
// import 'package:jetleaf_core/src/context/event/application_event.dart';
// import 'package:jetleaf_env/src/core/environment.dart';
// import 'package:jetleaf_lang/lang.dart';

// class TestApplicationContextEvent extends ApplicationContextEvent {
//   TestApplicationContextEvent(super.source);
// }

// class MockApplicationContext implements ApplicationContext {
//   @override
//   String toString() => 'MockApplicationContext';

//   @override
//   String getApplicationName() => 'MockApplicationContext';

//   @override
//   Environment getEnvironment() => throw UnimplementedError();

//   @override
//   String getId() => 'MockApplicationContext';

//   @override
//   Class<Object> getMainApplicationClass() => throw UnimplementedError();

//   @override
//   String getMessage(String code, {List<Object>? args, Locale? locale, String? defaultMessage}) => throw UnimplementedError();

//   @override
//   ApplicationContext? getParent() => throw UnimplementedError();

//   @override
//   DateTime getStartTime() => throw UnimplementedError();

//   @override
//   bool isActive() => throw UnimplementedError();

//   @override
//   bool isClosed() => throw UnimplementedError();

//   @override
//   void publishEvent(ApplicationEvent event) => throw UnimplementedError();

//   @override
//   bool supports(ApplicationType applicationType) => throw UnimplementedError();
// }