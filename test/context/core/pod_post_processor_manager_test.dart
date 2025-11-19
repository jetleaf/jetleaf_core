// Mock implementations
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/src/context/core/pod_post_processor_manager.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

class MockPodFactoryPostProcessor implements PodFactoryPostProcessor {
  bool called = false;
  
  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory factory) async {
    called = true;
  }
}

class MockPriorityPostProcessor implements PodFactoryPostProcessor, PriorityOrdered {
  final int priority;
  bool called = false;
  
  MockPriorityPostProcessor(this.priority);
  
  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory factory) async {
    called = true;
  }
  
  @override
  int getOrder() => priority;
}

class MockPodProcessor implements PodProcessor {
  bool called = false;
  
  Future<void> process(dynamic pod) async {
    called = true;
  }
}

void main() {
  late DefaultListablePodFactory factory;

  setUpAll(() async {
    await setupRuntime();

    factory = DefaultListablePodFactory();
    return Future<void>.value();
  });

  group('PodPostProcessorManager', () {
    test('should invoke post processors in order', () async {
      final processor1 = MockPodFactoryPostProcessor();
      final processor2 = MockPodFactoryPostProcessor();
      
      final manager = PodPostProcessorManager(factory);
      await manager.invokePodFactoryPostProcessor([processor2, processor1]);
      
      expect(processor1.called, isTrue);
      expect(processor2.called, isTrue);
    });

    test('should prioritize PriorityOrdered processors', () async {
      final highPriority = MockPriorityPostProcessor(1);
      final lowPriority = MockPriorityPostProcessor(10);
      
      final manager = PodPostProcessorManager(factory);
      await manager.invokePodFactoryPostProcessor([lowPriority, highPriority]);
      
      expect(highPriority.called, isTrue);
      expect(lowPriority.called, isTrue);
    });

    test('should handle regular processors after ordered ones', () async {
      final priorityProcessor = MockPriorityPostProcessor(1);
      final regularProcessor = MockPodFactoryPostProcessor();
      
      final manager = PodPostProcessorManager(factory);
      await manager.invokePodFactoryPostProcessor([priorityProcessor, regularProcessor]);
      
      expect(priorityProcessor.called, isTrue);
      expect(regularProcessor.called, isTrue);
    });
  });

  group('Processor Ordering', () {
    test('should sort by priority correctly', () {
      final processors = [
        MockPriorityPostProcessor(10),
        MockPriorityPostProcessor(1),
        MockPriorityPostProcessor(5),
      ];
      
      processors.sort((a, b) => a.getOrder().compareTo(b.getOrder()));
      
      expect(processors[0].getOrder(), equals(1));
      expect(processors[1].getOrder(), equals(5));
      expect(processors[2].getOrder(), equals(10));
    });

    test('should handle equal priorities', () {
      final processor1 = MockPriorityPostProcessor(5);
      final processor2 = MockPriorityPostProcessor(5);
      
      expect(processor1.getOrder(), equals(processor2.getOrder()));
    });
  });
}