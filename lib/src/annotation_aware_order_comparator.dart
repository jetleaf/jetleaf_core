// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_lang/lang.dart';

import 'annotations/others.dart';

/// {@template annotation_aware_order_comparator}
/// A Jetleaf-provided [OrderComparator] implementation that determines ordering
/// based on the presence of the `@Order` annotation or the [Ordered] interface.
///
/// This comparator extends the standard [OrderComparator] to provide annotation-aware
/// ordering capabilities, making it the primary ordering mechanism throughout the
/// Jetleaf framework for components that use declarative ordering via annotations.
///
/// ### Order Resolution Strategy:
/// 1. **`@Order` Annotation**: Highest precedence, directly specifies order value
/// 2. **`PriorityOrdered` Interface**: Second highest precedence for programmatic control
/// 3. **`Ordered` Interface**: Standard programmatic ordering
/// 4. **Default Fallback**: [Ordered.LOWEST_PRECEDENCE] when no order specified
///
/// ### Supported Types:
/// - **Classes**: Inspects `@Order` annotation and [Ordered] interface implementation
/// - **Sources**: Checks for `@Order` annotation on source elements
/// - **Executables**: Methods and constructors with parameter count as tiebreaker
/// - **Direct Objects**: Objects implementing [Ordered] or [PriorityOrdered]
/// - **Raw Integers**: Direct order values for programmatic use
///
/// ### Framework Integration:
/// - Used in pod factory post-processor execution ordering
/// - Applied to application context initializer sorting
/// - Utilized for event listener ordering
/// - Employed in configuration class processing sequence
///
/// ### Example:
/// ```dart
/// @Order(1)
/// class HighPriorityService {
///   // This service will be processed first due to @Order(1)
/// }
///
/// @Order(5)
/// class MediumPriorityService {
///   // Processed after HighPriorityService but before LowPriorityService
/// }
///
/// class LowPriorityService implements Ordered {
///   @override
///   int get order => 10; // Processed last
/// }
///
/// class DefaultPriorityService {
///   // No order specified - uses LOWEST_PRECEDENCE (Integer.MAX_VALUE)
/// }
///
/// void main() {
///   final comparator = AnnotationAwareOrderComparator();
///
///   // Check order values
///   final order1 = comparator.findOrder(Class<HighPriorityService>());
///   print(order1); // 1
///
///   final order2 = comparator.findOrder(Class<LowPriorityService>());
///   print(order2); // 10
///
///   final order3 = comparator.findOrder(Class<DefaultPriorityService>());
///   print(order3); // 2147483647 (Ordered.LOWEST_PRECEDENCE)
///
///   // Sort a list of classes by their order precedence
///   final classes = [
///     Class<LowPriorityService>(),
///     Class<HighPriorityService>(),
///     Class<DefaultPriorityService>(),
///     Class<MediumPriorityService>()
///   ];
///   
///   AnnotationAwareOrderComparator.sort(classes);
///
///   // Classes are now sorted: High, Medium, Low, Default
///   for (final cls in classes) {
///     print('${cls.getSimpleName()}: ${comparator.findOrder(cls)}');
///   }
/// }
/// ```
///
/// ### Advanced Usage with Mixed Types:
/// ```dart
/// // Mix of different order specification methods
/// final components = [
///   Class<AnnotatedComponent>(),      // Uses @Order(2)
///   ManualOrderComponent(),           // Implements Ordered returning 1
///   Class<DefaultComponent>(),        // No order specified
///   PriorityComponent(),              // Implements PriorityOrdered returning 0
///   5                                 // Raw integer order value
/// ];
///
/// AnnotationAwareOrderComparator.sort(components);
/// // Order: PriorityComponent (0), ManualOrderComponent (1), 
/// //        AnnotatedComponent (2), 5 (5), DefaultComponent (MAX_VALUE)
/// ```
///
/// See also:
/// - [OrderComparator] for the base ordering implementation
/// - [Ordered] for the standard ordering interface
/// - [PriorityOrdered] for highest precedence ordering
/// - [Order] for the ordering annotation
/// {@endtemplate}
class AnnotationAwareOrderComparator extends OrderComparator {
  /// {@macro annotation_aware_order_comparator}
  AnnotationAwareOrderComparator();

  /// {@template annotation_aware_order_comparator.when_compared}
  /// Compares two objects using annotation-aware ordering rules.
  ///
  /// This method extends the base comparison logic to first attempt
  /// order resolution through the [findOrder] method, which handles
  /// annotation-based ordering. If both objects have explicit order
  /// values, they are compared directly. Otherwise, falls back to
  /// the standard [OrderComparator] logic.
  ///
  /// ### Comparison Strategy:
  /// 1. Resolve order values for both objects using [findOrder]
  /// 2. If both have explicit orders, compare numerically
  /// 3. Otherwise, delegate to parent [OrderComparator] for standard rules
  /// 4. Maintains [PriorityOrdered] precedence over regular [Ordered]
  ///
  /// ### Parameters:
  /// - [o1]: The first object to compare
  /// - [o2]: The second object to compare
  ///
  /// ### Returns:
  /// - Negative integer if [o1] should come before [o2]
  /// - Positive integer if [o2] should come before [o1]
  /// - Zero if objects have equal ordering precedence
  ///
  /// ### Example:
  /// ```dart
  /// final comparator = AnnotationAwareOrderComparator();
  /// 
  /// @Order(1)
  /// class ServiceA {}
  /// 
  /// class ServiceB implements Ordered {
  ///   @override int get order => 2;
  /// }
  /// 
  /// final result = comparator.whenCompared(Class<ServiceA>(), Class<ServiceB>());
  /// print(result); // -1 (ServiceA comes before ServiceB)
  /// ```
  /// {@endtemplate}
  @override
  int whenCompared(Object? o1, Object? o2) {
    final order1 = findOrder(o1);
    final order2 = findOrder(o2);

    if (order1 != null && order2 != null) {
      return order1.compareTo(order2);
    }

    return OrderComparator().whenCompared(o1, o2);
  }

  /// {@template annotation_aware_order_comparator.find_order}
  /// Finds the order value for the given object using annotation-aware resolution.
  ///
  /// This method implements the comprehensive order resolution strategy that
  /// makes this comparator unique. It examines various sources of order
  /// information in a specific precedence sequence.
  ///
  /// ### Resolution Precedence:
  /// 1. **Direct Objects**:
  ///    - [PriorityOrdered] implementations (highest precedence)
  ///    - [Ordered] implementations
  ///    - Raw integer values
  ///
  /// 2. **Class Objects**:
  ///    - `@Order` annotation on the class
  ///    - [Ordered] interface implementation
  ///    - Fallback to [Ordered.LOWEST_PRECEDENCE]
  ///
  /// 3. **Source Objects**:
  ///    - `@Order` annotation on the source element
  ///
  /// 4. **Executable Objects** (Methods/Constructors):
  ///    - `@Order` annotation
  ///    - Parameter count as natural ordering (fewer parameters first)
  ///
  /// 5. **Fallback Strategy**:
  ///    - For unknown types, attempt to get class and recurse
  ///    - Final fallback to [Ordered.LOWEST_PRECEDENCE]
  ///
  /// ### Parameters:
  /// - [obj]: The object to find order for (Class, Source, Executable, or direct object)
  ///
  /// ### Returns:
  /// The resolved order value, or `null` if no specific order could be determined
  ///
  /// ### Example:
  /// ```dart
  /// final comparator = AnnotationAwareOrderComparator();
  /// 
  /// // Check annotated class
  /// @Order(42)
  /// class MyService {}
  /// final order1 = comparator.findOrder(Class<MyService>());
  /// print(order1); // 42
  /// 
  /// // Check Ordered implementation
  /// class OrderedService implements Ordered {
  ///   @override int get order => 100;
  /// }
  /// final order2 = comparator.findOrder(Class<OrderedService>());
  /// print(order2); // 100
  /// 
  /// // Check method with @Order annotation
  /// class Component {
  ///   @Order(10)
  ///   void highPriorityMethod() {}
  /// }
  /// final method = Class<Component>().getDeclaredMethod('highPriorityMethod');
  /// final order3 = comparator.findOrder(method);
  /// print(order3); // 10
  /// 
  /// // Check method without annotation (uses parameter count)
  /// class AnotherComponent {
  ///   void methodWithParams(String a, int b) {} // 2 parameters
  /// }
  /// final method2 = Class<AnotherComponent>().getDeclaredMethod('methodWithParams');
  /// final order4 = comparator.findOrder(method2);
  /// print(order4); // 2
  /// ```
  /// {@endtemplate}
  int? findOrder(Object? obj) {
    if (obj == null) return Ordered.LOWEST_PRECEDENCE;

    if (obj is Class) {
      final cls = obj;

      // First priority: @Order annotation on class
      if (cls.hasDirectAnnotation<Order>()) {
        final ann = cls.getDirectAnnotation<Order>();
        if (ann != null) return ann.value;
      }

      // Second priority: Ordered interface implementation
      final ordered = Class<Ordered>();
      if (ordered.isAssignableFrom(cls)) {
        final instance = cls.getNoArgConstructor()?.newInstance();
        if (instance != null && instance is PriorityOrdered) {
          return instance.getOrder();
        } else if (instance != null && instance is Ordered) {
          return instance.getOrder();
        }
      }
    } else if (obj is Source) {
      // @Order annotation on source elements
      if (obj.hasDirectAnnotation<Order>()) {
        final ann = obj.getDirectAnnotation<Order>();
        if (ann != null) return ann.value;
      }
    } else if (obj is Executable) {
      // @Order annotation on executables
      if (obj.hasDirectAnnotation<Order>()) {
        final ann = obj.getDirectAnnotation<Order>();
        if (ann != null) return ann.value;
      }

      // Natural ordering for methods based on parameter count
      if (obj is Method) {
        final method = obj;
        return method.getParameters().length;
      }

      // Natural ordering for constructors based on parameter count
      if (obj is Constructor) {
        final constructor = obj;
        return constructor.getParameters().length;
      }
    } else if (obj is PriorityOrdered) {
      // Direct PriorityOrdered implementation (highest precedence)
      return obj.getOrder();
    } else if (obj is Ordered) {
      // Direct Ordered implementation
      return obj.getOrder();
    } else if (obj is int) {
      // Raw integer order value
      return obj;
    } else {
      // Fallback: try to get class and recurse
      return findOrder(obj.getClass());
    }

    return null;
  }

  @override
  int? getPriority(Object obj) => findOrder(obj);

  /// {@template annotation_aware_order_comparator.sort}
  /// Utility method to sort a list of objects according to Jetleaf's
  /// annotation and order-based rules.
  ///
  /// This static method provides a convenient way to sort lists without
  /// explicitly creating a comparator instance. It's particularly useful
  /// for one-off sorting operations.
  ///
  /// ### Parameters:
  /// - [list]: The list to sort in-place using annotation-aware ordering
  ///
  /// ### Usage:
  /// ```dart
  /// // Sort configuration classes by their @Order annotations
  /// final configClasses = [
  ///   Class<DatabaseConfig>(),    // @Order(2)
  ///   Class<SecurityConfig>(),    // @Order(1)
  ///   Class<WebConfig>(),         // @Order(3)
  ///   Class<CacheConfig>()        // No @Order - defaults to LOWEST_PRECEDENCE
  /// ];
  /// 
  /// AnnotationAwareOrderComparator.sort(configClasses);
  /// 
  /// // Order: SecurityConfig (1), DatabaseConfig (2), 
  /// //        WebConfig (3), CacheConfig (MAX_VALUE)
  /// for (final cls in configClasses) {
  ///   print(cls.getSimpleName());
  /// }
  /// ```
  ///
  /// ### Framework Usage:
  /// This method is used internally by Jetleaf to sort:
  /// - Pod factory post-processors
  /// - Application context initializers  
  /// - Event listeners
  /// - Configuration classes
  /// - Any framework extension points that support ordering
  /// {@endtemplate}
  static void sort(List<Object> list) => list.sort(AnnotationAwareOrderComparator().whenCompared);

  /// {@template annotation_aware_order_comparator.reverse_sort}
  /// Sorts a list in reverse order according to annotation-aware rules.
  ///
  /// This method sorts the list using the standard annotation-aware ordering
  /// and then reverses it, resulting in descending order (highest order values first).
  ///
  /// ### Parameters:
  /// - [list]: The list to sort in reverse order
  ///
  /// ### Use Cases:
  /// - Processing components in reverse order for cleanup/shutdown
  /// - Implementing LIFO (Last-In-First-Out) processing patterns
  /// - Dependency resolution where dependents should process before dependencies
  ///
  /// ### Example:
  /// ```dart
  /// final processors = [
  ///   Class<FirstProcessor>(),   // @Order(1)
  ///   Class<LastProcessor>(),    // @Order(100)
  ///   Class<MiddleProcessor>()   // @Order(50)
  /// ];
  /// 
  /// AnnotationAwareOrderComparator.reverseSort(processors);
  /// 
  /// // Order: LastProcessor (100), MiddleProcessor (50), FirstProcessor (1)
  /// for (final processor in processors) {
  ///   print(processor.getSimpleName());
  /// }
  /// ```
  /// {@endtemplate}
  static void reverseSort(List<Object> list) {
    list.sort(AnnotationAwareOrderComparator().whenCompared);
    list = list.reversed.toList();
  }
}