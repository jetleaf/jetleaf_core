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
import 'package:meta/meta.dart';

import '../../condition/condition_evaluator.dart';
import '../../intercept/default_method_interceptor.dart';
import '../base/application_conversion_service.dart';
import '../base/application_environment.dart';
import '../base/application_module.dart';
import '../base/application_type.dart';
import '../processors/autowired_annotation_pod_processor.dart';
import '../processors/common_annotation_pod_processor.dart';
import '../processors/configuration_property_pod_processor.dart';
import '../processors/event_listener_method_processor.dart';
import '../scanning/annotated_pod_definition_reader.dart';
import '../scanning/class_path_pod_definition_scanner.dart';
import '../scanning/configuration_class_post_processor.dart';
import 'abstract_application_context.dart';
import 'generic_application_context.dart';

/// {@template annotation_config_application_context}
/// ApplicationContext implementation that supports annotation-based configuration.
///
/// This context extends [GenericApplicationContext] to add comprehensive support for
/// annotation-driven dependency injection and component configuration in the Jetleaf framework.
///
/// ### Key Features:
/// - **@Component Scanning**: Automatically discovers and registers annotated classes
/// - **@Configuration Support**: Processes configuration classes with @Pod methods
/// - **@Profile Activation**: Conditionally registers components based on active profiles
/// - **@Autowired Injection**: Automatically wires dependencies between services
/// - **Package Scanning**: Scans specified packages for annotated components
/// - **Annotation Processors**: Built-in processors for common annotations
/// - **Environment Integration**: Profile-based conditional pod registration
///
/// ### Architecture:
/// The context combines programmatic registration with automatic classpath scanning
/// to provide a flexible configuration system. It uses specialized processors to
/// handle different annotation types and integrates with the Jetleaf environment
/// system for profile-based activation.
///
/// ### Usage Example:
/// ```dart
/// final context = AnnotationConfigApplicationContext();
/// 
/// // Register configuration classes
/// context.register(AppConfig);
/// context.register(DatabaseConfig);
/// 
/// // Scan packages for components
/// context.scan(['package:example/services', 'package:example/repositories']);
/// 
/// // Set active profiles
/// context.getEnvironment().setActiveProfiles(['production', 'database']);
/// 
/// // Initialize the context
/// await context.refresh();
/// 
/// // Retrieve components
/// final userService = await context.get<UserService>();
/// ```
///
/// ### Annotation Support:
/// - `@Component`, `@Service`, `@Repository` - Component stereotypes
/// - `@Configuration` - Configuration classes with `@Pod` methods
/// - `@Autowired` - Dependency injection points
/// - `@Qualifier` - Dependency disambiguation
/// - `@Profile` - Conditional registration
/// - `@EventListener` - Event handling methods
///
/// See also:
/// - [GenericApplicationContext] for the base application context functionality
/// - [AnnotationConfigRegistry] for the annotation configuration interface
/// - [AnnotatedPodDefinitionReader] for annotation processing
/// {@endtemplate}
class AnnotationConfigApplicationContext extends GenericApplicationContext implements AnnotationConfigRegistry {
  /// {@template annotation_config_application_context.configuration_annotation_processor_pod_name}
  /// Pod name for the internal configuration annotation processor.
  ///
  /// This processor handles `@Configuration` classes and processes `@Pod` methods
  /// to register pod definitions for the methods' return types.
  ///
  /// Used internally by the framework to process configuration classes.
  /// {@endtemplate}
  static final String CONFIGURATION_ANNOTATION_PROCESSOR_POD_NAME = "jetleaf.annotation.internalConfigurationAnnotationProcessor";

  /// {@template annotation_config_application_context.autowired_annotation_processor_pod_name}
  /// Pod name for the internal autowired annotation processor.
  ///
  /// This processor handles `@Autowired` annotations on fields, constructors,
  /// and methods, performing dependency injection at the appropriate lifecycle phase.
  ///
  /// Used internally by the framework to enable automatic dependency wiring.
  /// {@endtemplate}
  static final String AUTOWIRED_ANNOTATION_PROCESSOR_POD_NAME = "jetleaf.annotation.internalAutowiredAnnotationProcessor";

  /// {@template annotation_config_application_context.common_annotation_processor_pod_name}
  /// Pod name for the internal common annotation processor.
  ///
  /// This processor handles common Java-like annotations such as `@PostConstruct`,
  /// `@PreDestroy`, and other lifecycle-related annotations.
  ///
  /// Used internally by the framework to support standard lifecycle callbacks.
  /// {@endtemplate}
  static final String COMMON_ANNOTATION_PROCESSOR_POD_NAME = "jetleaf.annotation.internalCommonAnnotationProcessor";

  /// {@template annotation_config_application_context.configuration_property_annotation_processor_pod_name}
  /// Pod name for the internal configuration property annotation processor.
  ///
  /// This processor is responsible for handling `@ConfigurationProperty`
  /// (or similar) annotations on fields, methods, or classes. It performs
  /// automatic binding of configuration values (from environment variables,
  /// `.env` files, or the application configuration system) into annotated
  /// components during the context initialization phase.
  ///
  /// Used internally by the framework to support declarative configuration
  /// binding in Jetleaf applications.
  /// {@endtemplate}
  static final String CONFIGURATION_PROPERTY_ANNOTATION_PROCESSOR_POD_NAME = "jetleaf.annotation.internalConfigurationPropertyAnnotationProcessor";

  /// {@template annotation_config_application_context.event_listener_method_processor_pod_name}
  /// Pod name for the internal event listener method processor.
  ///
  /// This processor handles `@EventListener` annotations on methods, registering
  /// them as event listeners within the application context's event system.
  ///
  /// Used internally by the framework to support event-driven architecture.
  /// {@endtemplate}
  static final String EVENT_LISTENER_METHOD_PROCESSOR_POD_NAME = "jetleaf.annotation.internalEventListenerMethodProcessor";

  /// {@template annotation_config_application_context.environment_pod_name}
  /// Pod name for the internal environment instance.
  ///
  /// This pod provides access to the application environment, including profiles,
  /// properties, and other environment-specific configuration.
  ///
  /// Used internally by the framework and available for injection into application components.
  /// {@endtemplate}
  static final String ENVIRONMENT_POD_NAME = "jetleaf.environment.internalEnvironment";

  /// {@template annotation_config_application_context.application_context_pod_name}
  /// Pod name for the registered application context.
  ///
  /// This application context handles the entirety of the application and makes it easy for access.
  ///
  /// Used internally by the framework to support modular application architecture.
  /// {@endtemplate}
  static final String APPLICATION_CONTEXT_POD_NAME = "jetleaf.application.context";

  /// The internal pod name used to register JetLeaf's AOP (Aspect-Oriented Programming)
  /// interception support infrastructure.
  ///
  /// This constant uniquely identifies the interception subsystem within the
  /// JetLeaf runtime. It is primarily used for dependency registration,
  /// service discovery, and lifecycle management of interception-related
  /// components such as:
  ///
  /// - [MethodInterceptorDispatcher]
  /// - [ConditionalMethodInterceptor]
  /// - [Interceptable] mixins and proxies
  ///
  /// ## Usage
  /// This identifier is used internally when binding or resolving
  /// the interception support pod from the JetLeaf application context.
  ///
  /// Example:
  /// ```dart
  /// final pod = context.getPod(InterceptSupportPods.INTERCEPT_SUPPORT_POD_NAME);
  /// ```
  ///
  /// @internal
  static final String INTERCEPT_SUPPORT_POD_NAME = "jetleaf.intercept.aop.support";

  /// {@template annotation_config_application_context.reader}
  /// Reader instance for processing annotated class definitions.
  ///
  /// This reader scans classes for annotations and converts them into
  /// [PodDefinition] instances that can be registered with the pod factory.
  ///
  /// Handles annotations like `@Component`, `@Service`, `@Repository`, etc.
  /// {@endtemplate}
  late AnnotatedPodDefinitionReader _reader;

  /// {@template annotation_config_application_context.uuid}
  /// Unique identifier for this application context instance.
  ///
  /// Used to generate unique context IDs and for display purposes.
  /// Lazily initialized when first accessed.
  /// {@endtemplate}
  Uuid? _uuid;

  /// {@macro annotation_config_application_context}
  ///
  /// Creates a new [AnnotationConfigApplicationContext] with default settings.
  ///
  /// The context is initialized with an [AnnotatedPodDefinitionReader] for
  /// processing annotated classes but is not refreshed until [setup] is called.
  ///
  /// Example:
  /// ```dart
  /// final context = AnnotationConfigApplicationContext();
  /// await context.refresh();
  /// ```
  AnnotationConfigApplicationContext() : this.all(null, null);

  /// {@template annotation_config_application_context.with_parent}
  /// Creates a new [AnnotationConfigApplicationContext] with a parent context and optional pod factory.
  ///
  /// This constructor allows creating a hierarchical context structure where
  /// this context can delegate to a parent context for dependency resolution.
  ///
  /// [parent] the parent application context for hierarchical resolution
  /// [podFactory] optional custom pod factory instance
  ///
  /// Example:
  /// ```dart
  /// final parentContext = GenericApplicationContext();
  /// final childContext = AnnotationConfigApplicationContext.all(parentContext, null);
  /// ```
  /// {@endtemplate}
  AnnotationConfigApplicationContext.all(super.parent, super.podFactory) : super.all() {
    _reader = AnnotatedPodDefinitionReader();
    _uuid = Uuid.randomUuid();
  }

  @override
  String getId() {
    _uuid ??= Uuid.randomUuid();
    
    return "$runtimeType-$_uuid";
  }

  @override
  String getDisplayName() => "AnnotationConfigApplicationContext";

  @override
  AbstractEnvironment getSupportingEnvironment() => ApplicationEnvironment();

  @override
  bool supports(ApplicationType applicationType) => applicationType == ApplicationType.NONE;

  @override
  Future<void> registerClass({List<Class<Object>>? classes, Class<Object>? mainClass}) async {
    if(classes != null) {
      await _reader.register(classes);
    }

    if(mainClass != null) {
      await _reader.doRegister(mainClass);
    }

    return Future.value();
  }

  @override
  Future<void> scan(List<String> basePackages) async {
    final podFactory = getPodFactory();
    final scanner = ClassPathPodDefinitionScanner(
      ConditionEvaluator(getEnvironment(), podFactory, Runtime),
      podFactory,
      getMainApplicationClass()
    );
    
    final definitions = <PodDefinition>[];
    for (final basePackage in basePackages) {
      definitions.addAll(await scanner.doScan(basePackage));
    }

    for (final definition in definitions) {
      await registerDefinition(definition.name, definition);
    }

    return Future.value();
  }

  @override
  Future<void> preparePodFactory(ConfigurableListablePodFactory podFactory) async {
    await super.preparePodFactory(podFactory);

    _reader = AnnotatedPodDefinitionReader();
    _reader.setEnvironment(getEnvironment());
    _reader.setPodFactory(podFactory);

    setAllowDefinitionOverriding(false);
    setAllowCircularReferences(true);
    setAllowRawInjection(true);

    return await _reader.doRegister(getMainApplicationClass());
  }

  @override
  Future<void> postProcessPodFactory(ConfigurableListablePodFactory podFactory) async {
    if (!containsSingleton(ENVIRONMENT_POD_NAME)) {
      final env = getEnvironment();
      final envClass = env.getClass();

      await podFactory.registerSingleton(
        ENVIRONMENT_POD_NAME,
        envClass,
        object: ObjectHolder(env, packageName: env.getPackageName(), qualifiedName: envClass.getQualifiedName())
      );
    }

    await registerAnnotationConfigProcessors(podFactory, null);

    return super.postProcessPodFactory(podFactory);
  }

  @override
  Future<void> finishSetup(ConfigurableListablePodFactory podFactory) async {
    if (!containsSingleton(APPLICATION_CONTEXT_POD_NAME)) {
      final contextClass = getClass();

      await podFactory.registerSingleton(
        APPLICATION_CONTEXT_POD_NAME,
        contextClass,
        object: ObjectHolder(this, packageName: getPackageName(), qualifiedName: contextClass.getQualifiedName())
      );
    }

    return super.finishSetup(podFactory);
  }
  
  // ---------------------------------------------------------------------------------------------------------
  // PROTECTED METHODS
  // ---------------------------------------------------------------------------------------------------------

  /// {@template annotation_config_application_context.register_annotation_config_processors}
  /// Registers the internal annotation configuration processors.
  ///
  /// This method ensures that all necessary annotation processors are registered
  /// with the pod factory. These processors handle various annotations during
  /// the pod factory's post-processing phase.
  ///
  /// Processors registered:
  /// - [ConfigurationClassPostProcessor] - Handles `@Configuration` classes
  /// - [CommonAnnotationPodProcessor] - Handles common annotations
  /// - [AutowiredAnnotationPodProcessor] - Handles `@Autowired` injection
  /// - [EventListenerMethodProcessor] - Handles `@EventListener` methods
  /// - [DefaultInterceptorRegistry] - Handles method intercept modules
  ///
  /// All processors are registered with [DesignRole.INFRASTRUCTURE] to indicate
  /// they are framework infrastructure components.
  ///
  /// [source] optional source object for the processor definitions
  ///
  /// Example:
  /// ```dart
  /// await context.registerAnnotationConfigProcessors();
  /// ```
  ///
  /// See also:
  /// - [CONFIGURATION_ANNOTATION_PROCESSOR_POD_NAME]
  /// - [AUTOWIRED_ANNOTATION_PROCESSOR_POD_NAME]
  /// - [COMMON_ANNOTATION_PROCESSOR_POD_NAME]
  /// - [EVENT_LISTENER_METHOD_PROCESSOR_POD_NAME]
  /// - [INTERCEPT_SUPPORT_POD_NAME]
  /// {@endtemplate}
  @protected
  Future<void> registerAnnotationConfigProcessors(ConfigurableListablePodFactory podFactory, [Object? source]) async {
    if (!podFactory.containsDefinition(CONFIGURATION_ANNOTATION_PROCESSOR_POD_NAME)) {
      RootPodDefinition def = RootPodDefinition(type: Class<ConfigurationClassPostProcessor>(null, PackageNames.CORE));
      def.instance = source;
      def.design.role = DesignRole.INFRASTRUCTURE;
      await podFactory.registerDefinition(CONFIGURATION_ANNOTATION_PROCESSOR_POD_NAME, def);
    }

    if (!podFactory.containsDefinition(COMMON_ANNOTATION_PROCESSOR_POD_NAME)) {
      RootPodDefinition def = RootPodDefinition(type: Class<CommonAnnotationPodProcessor>(null, PackageNames.CORE));
      def.instance = source;
      def.design.role = DesignRole.INFRASTRUCTURE;
      await podFactory.registerDefinition(COMMON_ANNOTATION_PROCESSOR_POD_NAME, def);
    }

    if (!podFactory.containsDefinition(AUTOWIRED_ANNOTATION_PROCESSOR_POD_NAME)) {
      RootPodDefinition def = RootPodDefinition(type: Class<AutowiredAnnotationPodProcessor>(null, PackageNames.CORE));
      def.instance = source;
      def.design.role = DesignRole.INFRASTRUCTURE;
      await podFactory.registerDefinition(AUTOWIRED_ANNOTATION_PROCESSOR_POD_NAME, def);
    }

    if (!podFactory.containsDefinition(CONFIGURATION_PROPERTY_ANNOTATION_PROCESSOR_POD_NAME)) {
      RootPodDefinition def = RootPodDefinition(type: Class<ConfigurationPropertyPodProcessor>(null, PackageNames.CORE));
      def.instance = source;
      def.design.role = DesignRole.INFRASTRUCTURE;
      await podFactory.registerDefinition(CONFIGURATION_PROPERTY_ANNOTATION_PROCESSOR_POD_NAME, def);
    }

    if (!podFactory.containsDefinition(EVENT_LISTENER_METHOD_PROCESSOR_POD_NAME)) {
      RootPodDefinition def = RootPodDefinition(type: Class<EventListenerMethodProcessor>(null, PackageNames.CORE));
      def.instance = source;
      def.design.role = DesignRole.INFRASTRUCTURE;
      await podFactory.registerDefinition(EVENT_LISTENER_METHOD_PROCESSOR_POD_NAME, def);
    }

    if (!podFactory.containsDefinition(INTERCEPT_SUPPORT_POD_NAME)) {
      RootPodDefinition def = RootPodDefinition(type: Class<DefaultMethodInterceptor>(null, PackageNames.CORE));
      def.instance = source;
      def.design.role = DesignRole.INFRASTRUCTURE;
      await podFactory.registerDefinition(INTERCEPT_SUPPORT_POD_NAME, def);
    }

    if (!podFactory.containsDefinition(AbstractApplicationContext.JETLEAF_CONVERSION_SERVICE_POD_NAME)) {
      RootPodDefinition def = RootPodDefinition(type: Class<ApplicationConversionService>(null, PackageNames.CORE));
      def.instance = source;
      def.design.role = DesignRole.INFRASTRUCTURE;
      await podFactory.registerDefinition(AbstractApplicationContext.JETLEAF_CONVERSION_SERVICE_POD_NAME, def);
    }

    return Future.value();
  }
  
  @override
  int getPhase() => 0;
}