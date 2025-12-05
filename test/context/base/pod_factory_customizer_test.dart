import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

class TestPodFactoryCustomizer implements PodFactoryCustomizer<ApplicationContext> {
  bool customized = false;

  @override
  Future<void> customize(ApplicationContext podFactory, Environment environment) async {
    customized = true;
  }
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('PodFactoryCustomizer', () {
    test('should customize factory', () async {
      final customizer = TestPodFactoryCustomizer();
      final context = AnnotationConfigApplicationContext();

      await customizer.customize(context, context.getEnvironment());

      expect(customizer.customized, isTrue);
    });
  });
}