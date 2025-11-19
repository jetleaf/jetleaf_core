import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:test/test.dart';

import '../_dependencies.dart';

@Scope("singleton")
final class MyService {}

@Scope("prototype")
final class PrototypeService {}

@Scope("request")
final class RequestScopedService {}

void main() {
  setUpAll(() async {
    await setupRuntime();

    return Future<void>.value();
  });

  group('ScopeMetadataResolver', () {
    late ScopeMetadataResolver resolver;

    setUp(() {
      resolver = AnnotatedScopeMetadataResolver();
    });

    test('should return singleton for classes without @Scope annotation', () {
      final classType = Class<MyService>();
      
      final scope = resolver.resolve(classType);
      
      expect(scope, equals('singleton'));
    });

    test('should return custom scope from @Scope annotation', () {
      final classType = Class<PrototypeService>();
      final scope = resolver.resolve(classType);
      
      expect(scope, equals('prototype'));
    });

    test('should handle request scope', () {
      final classType = Class<RequestScopedService>();
      final scope = resolver.resolve(classType);
      
      expect(scope, equals('request'));
    });
  });

  group('ScopeDesign', () {
    test('should create singleton scope design', () {
      final design = ScopeDesign.type('singleton');
      
      expect(design.type, equals('singleton'));
      expect(design.isSingleton, isTrue);
      expect(design.isPrototype, isFalse);
    });

    test('should create prototype scope design', () {
      final design = ScopeDesign.type('prototype');
      
      expect(design.type, equals('prototype'));
      expect(design.isSingleton, isFalse);
      expect(design.isPrototype, isTrue);
    });

    test('should implement equality correctly', () {
      final design1 = ScopeDesign.type('singleton');
      final design2 = ScopeDesign.type('singleton');
      final design3 = ScopeDesign.type('prototype');
      
      expect(design1, equals(design2));
      expect(design1, isNot(equals(design3)));
      expect(design1.hashCode, equals(design2.hashCode));
    });

    test('should handle custom scope types', () {
      final design = ScopeDesign.type('custom');
      
      expect(design.type, equals('custom'));
      expect(design.isSingleton, isFalse);
      expect(design.isPrototype, isFalse);
    });
  });
}