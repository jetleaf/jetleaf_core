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

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

/// {@template jetleaf_pod_registrar}
/// A contract in **JetLeaf** for components that can register pods
/// into the application’s dependency container.
///
/// A `PodRegistrar` is responsible for describing how specific pods
/// should be registered with the [`PodRegistry`].  
/// Implementations are automatically instantiated by the JetLeaf pod factory at startup,
/// so **any class implementing this interface must provide a no-argument constructor**.
/// Failure to do so will prevent automatic registration of pods.
///
/// ### Lifecycle & Workflow
/// When the JetLeaf application context starts:
///
/// 1. **Registrar Discovery**
///    - The pod factory scans for all classes implementing `PodRegistrar`.
///    - It instantiates each registrar using the no-arg constructor.
///
/// 2. **Registration Phase**
///    - The `register` method of each registrar is called with:
///      - `PodRegistry`: the central registry for managing pods.
///      - `Environment`: access to runtime properties, profiles, and configuration.
///
/// 3. **Pod Declaration**
///    - Within `register`, implementers declare the pods that should exist in the container:
///      - Either via `registry.registerPod(...)` for individual pod registration.
///      - Or by delegating to other registrars if needed.
///
/// 4. **Initialization**
///    - Once registration is complete, the pod factory resolves dependencies,
///      initializes pods according to their lifecycle (singleton, prototype, etc.),
///      and applies ordering if the registrars implement `Ordered`.
///
/// ### Implementation Guidelines
/// - Must have a **public no-arg constructor** because the pod factory must not have been initialized creates instances reflectively.
/// - Can optionally implement `Ordered` to control registration order relative to other registrars.
/// - Use the `Environment` parameter to conditionally register pods based on configuration,
///   profiles, or system properties.
/// - Registrars should focus on **declaration**, not **business logic**.
///
/// ### Example
/// ```dart
/// @Component() // If to be discovered by the scanner. Any stereotype annotation can suffice
/// class MyServiceRegistrar implements PodRegistrar {
///   // No-arg constructor is required for reflection-based instantiation
///   MyServiceRegistrar();
///
///   @override
///   void register(PodRegistry registry, Environment env) {
///     // Register a singleton pod
///     registry.registerPod(Class<MyService>(), customizer: (spec) {
///       spec.namedAs('myService').withScope(ScopeType.singleton);
///     });
///
///     // Conditionally register based on environment
///     if (env.getPropertyAs<bool>('featureX.enabled', Class<bool>()) == true) {
///       registry.registerPod(Class<FeatureXService>());
///     }
///   }
/// }
/// ```
///
/// ### Notes
/// - JetLeaf guarantees that all discovered registrars are invoked once during startup.
/// - Registration is performed **before** any pod dependencies are injected.
/// - Improper constructors (e.g., missing no-arg constructor) will cause registrars to be skipped.
/// {@endtemplate}
abstract interface class PodRegistrar {
  /// Registers one or more pods into the JetLeaf pod registry.
  ///
  /// - [registry] is the central pod registry used to manage pod
  ///   definitions and their lifecycle.
  /// - [env] gives access to the runtime environment so pods can
  ///   be conditionally registered.
  void register(PodRegistry registry, Environment env);
}

/// {@template jetleaf_pod_registry}
/// A contract in **JetLeaf** that provides methods for managing pods
/// in the container.
///
/// The `PodRegistry` allows registration of pod definitions either directly
/// or through [`PodRegistrar`].
///
/// ### Workflow
/// 1. **Registrar Registration**
///    - A `PodRegistrar` is registered with the registry using `register`.
///    - Its `register` method declares one or more pods.
///
/// 2. **Direct Pod Registration**
///    - Use `registerPod<T>` to register a pod of type `T`.
///    - Customize its metadata via the optional `customizer`.
///    - Optionally assign a unique `name`.
///
/// 3. **Pod Resolution**
///    - The pod registry maintains a mapping of pod names and types to instances.
///    - Pods are initialized based on scope and lifecycle rules:
///      - Singleton: a single shared instance.
///      - Prototype: a new instance per request.
///      - Lazy: created only when first requested.
///
/// 4. **Dependency Injection**
///    - Once pods are registered, other pods can depend on them.
///    - The registry ensures correct instantiation order respecting `Ordered` registrars.
///
/// ### Example
/// ```dart
/// final registry = DefaultPodRegistry();
///
/// // Register a registrar
/// registry.register(MyServiceRegistrar());
///
/// // Direct pod registration
/// registry.registerPod(Class<MyService>(), customizer: (spec) {
///   spec.namedAs('myService').withScope(ScopeType.singleton);
/// });
///
/// // Retrieve a pod
/// final myService = registry.getPod<MyService>('myService');
/// ```
///
/// ### Notes
/// - Pod registration should be performed at startup before any dependent pods are used.
/// - Registrars and pods can be conditionally registered based on runtime properties.
/// - The registry supports ordering via `Ordered` interfaces to guarantee deterministic initialization.
/// {@endtemplate}
abstract interface class PodRegistry {
  /// Registers a [registrar] that declares pods into this registry.
  Future<void> register(PodRegistrar registrar);

  /// Registers a pod of type [T] in the registry.
  ///
  /// - [podClass] defines the class type for the pod.
  /// - [customizer] allows refining the [Spec] of the pod.
  /// - [name] can be provided to identify the pod uniquely.
  Future<void> registerPod<T>(Class<T> podClass, {Consumer<Spec<T>>? customizer, String? name});
}

/// {@template jetleaf_spec}
/// A **Jetleaf** definition describing how a pod should be instantiated,
/// configured, and managed inside the container.
///
/// A `Spec` acts as a fluent builder for pod registration. It allows chaining
/// configuration methods for scope, lifecycle, dependencies, naming, and
/// autowiring.
///
/// ### When to use
/// Use a `Spec` whenever you register a pod inside a `Registry`. It provides
/// a structured, declarative way to define pod behaviors and their container
/// interactions.
///
/// ### Example
/// ```dart
/// registry.registerPod(MyService.classType, customizer: (spec) {
///   spec
///     .namedAs('myService')
///     .withScope(ScopeType.singleton)
///     .describedAs('Provides business logic services')
///     .suppliedBy((ctx) => MyService(ctx.get(Dependency.classType)));
/// });
/// ```
///
/// ### Fluent Chaining
/// All methods return the same `Spec<T>` instance, allowing chained invocations.
/// {@endtemplate}
@Generic(Spec)
abstract class Spec<T> extends PodDefinition {
  /// {@macro jetleaf_spec}
  Spec({required super.type});

  /// {@template spec_described_as}
  /// Adds a human-readable [description] to this pod spec.  
  /// This can be useful for debugging, logging, or documentation purposes.
  ///
  /// ### Example
  /// ```dart
  /// spec.describedAs('Handles authentication logic');
  /// ```
  /// {@endtemplate}
  Spec<T> describedAs(String description);

  /// {@template spec_with_scope}
  /// Defines the [type] of scope this pod belongs to (e.g., `singleton`,
  /// `prototype`).
  ///
  /// - `singleton`: one shared instance across the container.
  /// - `prototype`: a new instance each time it is requested.
  ///
  /// ### Example
  /// ```dart
  /// spec.withScope(ScopeType.singleton);
  /// ```
  /// {@endtemplate}
  Spec<T> withScope(ScopeType type);

  /// {@template spec_with_design_role}
  /// Assigns a design [role] to this pod, with an option to mark it as
  /// [isPrimary] for autowiring resolution.
  ///
  /// - Use roles to categorize pods (e.g., "controller", "repository").
  /// - If multiple candidates exist, `isPrimary: true` helps resolve ambiguity.
  ///
  /// ### Example
  /// ```dart
  /// spec.withDesignRole(DesignRole.service, isPrimary: true);
  /// ```
  /// {@endtemplate}
  Spec<T> withDesignRole(DesignRole role, {bool isPrimary = false});

  /// {@template spec_with_design}
  /// Associates a [design] descriptor with this pod.  
  /// A design encapsulates structural or semantic metadata about the pod.
  ///
  /// ### Example
  /// ```dart
  /// spec.withDesign(DesignDescriptor('payment-service'));
  /// ```
  /// {@endtemplate}
  Spec<T> withDesign(DesignDescriptor design);

  /// {@template spec_lifecycle_design}
  /// Configures lifecycle design for the pod.
  ///
  /// Parameters:
  /// - [lazy]: Whether initialization should be deferred until first access.
  /// - [initMethods]: List of method names to call during initialization.
  /// - [destroyMethods]: List of method names to call during destruction.
  /// - [enforceInitMethod]: Enforces that init methods exist on the class.
  /// - [enforceDestroyMethod]: Enforces that destroy methods exist on the class.
  ///
  /// ### Example
  /// ```dart
  /// spec.designedWithLifecycle(
  ///   lazy: true,
  ///   initMethods: ['init'],
  ///   destroyMethods: ['dispose'],
  ///   enforceInitMethod: true,
  /// );
  /// ```
  /// {@endtemplate}
  Spec<T> designedWithLifecycle({
    bool lazy = false,
    List<String> initMethods = const [],
    List<String> destroyMethods = const [],
    bool enforceInitMethod = false,
    bool enforceDestroyMethod = false,
  });

  /// {@template spec_with_lifecycle}
  /// Attaches a lifecycle [lifecycle] definition to this pod.
  ///
  /// This allows declarative lifecycle handling with a `LifecycleDesign` object.
  ///
  /// ### Example
  /// ```dart
  /// spec.withLifecycle(LifecycleDesign.lazy(init: ['onStart']));
  /// ```
  /// {@endtemplate}
  Spec<T> withLifecycle(LifecycleDesign lifecycle);

  /// {@template spec_dependencies}
  /// Declares [dependencies] required for this pod.
  ///
  /// Dependencies must be registered within the container to resolve correctly.
  ///
  /// ### Example
  /// ```dart
  /// spec.dependingOn([
  ///   DependencyDesign.of(Logger),
  ///   DependencyDesign.of(Database),
  /// ]);
  /// ```
  /// {@endtemplate}
  Spec<T> dependingOn(List<DependencyDesign> dependencies);

  /// {@template spec_autowire_candidate}
  /// Declares this pod as an autowire candidate with the given [mode].
  ///
  /// The [AutowireMode] determines how automatic dependency injection
  /// should behave when resolving this pod.
  ///
  /// ### Example
  /// ```dart
  /// spec.asAutowireCandidate(AutowireMode.byType);
  /// ```
  /// {@endtemplate}
  Spec<T> asAutowireCandidate(AutowireMode mode);

  /// {@template spec_with_autowire}
  /// Provides a [descriptor] describing autowiring rules for this pod.
  ///
  /// Useful for advanced autowire customization.
  ///
  /// ### Example
  /// ```dart
  /// spec.withAutowire(AutowireCandidateDescriptor.named('specialService'));
  /// ```
  /// {@endtemplate}
  Spec<T> withAutowire(AutowireCandidateDescriptor descriptor);

  /// {@template spec_created_by}
  /// Configures a factory method for creating this pod.
  ///
  /// - [factoryClass]: Class containing the factory method.
  /// - [methodName]: Method name to call for pod creation.
  ///
  /// ### Example
  /// ```dart
  /// spec.createdBy('serviceFactory', 'createService', Class<ServiceFactory>());
  /// ```
  /// {@endtemplate}
  Spec<T> createdBy(String factoryClassPodName, String methodName, Class factoryClass);

  /// {@template spec_with_factory}
  /// Defines this pod using a factory [descriptor].
  ///
  /// This allows more complex factory method definitions.
  /// {@endtemplate}
  Spec<T> withFactory(FactoryMethodDesign descriptor);

  /// {@template spec_add_property_value}
  /// Adds a property [value] to this pod definition.
  ///
  /// Typically used for configuration values injected into the pod.
  ///
  /// ### Example
  /// ```dart
  /// spec.addPropertyValue(PropertyValue('timeout', 5000));
  /// ```
  /// {@endtemplate}
  Spec<T> addPropertyValue(PropertyValue value);

  /// {@template spec_add_constructor_arguments}
  /// Adds a constructor [argument] for pod instantiation.
  ///
  /// Constructor arguments help resolve dependencies during creation.
  ///
  /// ### Example
  /// ```dart
  /// spec.addConstructorArguments(ArgumentValue.of(Database.classType));
  /// ```
  /// {@endtemplate}
  Spec<T> addConstructorArguments(ArgumentValue argument);

  /// {@template spec_as_pod_provider}
  /// Marks this spec as a pod provider (i.e., a factory for other pods).
  ///
  /// Pod providers act as producers of other managed instances.
  /// {@endtemplate}
  Spec<T> asPodProvider();

  /// {@template spec_expressed_with}
  /// Configures the pod using a custom [expression].
  ///
  /// This allows programmatic or computed pod definitions.
  /// {@endtemplate}
  Spec<T> expressedWith(PodExpression<Object> expression);

  /// {@template spec_supplied_by}
  /// Supplies a pod instance using a [supplier] function.
  ///
  /// The [supplier] receives a [SpecContext] for resolving dependencies.
  ///
  /// ### Example
  /// ```dart
  /// spec.suppliedBy((ctx) => MyService(ctx.get(Logger.classType)));
  /// ```
  /// {@endtemplate}
  Spec<T> suppliedBy(T Function(SpecContext context) supplier);

  /// {@template spec_target}
  /// Targets this spec towards a specific [type].
  ///
  /// This ensures type safety and explicit binding to a class type.
  /// {@endtemplate}
  Spec<T> target(Class<T> type);

  /// {@template spec_named_as}
  /// Assigns a logical [name] to this pod spec.
  ///
  /// Named pods can be retrieved explicitly by name.
  ///
  /// ### Example
  /// ```dart
  /// spec.namedAs('paymentService');
  /// ```
  /// {@endtemplate}
  Spec<T> namedAs(String name);
}

/// {@template jetleaf_spec_context}
/// A context object in **Jetleaf** provided to suppliers and pod
/// definitions for resolving dependencies at runtime.
///
/// Use this to fetch required pods or objects from within custom
/// suppliers.
///
/// ### Usage
/// ```dart
/// registry.registerPod(MyService.classType, customizer: (spec) {
///   spec.suppliedBy((ctx) async {
///     final repo = await ctx.pod(Repository.classType);
///     return MyService(repo);
///   });
/// });
/// ```
/// {@endtemplate}
abstract interface class SpecContext {
  /// Resolves a pod of type [T] from the context.
  ///
  /// - [requiredType] specifies the class of the pod.
  /// - [name] optionally narrows the resolution to a named pod.
  /// - [arguments] can be supplied for parameterized instantiation.
  Future<T> pod<T>(Class<T> requiredType, {String? name, List<ArgumentValue> arguments});

  /// Resolves an object of the given [requiredType] from the context.
  ///
  /// - [arguments] are optional arguments for construction.
  Future<Object> get(Class<Object> requiredType, {List<ArgumentValue> arguments});
}