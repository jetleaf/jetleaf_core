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

// test/pod_spec_test.dart
import 'package:jetleaf_core/src/context/core/pod_spec.dart';
import 'package:jetleaf_core/src/context/base/pod_registrar.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

class MockSpecContext implements SpecContext {
  @override
  Future<T> pod<T>(Class<T> requiredType, {String? name, List<ArgumentValue>? arguments}) {
    throw UnimplementedError();
  }

  @override
  Future<Object> get(Class<Object> requiredType, {List<ArgumentValue>? arguments}) {
    throw UnimplementedError();
  }
}

class TestPod {}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });
  
  group('PodSpec', () {
    late PodSpec<TestPod> podSpec;
    late MockSpecContext context;

    setUp(() {
      context = MockSpecContext();
      podSpec = PodSpec<TestPod>(context);
    });

    test('describedAs should set description', () {
      final result = podSpec.describedAs('Test description');
      expect(result, equals(podSpec));
    });

    test('withScope should set scope descriptor', () {
      final result = podSpec.withScope(ScopeType.SINGLETON);
      expect(result, equals(podSpec));
    });

    test('withDesignRole should set design descriptor', () {
      final result = podSpec.withDesignRole(DesignRole.INFRASTRUCTURE, isPrimary: true);
      expect(result, equals(podSpec));
    });

    test('withDesign should set design descriptor', () {
      final design = DesignDescriptor(
        role: DesignRole.APPLICATION,
        isPrimary: false,
      );
      final result = podSpec.withDesign(design);
      expect(result, equals(podSpec));
    });

    test('designedWithLifecycle should set lifecycle design', () {
      final result = podSpec.designedWithLifecycle(
        lazy: true,
        initMethods: ['init'],
        destroyMethods: ['destroy'],
        enforceInitMethod: true,
        enforceDestroyMethod: true,
      );
      expect(result, equals(podSpec));
    });

    test('withLifecycle should set lifecycle design', () {
      final lifecycle = LifecycleDesign(
        isLazy: true,
        initMethods: ['init'],
        destroyMethods: ['destroy'],
        enforceInitMethod: true,
        enforceDestroyMethod: true,
      );
      final result = podSpec.withLifecycle(lifecycle);
      expect(result, equals(podSpec));
    });

    test('dependingOn should set dependencies', () {
      final dependencies = [DependencyDesign(name: "dependency")];
      final result = podSpec.dependingOn(dependencies);
      expect(result, equals(podSpec));
    });

    test('asAutowireCandidate should set autowire candidate', () {
      final result = podSpec.asAutowireCandidate(AutowireMode.BY_TYPE);
      expect(result, equals(podSpec));
    });

    test('withAutowire should set autowire candidate descriptor', () {
      final descriptor = AutowireCandidateDescriptor(
        autowireCandidate: true,
        autowireMode: AutowireMode.BY_NAME,
      );
      final result = podSpec.withAutowire(descriptor);
      expect(result, equals(podSpec));
    });
    
    test('addPropertyValue should add property value', () {
      final propertyValue = PropertyValue('test', 'value', packageName: "test");
      final result = podSpec.addPropertyValue(propertyValue);
      expect(result, equals(podSpec));
    });

    test('addConstructorArguments should add argument value', () {
      final argument = ArgumentValue('test', packageName: 'value', name: 'value');
      final result = podSpec.addConstructorArguments(argument);
      expect(result, equals(podSpec));
    });

    test('asPodProvider should set isPodProvider flag', () {
      final result = podSpec.asPodProvider();
      expect(result, equals(podSpec));
    });

    test('suppliedBy should set instance', () {
      final result = podSpec.suppliedBy((context) => TestPod());
      expect(result, equals(podSpec));
    });

    test('target should set type', () {
      final result = podSpec.target(Class<TestPod>());
      expect(result, equals(podSpec));
    });

    test('namedAs should set name', () {
      final result = podSpec.namedAs('testName');
      expect(result, equals(podSpec));
    });

    test('clone should throw when type is null', () {
      expect(() => podSpec.clone(), throwsA(isA<IllegalArgumentException>()));
    });

    test('clone should succeed when type and name are set', () {
      podSpec.target(Class<TestPod>());
      podSpec.namedAs('testName');
      
      // This should not throw
      expect(() => podSpec.clone(), returnsNormally);
    });
  });
}