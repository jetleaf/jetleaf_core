import 'dart:async';
import 'package:jetleaf_core/context.dart';
import 'package:test/test.dart';

void main() {
  group('KeepAlive', () {
    
    test('should block and release thread', () async {
      final keepAlive = KeepAlive();
      bool completed = false;

      // Start keepAlive in a microtask
      final future = Future.microtask(() async {
        await keepAlive.start();
        completed = true;
      });

      // Let microtasks run
      await Future.delayed(Duration.zero);
      expect(completed, isFalse); // should still be blocked

      // Stop keepAlive
      await keepAlive.stop();

      // Await the start future to complete
      await future;
      expect(completed, isTrue);
    });

    test('should handle multiple start/stop cycles', () async {
      final keepAlive = KeepAlive();

      // Cycle 1
      var future1 = Future.microtask(() => keepAlive.start());
      await Future.delayed(Duration.zero); // allow microtask to schedule
      await keepAlive.stop();
      await future1; // ensure first start completes

      // Cycle 2
      bool completed = false;
      var future2 = Future.microtask(() async {
        await keepAlive.start();
        completed = true;
      });

      await Future.delayed(Duration.zero);
      expect(completed, isFalse); // still blocked

      await keepAlive.stop();
      await future2;
      expect(completed, isTrue);
    });

    test('should respond to events', () async {
      final keepAlive = KeepAlive();

      // Fire setup event
      final setupFuture = Future(() => keepAlive.onApplicationEvent(ContextSetupEvent(MockApplicationContext())));
      await Future.delayed(Duration.zero);
      expect(keepAlive.isRunning(), isTrue);

      // Fire closed event
      await keepAlive.onApplicationEvent(ContextClosedEvent(MockApplicationContext()));
      await setupFuture;

      expect(keepAlive.isRunning(), isFalse); // should be stopped
    });

    test('isRunning returns correct state', () async {
      final keepAlive = KeepAlive();

      expect(keepAlive.isRunning(), isFalse);

      // start
      final future = Future(() => keepAlive.start());
      await Future.delayed(Duration.zero);
      expect(keepAlive.isRunning(), isTrue);

      await keepAlive.stop();
      await future;
      expect(keepAlive.isRunning(), isFalse);
    });
  });
}

// Mock ApplicationContext for testing events
class MockApplicationContext extends ApplicationContext {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}