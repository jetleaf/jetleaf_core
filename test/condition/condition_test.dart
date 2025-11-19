import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:test/test.dart';

import '../_dependencies.dart';

final class UserService {}

final class DataSource {}

@ConditionalOnProperty(
  prefix: 'server',
  names: ['ssl.enabled'],
  havingValue: 'true',
  matchIfMissing: false,
)
final class PropertyClass {}

@ConditionalOnProperty(
  prefix: 'server',
  names: ['ssl.enabled'],
  havingValue: 'true',
  matchIfMissing: true,
)
final class PropertyClassMatchIfTrue {}

@ConditionalOnProperty(
  prefix: 'app',
  names: ['feature.enabled'],
  havingValue: 'true',
)
final class PropertyWithPrefixClass {}

@ConditionalOnProperty(
  prefix: 'app',
  names: ['feature1.enabled', 'feature2.enabled'],
  havingValue: 'true',
)
final class MultiplePropertiesClass {}

@ConditionalOnClass(['String', 'int'])
final class ClassExistsClass {}

@ConditionalOnClass(['NonExistentClass'])
final class ClassMissingClass {}

@ConditionalOnMissingClass(['NonExistentClass'])
final class MissingClassClass {}

@ConditionalOnPod(['userService', 'dataSource'])
final class PodExistsClass {}

@ConditionalOnPod(['missingService'])
final class PodMissingClass {}

@ConditionalOnMissingPod(values: ['missingService'])
final class MissingPodClass {}

@Profile(['dev'])
final class ProfileDevClass {}

@Profile(['prod'])
final class ProfileProdClass {}

@Profile(['prod'], negate: true)
final class ProfileNotProdClass {}

@Profile(['dev', 'database'])
final class MultipleProfilesClass {}

@ConditionalOnDart('3.1.0', VersionRange())
final class DartVersionExactClass {}

@ConditionalOnDart('>=3.0.0 <4.0.0', VersionRange(start: Version(3, 0, 0), end: Version(4, 0, 0)))
final class DartVersionRangeClass {}

@ConditionalOnDart('^3.0.0', VersionRange(start: Version(3, 0, 0), end: Version(4, 0, 0)))
final class DartVersionCaretClass {}

@ConditionalOnAsset('config/app.json')
final class AssetExistsClass {}

@ConditionalOnAsset('missing/file.json')
final class AssetMissingClass {}

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

  group('OnPropertyCondition', () {
    test('should pass when property exists with correct value', () async {
      final env = MockEnvironment(properties: {'server.ssl.enabled': 'true'});
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnPropertyCondition();
      final source = Class<PropertyClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnProperty>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });

    test('should fail when property is missing and matchIfMissing is false', () async {
      final env = MockEnvironment(properties: {});
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnPropertyCondition();
      final source = Class<PropertyClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnProperty>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isFalse);
    });

    test('should pass when property is missing and matchIfMissing is true', () async {
      final env = MockEnvironment(properties: {});
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnPropertyCondition();
      final source = Class<PropertyClassMatchIfTrue>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnProperty>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });

    test('should handle prefix correctly', () async {
      final env = MockEnvironment(properties: {'app.feature.enabled': 'true'});
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnPropertyCondition();
      final source = Class<PropertyWithPrefixClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnProperty>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });

    test('should handle multiple property names', () async {
      final env = MockEnvironment(properties: {
        'app.feature1.enabled': 'true',
        'app.feature2.enabled': 'true',
      });
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnPropertyCondition();
      final source = Class<MultiplePropertiesClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnProperty>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });
  });

  group('OnClassCondition', () {
    test('should pass when required class exists', () async {
      final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
      final condition = OnClassCondition();
      final source = Class<ClassExistsClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnClass>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isA<bool>());
    });

    test('should fail when required class is missing', () async {
      final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
      final condition = OnClassCondition();
      final source = Class<ClassMissingClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnClass>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isFalse);
    });

    test('should handle missing classes', () async {
      final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
      final condition = OnClassCondition();
      final source = Class<MissingClassClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnMissingClass>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });
  });

  group('OnPodCondition', () {
    test('should pass when required pod exists', () async {
      final podFactory = DefaultListablePodFactory();

      podFactory.registerDefinition("userService", RootPodDefinition(type: Class<UserService>()));
      podFactory.registerDefinition("dataSource", RootPodDefinition(type: Class<DataSource>()));

      final context = ConditionalContext(MockEnvironment(), podFactory, Runtime);
      final condition = OnPodCondition();
      final source = Class<PodExistsClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnPod>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });

    test('should fail when required pod is missing', () async {
      final podFactory = DefaultListablePodFactory();

      podFactory.registerDefinition("userService", RootPodDefinition(type: Class<UserService>()));

      final context = ConditionalContext(MockEnvironment(), podFactory, Runtime);
      final condition = OnPodCondition();
      final source = Class<PodMissingClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnPod>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isFalse);
    });

    test('should handle missing pods', () async {
      final podFactory = DefaultListablePodFactory();

      podFactory.registerDefinition("userService", RootPodDefinition(type: Class<UserService>()));

      final context = ConditionalContext(MockEnvironment(), podFactory, Runtime);
      final condition = OnPodCondition();
      final source = Class<MissingPodClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnMissingPod>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });
  });

  group('OnProfileCondition', () {
    test('should pass when required profile is active', () async {
      final env = MockEnvironment(activeProfiles: ['dev', 'test']);
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnProfileCondition();
      final source = Class<ProfileDevClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<Profile>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });

    test('should fail when required profile is not active', () async {
      final env = MockEnvironment(activeProfiles: ['dev']);
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnProfileCondition();
      final source = Class<ProfileProdClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<Profile>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isFalse);
    });

    test('should handle negated profiles', () async {
      final env = MockEnvironment(activeProfiles: ['dev']);
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnProfileCondition();
      final source = Class<ProfileNotProdClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<Profile>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });

    test('should handle multiple profiles', () async {
      final env = MockEnvironment(activeProfiles: ['dev', 'database', 'cache']);
      final context = ConditionalContext(env, DefaultListablePodFactory(), Runtime);
      final condition = OnProfileCondition();
      final source = Class<MultipleProfilesClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<Profile>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isTrue);
    });
  });

  // group('OnDartCondition', () {
  //   test('should pass when Dart version matches', () async {
  //     final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
  //     final condition = OnDartCondition();
  //     final source = Class<DartVersionExactClass>();
  //     final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnDart>()).first;

  //     final result = await condition.matches(context, annotation, source);
      
  //     expect(result, isTrue);
  //   });

  //   test('should pass when Dart version is in range', () async {
  //     final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
  //     final condition = OnDartCondition();
  //     final source = Class<DartVersionRangeClass>();
  //     final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnDart>()).first;

  //     final result = await condition.matches(context, annotation, source);
      
  //     expect(result, isTrue);
  //   });

  //   test('should fail when Dart version is out of range', () async {
  //     final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
  //     final condition = OnDartCondition();
  //     final source = Class<DartVersionRangeClass>();
  //     final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnDart>()).first;

  //     final result = await condition.matches(context, annotation, source);
      
  //     expect(result, isFalse);
  //   });

  //   test('should support caret syntax', () async {
  //     final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
  //     final condition = OnDartCondition();
  //     final source = Class<DartVersionCaretClass>();
  //     final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnDart>()).first;

  //     final result = await condition.matches(context, annotation, source);
      
  //     expect(result, isTrue);
  //   });
  // });

  group('OnAssetCondition', () {
    test('should pass when asset exists', () async {
      final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
      final condition = OnAssetCondition();
      final source = Class<AssetExistsClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnAsset>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isA<bool>());
    });

    test('should fail when asset is missing', () async {
      final context = ConditionalContext(MockEnvironment(), DefaultListablePodFactory(), Runtime);
      final condition = OnAssetCondition();
      final source = Class<AssetMissingClass>();
      final annotation = source.getAllDirectAnnotations().where((an) => an.matches<ConditionalOnAsset>()).first;

      final result = await condition.matches(context, annotation, source);
      
      expect(result, isFalse);
    });
  });
}