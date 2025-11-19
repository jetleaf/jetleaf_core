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
import 'package:jetleaf_pod/pod.dart';

import '../base/pod_registrar.dart';

/// {@template jetleaf_pod_spec}
/// A concrete implementation of the [`Spec`] API in **Jetleaf**.
/// 
/// `PodSpec` provides the internal mechanism for building, configuring,
/// and cloning pod definitions that are registered into the container.
/// 
/// While developers usually interact with the higher-level [`Spec`] API
/// when customizing pods, Jetleaf internally uses `PodSpec` to hold
/// the actual configuration state.
/// 
/// ### Key Details
/// - Backed by a [`RootPodDefinition`] that stores all pod metadata.
/// - All configuration methods from [`Spec`] delegate into this root definition.
/// - Ensures that pods are fully validated before cloning into the registry.
/// 
/// ### Example
/// Developers typically don’t instantiate `PodSpec` directly, but interact with it
/// through the `registerPod` API:
/// 
/// ```dart
/// registry.registerPod(MyService.classType, customizer: (spec) {
///   spec
///     .namedAs('myService')
///     .withScope(ScopeType.singleton)
///     .describedAs('Provides the MyService business logic')
///     .suppliedBy((ctx) => MyService());
/// });
/// ```
/// {@endtemplate}
@Generic(PodSpec)
final class PodSpec<T> extends Spec<T> {
  /// The root pod definition that stores all pod metadata.
  final RootPodDefinition _root;

  /// The context used for resolving dependencies in suppliers.
  final SpecContext _context;

  /// {@macro jetleaf_pod_spec}
  PodSpec(this._context) : _root = RootPodDefinition(type: NullablePod.CLASS), super(type: NullablePod.CLASS);

  @override
  Spec<T> describedAs(String description) {
    _root.description = description;
    return this;
  }

  @override
  Spec<T> withScope(ScopeType type) {
    _root.scope = ScopeDesign(
      type: type.name,
      isSingleton: type == ScopeType.SINGLETON,
      isPrototype: type == ScopeType.PROTOTYPE,
    );

    return this;
  }

  @override
  Spec<T> withDesignRole(DesignRole role, {bool isPrimary = false}) {
    _root.design = DesignDescriptor(
      role: role,
      isPrimary: isPrimary,
    );

    return this;
  }

  @override
  Spec<T> withDesign(DesignDescriptor design) {
    _root.design = design;
    return this;
  }

  @override
  Spec<T> designedWithLifecycle({
    bool lazy = false,
    List<String> initMethods = const [],
    List<String> destroyMethods = const [],
    bool enforceInitMethod = false,
    bool enforceDestroyMethod = false,
  }) {
    _root.lifecycle = LifecycleDesign(
      isLazy: lazy,
      initMethods: initMethods,
      destroyMethods: destroyMethods,
      enforceInitMethod: enforceInitMethod,
      enforceDestroyMethod: enforceDestroyMethod,
    );
    return this;
  }

  @override
  Spec<T> withLifecycle(LifecycleDesign lifecycle) {
    _root.lifecycle = lifecycle;
    return this;
  }

  @override
  Spec<T> dependingOn(List<DependencyDesign> dependencies) {
    _root.dependsOn = dependencies;
    return this;
  }

  @override
  Spec<T> asAutowireCandidate(AutowireMode mode) {
    _root.autowireCandidate = AutowireCandidateDescriptor(
      autowireCandidate: mode != AutowireMode.NO,
      autowireMode: mode,
    );

    return this;
  }

  @override
  Spec<T> withAutowire(AutowireCandidateDescriptor descriptor) {
    _root.autowireCandidate = descriptor;
    return this;
  }

  @override
  Spec<T> createdBy(String factoryClassPodName, String methodName, Class factoryClass) {
    _root.factoryMethod = FactoryMethodDesign(factoryClassPodName, methodName, factoryClass);
    return this;
  }

  @override
  Spec<T> withFactory(FactoryMethodDesign descriptor) {
    _root.factoryMethod = descriptor;
    return this;
  }

  @override
  Spec<T> addPropertyValue(PropertyValue value) {
    _root.propertyValues.addPropertyValue(value);
    return this;
  }

  @override
  Spec<T> addConstructorArguments(ArgumentValue argument) {
    _root.executableArgumentValues.addArgument(argument);
    return this;
  }

  @override
  Spec<T> asPodProvider() {
    _root.isPodProvider = true;
    return this;
  }

  @override
  Spec<T> expressedWith(PodExpression<Object> expression) {
    _root.setPodExpression(expression);
    return this;
  }

  @override
  Spec<T> suppliedBy(T Function(SpecContext context) supplier) {
    _root.instance = supplier(_context);
    return this;
  }

  @override
  Spec<T> target(Class<T> type) {
    _root.type = type;
    return this;
  }

  @override
  Spec<T> namedAs(String name) {
    _root.name = name;
    return this;
  }
  
  @override
  PodDefinition clone() {
    if(_root.type == NullablePod.CLASS) {
      throw IllegalArgumentException('Pod type cannot be null');
    }

    return RootPodDefinition.from(_root);
  }
}

/// {@template jetleaf_pod_spec_context}
/// An implementation of [`SpecContext`] in **Jetleaf** that resolves
/// dependencies during pod creation and supplier evaluation.
/// 
/// `PodSpecContext` bridges the pod factory with pod specifications,
/// enabling suppliers and expressions to fetch other pods or objects.
/// 
/// ### Key Details
/// - Wraps a [`ListablePodFactory`] for resolving pods.
/// - Provides asynchronous resolution of both pods and objects.
/// - Used internally when evaluating [`Spec.suppliedBy`] or dependency injection.
/// 
/// ### Example
/// ```dart
/// registry.registerPod(MyService.classType, customizer: (spec) {
///   spec.suppliedBy((ctx) async {
///     final repo = await ctx.pod(Repository.classType);
///     return MyService(repo);
///   });
/// });
/// ```
/// {@endtemplate}
final class PodSpecContext implements SpecContext {
  /// The pod factory used for resolving pods and objects.
  final ListablePodFactory _podFactory;

  /// {@macro jetleaf_pod_spec_context}
  PodSpecContext(this._podFactory);
  
  @override
  Future<T> pod<T>(Class<T> requiredType, {String? name, List<ArgumentValue>? arguments}) {
    if(name != null) {
      return _podFactory.getPod<T>(name, arguments);
    }

    return _podFactory.get<T>(requiredType, arguments);
  }

  @override
  Future<Object> get(Class<Object> requiredType, {List<ArgumentValue>? arguments}) {
    return _podFactory.getObject(requiredType, arguments);
  }
}