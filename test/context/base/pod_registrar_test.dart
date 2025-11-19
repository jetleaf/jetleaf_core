import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

final class TestPod {}

class TestPodRegistrar implements PodRegistrar {
  bool registered = false;

  @override
  void register(PodRegistry registry, Environment env) {
    registered = true;
    registry.registerPod(Class<TestPod>(), name: 'testPod');
  }
}

class AnotherPod {}

class AnotherPodRegistrar implements PodRegistrar {
  bool registered = false;

  @override
  void register(PodRegistry registry, Environment env) {
    registered = true;
    registry.registerPod(Class<AnotherPod>(), name: 'anotherPod');
  }
}

class MockPodRegistry implements PodRegistry {
  final Map<String, Class> pods = {};

  @override
  Future<void> register(PodRegistrar registrar) async {
    // no-op
  }

  @override
  Future<void> registerPod<T>(Class<T> podClass, {Consumer<Spec<T>>? customizer, String? name}) async {
    if (name != null) {
      pods[name] = podClass;
    }
  }
}

class MockEnvironment extends Environment {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('PodRegistrar', () {
    test('should register pods', () {
      final registrar = TestPodRegistrar();
      final registry = MockPodRegistry();
      final env = MockEnvironment();

      registrar.register(registry, env);

      expect(registrar.registered, isTrue);
      expect(registry.pods, contains('testPod'));
      expect(registry.pods['testPod'], isA<Class<TestPod>>());
    });

    test('should register pods with ApplicationContext', () {
      final applicationContext = AnnotationConfigApplicationContext();
      final registrar = TestPodRegistrar();

      applicationContext.register(registrar);

      expect(registrar.registered, isTrue);
      expect(applicationContext.containsDefinition("testPod"), isTrue);
    });
  });
}