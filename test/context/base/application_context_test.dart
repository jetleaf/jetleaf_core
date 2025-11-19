import 'package:jetleaf_core/context.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

class MockApplicationContext extends ApplicationContext {
  bool active = false;
  bool closed = false;

  @override
  String getId() => 'test-context';

  @override
  String getApplicationName() => 'test-app';

  @override
  DateTime getStartTime() => DateTime.now();

  @override
  bool isActive() => active;

  @override
  bool isClosed() => closed;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('ApplicationContext', () {
    test('should provide context information', () {
      final context = MockApplicationContext();
      
      expect(context.getId(), equals('test-context'));
      expect(context.getApplicationName(), equals('test-app'));
      expect(context.getStartTime(), isA<DateTime>());
    });

    test('should track state', () {
      final context = MockApplicationContext();
      
      context.active = true;
      expect(context.isActive(), isTrue);
      
      context.closed = true;
      expect(context.isClosed(), isTrue);
    });
  });
}