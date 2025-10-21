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

// test/lifecycle/lifecycle_interfaces_test.dart
import 'dart:async';

import 'package:jetleaf_core/src/context/lifecycle/lifecycle.dart';
import 'package:jetleaf_core/src/context/lifecycle/lifecycle_processor.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

class TestLifecycle implements Lifecycle {
  bool _running = false;
  Runnable? _lastCallback;
  
  @override
  FutureOr<void> start() {
    if (!_running) {
      _running = true;
    }
  }
  
  @override
  FutureOr<void> stop([Runnable? callback]) {
    if (_running) {
      _running = false;
    }
    _lastCallback = callback;
    callback?.run();
  }
  
  @override
  bool isRunning() => _running;
  
  Runnable? get lastCallback => _lastCallback;
}

class TestSmartLifecycle extends SmartLifecycle {
  bool _running = false;
  final bool autoStartup;
  final int phase;
  
  TestSmartLifecycle({this.autoStartup = true, this.phase = SmartLifecycle.DEFAULT_PHASE});
  
  @override
  FutureOr<void> start() {
    if (!_running) {
      _running = true;
    }
  }
  
  @override
  FutureOr<void> stop([Runnable? callback]) {
    if (_running) {
      _running = false;
    }
    callback?.run();
  }
  
  @override
  bool isRunning() => _running;
  
  @override
  bool isAutoStartup() => autoStartup;
  
  @override
  int getPhase() => phase;
}

class TestPhased implements Phased {
  final int phase;
  
  TestPhased(this.phase);
  
  @override
  int getPhase() => phase;
}

void main() {
  group('Lifecycle', () {
    test('should start and stop', () async {
      final lifecycle = TestLifecycle();
      
      expect(lifecycle.isRunning(), isFalse);
      
      await lifecycle.start();
      expect(lifecycle.isRunning(), isTrue);
      
      await lifecycle.stop();
      expect(lifecycle.isRunning(), isFalse);
    });
    
    test('should handle stop callback', () async {
      final lifecycle = TestLifecycle();
      var callbackCalled = false;
      
      await lifecycle.start();
      await lifecycle.stop(SimpleRunnable(() => callbackCalled = true));
      
      expect(callbackCalled, isTrue);
      expect(lifecycle.lastCallback, isNotNull);
    });
    
    test('should handle null callback', () async {
      final lifecycle = TestLifecycle();
      
      await lifecycle.start();
      await lifecycle.stop(null);
      
      expect(lifecycle.lastCallback, isNull);
    });
  });
  
  group('SmartLifecycle', () {
    test('should have default phase', () {
      final lifecycle = TestSmartLifecycle();
      
      expect(lifecycle.getPhase(), SmartLifecycle.DEFAULT_PHASE);
      expect(lifecycle.isAutoStartup(), isTrue);
    });
    
    test('should support custom phase and autoStartup', () {
      const customPhase = 100;
      final lifecycle = TestSmartLifecycle(autoStartup: false, phase: customPhase);
      
      expect(lifecycle.getPhase(), customPhase);
      expect(lifecycle.isAutoStartup(), isFalse);
    });
    
    test('should implement both Lifecycle and Phased', () {
      final lifecycle = TestSmartLifecycle();
      
      expect(lifecycle, isA<Lifecycle>());
      expect(lifecycle, isA<Phased>());
    });
  });
  
  group('Phased', () {
    test('should return phase value', () {
      const phase = -500;
      final phased = TestPhased(phase);
      
      expect(phased.getPhase(), phase);
    });
  });
  
  group('LifecycleProcessor', () {
    test('should have onRefresh and onClose methods', () {
      final processor = _TestLifecycleProcessor();
      
      expect(processor.onRefresh, isA<Function>());
      expect(processor.onClose, isA<Function>());
    });
  });
}

class _TestLifecycleProcessor implements LifecycleProcessor {
  @override
  Future<void> onClose() async {}
  
  @override
  void onRefresh() {}
}

class SimpleRunnable implements Runnable {
  final Function() action;
  
  SimpleRunnable(this.action);
  
  @override
  void run() => action();
}