import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '_dependencies.dart';

@Order(1)
class Order1 {}

@Order(2)
class Order2 {}

class OrderedImpl implements Ordered {
  @override
  int getOrder() => 3;
}

class PriorityOrderedImpl implements PriorityOrdered {
  @override
  int getOrder() => 0;
}

class NoOrder {}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });
  
  group('AnnotationAwareOrderComparator', () {
    test('should sort based on @Order annotation', () {
      final list = [Class<Order2>(), Class<Order1>()];
      AnnotationAwareOrderComparator.sort(list);
      expect(list[0].getDirectAnnotation<Order>()?.value, equals(1));
      expect(list[1].getDirectAnnotation<Order>()?.value, equals(2));
    });

    test('should sort based on Ordered interface', () {
      final list = [Class<OrderedImpl>(), Class<PriorityOrderedImpl>()];
      // Note: Class<T> wrapping might not expose the interface directly unless instantiated
      // The comparator checks if the class assigns from Ordered and instantiates it.
      AnnotationAwareOrderComparator.sort(list);
      expect(list[0], isA<Class<PriorityOrderedImpl>>());
      expect(list[1], isA<Class<OrderedImpl>>());
      
      // Let's test with instances for direct object comparison
      final o1 = OrderedImpl();
      final o2 = PriorityOrderedImpl();
      final listObj = [o1, o2];
      
      AnnotationAwareOrderComparator.sort(listObj);
      expect(listObj[0], isA<PriorityOrderedImpl>());
      expect(listObj[1], isA<OrderedImpl>());
    });

    test('should handle mixed types', () {
      final o1 = OrderedImpl(); // order 3
      final o2 = PriorityOrderedImpl(); // order 0
      final o3 = 5; // order 5
      
      final list = [o3, o1, o2];
      AnnotationAwareOrderComparator.sort(list);
      
      expect(list[0], equals(o2));
      expect(list[1], equals(o1));
      expect(list[2], equals(o3));
    });

    test('should reverse sort', () {
      final list = [1, 3, 2];
      AnnotationAwareOrderComparator.reverseSort(list);
      expect(list, equals([3, 2, 1]));
    });
  });
}