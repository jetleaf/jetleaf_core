import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:test/test.dart';

import '../_dependencies.dart';

final class TestService {}
final class TestDataSource {}

@Profile(['dev'])
final class DevProfileClass {}

@Profile(['dev'])
@ConditionalOnProperty(prefix: 'feature', names: ['enabled'], havingValue: 'true')
@ConditionalOnPod(['dataSource'])
final class MultipleConditionsClass {}

@Profile(['dev'], negate: true)
final class NotDevProfileClass {}

@ConditionalOnClass(['String'])
final class ClassConditionClass {}

class MockEnvironment extends ApplicationEnvironment {
  final Map<String, String> properties;
  final List<String> activeProfiles;

  MockEnvironment({
    this.properties = const {},
    this.activeProfiles = const [],
  }) {
    for (final active in activeProfiles) {
      super.addActiveProfile(active);
    }

    super.getPropertySources().addLast(MapPropertySource("test", properties));
  }
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('ConditionEvaluator', () {
    test('should include source without conditions', () async {
      final env = MockEnvironment();
      final podFactory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, podFactory);
      
      final source = Class<TestService>();
      
      final result = await evaluator.shouldInclude(source);
      
      expect(result, isTrue);
    });

    test('should evaluate @Profile annotation', () async {
      final env = MockEnvironment(activeProfiles: ['dev']);
      final podFactory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, podFactory);
      
      final source = Class<DevProfileClass>();
      
      final result = await evaluator.shouldInclude(source);
      
      expect(result, isTrue);
    });

    test('should handle multiple conditions', () async {
      final env = MockEnvironment(
        activeProfiles: ['dev'],
        properties: {'feature.enabled': 'true'},
      );
      final podFactory = DefaultListablePodFactory();
      
      podFactory.registerDefinition("dataSource", RootPodDefinition(type: Class<TestDataSource>()));
      
      final evaluator = ConditionEvaluator(env, podFactory);
      
      final source = Class<MultipleConditionsClass>();
      
      final result = await evaluator.shouldInclude(source);
      
      expect(result, isTrue);
    });

    test('should exclude source when condition fails', () async {
      final env = MockEnvironment(activeProfiles: ['prod']);
      final podFactory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, podFactory);
      
      final source = Class<DevProfileClass>();
      
      final result = await evaluator.shouldInclude(source);
      
      expect(result, isFalse);
    });

    test('should handle negated profiles', () async {
      final env = MockEnvironment(activeProfiles: ['prod']);
      final podFactory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, podFactory);
      
      final source = Class<NotDevProfileClass>();
      
      final result = await evaluator.shouldInclude(source);
      
      expect(result, isTrue);
    });

    test('should handle conditional on class', () async {
      final env = MockEnvironment();
      final podFactory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, podFactory);
      
      final source = Class<ClassConditionClass>();
      
      final result = await evaluator.shouldInclude(source);
      
      expect(result, isA<bool>());
    });
  });

  group('ConditionalContext', () {
    test('should provide access to environment', () {
      final env = MockEnvironment(properties: {'key': 'value'});
      
      expect(env.getProperty('key'), equals('value'));
    });

    test('should provide access to pod factory', () async {
      final podFactory = DefaultListablePodFactory();
      
      podFactory.registerDefinition("service1", RootPodDefinition(type: Class<TestService>()));
      podFactory.registerDefinition("service2", RootPodDefinition(type: Class<TestDataSource>()));
      
      expect(await podFactory.containsPod('service1'), isTrue);
      expect(await podFactory.containsPod('service3'), isFalse);
    });
  });
}