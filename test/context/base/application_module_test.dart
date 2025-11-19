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