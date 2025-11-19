import 'package:jetleaf_core/context.dart';
import 'package:test/test.dart';

class TestImportSelector implements ImportSelector {
  const TestImportSelector();

  @override
  List<ImportClass> selects() {
    return [
      ImportClass.package('pkg'),
      ImportClass.qualified('pkg.Class'),
    ];
  }
}

void main() {
  group('ImportClass', () {
    test('should create package import', () {
      final imp = ImportClass.package('pkg');
      expect(imp.name, equals('pkg'));
      expect(imp.isQualifiedName, isFalse);
      expect(imp.disable, isFalse);
    });

    test('should create qualified import', () {
      final imp = ImportClass.qualified('pkg.Class');
      expect(imp.name, equals('pkg.Class'));
      expect(imp.isQualifiedName, isTrue);
    });

    test('should support equality', () {
      final imp1 = ImportClass.package('pkg');
      final imp2 = ImportClass.package('pkg');
      final imp3 = ImportClass.qualified('pkg');

      expect(imp1, equals(imp2));
      expect(imp1, isNot(equals(imp3)));
    });
  });

  group('ImportSelector', () {
    test('should select imports', () {
      const selector = TestImportSelector();
      final imports = selector.selects();
      
      expect(imports, hasLength(2));
      expect(imports[0].name, equals('pkg'));
      expect(imports[1].isQualifiedName, isTrue);
    });
  });
}