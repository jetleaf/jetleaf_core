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

import 'dart:async';

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:meta/meta.dart';

import '../../annotations/lifecycle.dart';
import '../../message/delegating_message_source.dart';
import '../../message/message_source.dart';
import '../helpers.dart';
import '../lifecycle/_lifecycle_processor.dart';
import '../application_context.dart';
import '../event/application_event.dart';
import '../event/event_listener.dart';
import '../event/simple_application_event_bus.dart';
import '../lifecycle/lifecycle_processor.dart';

/// {@template abstract_application_context}
/// The base implementation of a configurable **Jetleaf Application Context**.
///
/// `AbstractApplicationContext` provides the foundational lifecycle management,
/// environment handling, event bus initialization, and pod factory orchestration
/// that all Jetleaf application contexts build upon.
///
/// ### Key Features:
/// - **Lifecycle Management**: Standardized `refresh()`, `start()`, `stop()`, and `close()` lifecycle
/// - **Event System**: Integrated event publishing for context lifecycle events
/// - **Environment Integration**: Property source management and profile handling
/// - **Pod Factory Orchestration**: Complete pod lifecycle from registration to destruction
/// - **Internationalization**: Built-in message source support
/// - **Resource Management**: Proper cleanup and resource disposal
///
/// ### Core Lifecycle Events:
/// - `ContextRefreshedEvent`: Published when context is successfully refreshed
/// - `ContextStartedEvent`: Published when context transitions to running state
/// - `ContextStoppedEvent`: Published when context is stopped
/// - `ContextClosedEvent`: Published when context is fully closed
///
/// ### Default Initialization:
/// - **MessageSource**: For internationalization and message resolution
/// - **ApplicationEventBus**: For event publishing and listening
/// - **LifecycleProcessor**: For managing pod lifecycle callbacks
/// - **Environment**: For property resolution and profile management
///
/// ### Usage Pattern:
/// Application developers typically **extend** this class to build custom contexts
/// suited for specific runtime environments (web server, CLI, testing, etc.).
///
/// ```dart
/// class MyCustomApplicationContext extends AbstractApplicationContext {
///   @override
///   Future<ConfigurableListablePodFactory> doGetFreshPodFactory() async {
///     // Provide a custom pod factory implementation
///     return MyCustomPodFactory();
///   }
///
///   @override
///   Future<void> preparePodFactory(ConfigurableListablePodFactory podFactory) async {
///     // Register core application pods before refresh
///     podFactory.registerSingleton('myService', object: ObjectHolder(MyService()));
///     podFactory.registerDefinition('myRepository', MyRepositoryDefinition());
///   }
///
///   @override
///   Future<void> postProcessPodFactory(ConfigurableListablePodFactory podFactory) async {
///     // Apply custom post-processing or decorators
///     await super.postProcessPodFactory(podFactory);
///     await applyCustomConfiguration(podFactory);
///   }
/// }
///
/// void main() async {
///   final context = MyCustomApplicationContext();
///   
///   // Standard lifecycle sequence
///   await context.refresh(); // Prepares, initializes, and publishes refresh event
///   await context.start();   // Marks context as running and publishes start event
///   
///   // Application logic here...
///   
///   await context.stop();    // Stops the context and publishes stop event
///   await context.close();   // Closes the context and releases resources
/// }
/// ```
///
/// ### Template Methods for Subclasses:
/// Subclasses must implement these protected template methods:
/// - `doGetFreshPodFactory()`: Provide a fresh pod factory instance
/// - `preparePodFactory()`: Register pods and configure factory before refresh
/// - `postProcessPodFactory()`: Apply custom processing after factory setup
///
/// ### Auto-Startup Behavior:
/// By default, `isAutoStartup()` returns `true`, meaning the context will
/// automatically start after refresh unless overridden by subclasses.
///
/// ### Important Notes:
/// - **Direct instantiation** of `AbstractApplicationContext` is not recommended
/// - Always **subclass** for specific application needs
/// - Ensure proper **resource cleanup** by implementing `doClose()`
/// - Handle **lifecycle exceptions** appropriately in subclasses
///
/// See also:
/// - [ConfigurableApplicationContext] for the configuration interface
/// - [GenericApplicationContext] for a ready-to-use implementation
/// - [AnnotationConfigApplicationContext] for annotation-based configuration
/// {@endtemplate}
abstract class AbstractApplicationContext extends ConfigurableApplicationContext {
  /// {@template abstract_application_context.jetleaf_application_name_property}
  /// The property key used to override the Jetleaf application name.
  ///
  /// Developers can set this property in their environment configuration
  /// to change the logical application name reported by the context.
  ///
  /// ### Property Resolution Order:
  /// 1. `jetleaf.application.name` (this property)
  /// 2. `application.name` (fallback)
  /// 3. Default naming based on main application class
  ///
  /// ### Configuration Examples:
  /// ```yaml
  /// # application.yaml
  /// jetleaf:
  ///   application:
  ///     name: MyCustomJetleafApp
  /// ```
  ///
  /// ```dart
  /// // Programmatic configuration
  /// environment.setProperty(
  ///   AbstractApplicationContext.JETLEAF_APPLICATION_NAME,
  ///   'MyCustomApp'
  /// );
  /// ```
  /// {@endtemplate}
  static final String JETLEAF_APPLICATION_NAME = "jetleaf.application.name";

  /// {@template abstract_application_context.application_name_property}
  /// The property key used as fallback for application name configuration.
  ///
  /// This property serves as a fallback if `JETLEAF_APPLICATION_NAME`
  /// is not set in the environment. It follows standard Spring-inspired
  /// property naming conventions.
  ///
  /// ### Usage:
  /// ```yaml
  /// # Simpler configuration alternative
  /// application:
  ///   name: MyApplication
  /// ```
  /// {@endtemplate}
  static final String APPLICATION_NAME = "application.name";

  /// {@template abstract_application_context.lifecycle_processor_pod_name}
  /// The reserved pod name for the [LifecycleProcessor] within the Jetleaf context.
  ///
  /// This pod is responsible for managing the lifecycle of all pods
  /// that implement lifecycle interfaces such as [SmartLifecycle] or
  /// have `@PostConstruct`/`@PreDestroy` methods.
  ///
  /// ### Responsibilities:
  /// - Invoking `@PostConstruct` methods during initialization
  /// - Calling `@PreDestroy` methods during shutdown
  /// - Managing [SmartLifecycle] start/stop phases
  /// - Coordinating lifecycle dependencies between pods
  /// {@endtemplate}
  static final String LIFECYCLE_PROCESSOR_POD_NAME = "jetleaf.internal.lifecycleProcessor";

  /// {@template abstract_application_context.application_event_bus_pod_name}
  /// The reserved pod name for the [ApplicationEventBus].
  ///
  /// The event bus enables publish-subscribe communication within the
  /// application context, allowing pods to publish and consume application
  /// events without tight coupling.
  ///
  /// ### Event Types:
  /// - **Context Events**: Lifecycle events like refresh, start, stop
  /// - **Application Events**: Custom domain events specific to application
  /// - **Framework Events**: Internal framework operation events
  ///
  /// ### Usage:
  /// ```dart
  /// class MyService {
  ///   final ApplicationEventBus eventBus;
  ///   
  ///   MyService(this.eventBus);
  ///   
  ///   void performAction() {
  ///     eventBus.publish(MyCustomEvent(this, actionData));
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  static final String APPLICATION_EVENT_BUS_POD_NAME = "jetleaf.internal.applicationEventBus";

  /// {@template abstract_application_context.message_source_pod_name}
  /// The reserved pod name for the [MessageSource].
  ///
  /// The message source provides internationalization (i18n) capabilities
  /// for applications that need to support multiple languages and locales.
  ///
  /// ### Features:
  /// - Message resolution with parameter substitution
  /// - Locale-specific message bundles
  /// - Fallback to default messages
  /// - Hierarchical message source support
  ///
  /// ### Configuration:
  /// ```dart
  /// @Configuration
  /// class AppConfig {
  ///   @Pod
  ///   MessageSource messageSource() {
  ///     return ResourceBundleMessageSource()
  ///       ..setBasename('messages')
  ///       ..setDefaultEncoding('UTF-8');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  static final String MESSAGE_SOURCE_POD_NAME = "jetleaf.internal.messageSource";

  /// {@template abstract_application_context.pod_name_generator_pod_name}
  /// The reserved pod name for the pod name generator.
  ///
  /// This component is responsible for generating default names for
  /// pods that are registered without explicit names. The default
  /// implementation uses class name conventions (e.g., `myService`
  /// for `MyService` class).
  ///
  /// ### Customization:
  /// Applications can provide custom name generators for specialized
  /// naming conventions or integration requirements.
  /// {@endtemplate}
  static final String POD_NAME_GENERATOR_POD_NAME = "jetleaf.internal.podNameGenerator";

  /// {@template abstract_application_context.banner_pod_name}
  /// The reserved pod name for the startup banner.
  ///
  /// The banner is displayed during application startup and can be
  /// customized to show application-specific information, version
  /// details, or custom ASCII art.
  ///
  /// ### Custom Banner Example:
  /// ```dart
  /// @Pod
  /// Banner customBanner() {
  ///   return CustomBanner('''
  ///   ┌──────────────────────────────────────┐
  ///   │           MY APPLICATION             │
  ///   │         Version 1.0.0                │
  ///   └──────────────────────────────────────┘
  ///   ''');
  /// }
  /// ```
  /// {@endtemplate}
  static final String BANNER_POD_NAME = "jetleaf.internal.banner";

  /// {@template abstract_application_context.jetleaf_argument_pod_name}
  /// The reserved pod name for Jetleaf application arguments.
  ///
  /// This pod provides access to the command-line arguments and
  /// application parameters that were passed during startup.
  ///
  /// ### Usage:
  /// ```dart
  /// class MyService {
  ///   final ApplicationArguments args;
  ///   
  ///   MyService(this.args);
  ///   
  ///   void checkArgs() {
  ///     if (args.containsOption('verbose')) {
  ///       print('Verbose mode enabled');
  ///     }
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  static final String JETLEAF_ARGUMENT_POD_NAME = "jetleaf.internal.jetleafApplicationArgument";

  /// {@template abstract_application_context.lock_field}
  /// The lock object used for thread-safe operations.
  ///
  /// This lock ensures that critical sections of the context lifecycle
  /// (refresh, start, stop, close) are executed atomically, preventing
  /// race conditions in multi-threaded environments.
  ///
  /// ### Usage:
  /// ```dart
  /// void someThreadSafeMethod() {
  ///   synchronized(_lock, () {
  ///     // Critical section
  ///     if (!_isActive) {
  ///       initializeComponents();
  ///       _isActive = true;
  ///     }
  ///   });
  /// }
  /// ```
  /// {@endtemplate}
  final Object _lock = new Object();

  /// {@template abstract_application_context.logger_field}
  /// The logger associated with this application context.
  ///
  /// Subclasses should use this logger for all logging activities
  /// related to context lifecycle, configuration, and operations.
  ///
  /// ### Logging Levels:
  /// - `TRACE`: Detailed internal operations
  /// - `DEBUG`: Configuration steps and lifecycle transitions
  /// - `INFO`: Major lifecycle events (refresh, start, stop)
  /// - `WARN`: Non-critical issues and deprecations
  /// - `ERROR`: Critical failures and exceptions
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// Future<void> refresh() async {
  ///   logger.debug('Starting context refresh...');
  ///   try {
  ///     await super.refresh();
  ///     logger.info('Context refreshed successfully');
  ///   } catch (e) {
  ///     logger.error('Context refresh failed', error: e);
  ///     rethrow;
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  final Log logger = LogFactory.getLog(AbstractApplicationContext);

  /// {@template abstract_application_context.pod_factory_post_processors_field}
  /// The list of [PodFactoryPostProcessor]s to be applied to the pod factory.
  ///
  /// These processors are invoked during the refresh process after the
  /// pod factory is created but before any pods are instantiated. They
  /// can modify pod definitions, change configuration, or apply custom
  /// transformations to the factory.
  ///
  /// ### Common Processors:
  /// - `PropertySourcesPlaceholderProcessor`: Resolves `${...}` placeholders
  /// - `ConfigurationClassPostProcessor`: Processes `@Configuration` classes
  /// - Custom processors for application-specific factory customization
  ///
  /// ### Execution Order:
  /// Processors are executed in priority order as defined by the
  /// [Ordered] interface or `@Order` annotation.
  /// {@endtemplate}
  final List<PodFactoryPostProcessor> _podFactoryPostProcessors = [];

  /// {@template abstract_application_context.is_active_field}
  /// Whether the application context is active.
  ///
  /// A context is considered active after successful refresh and
  /// remains active until it is closed. Active contexts can serve
  /// pods and handle requests.
  ///
  /// ### State Transitions:
  /// - `false` → `true`: When refresh() completes successfully
  /// - `true` → `false`: When close() is called
  /// - This state is irreversible once set to `false`
  /// {@endtemplate}
  bool _isActive = false;

  /// {@template abstract_application_context.is_closed_field}
  /// Whether the application context is closed.
  ///
  /// A closed context has released all resources and cannot be
  /// restarted or reused. Attempting to use a closed context
  /// will result in [IllegalStateException].
  ///
  /// ### State Behavior:
  /// - Once closed, a context cannot be refreshed or restarted
  /// - All managed pods are destroyed during closure
  /// - Event listeners are unregistered
  /// - Resources like database connections are released
  /// {@endtemplate}
  bool _isClosed = false;

  /// {@template abstract_application_context.is_running_field}
  /// Whether the application context is running.
  ///
  /// A running context has completed the start lifecycle phase
  /// and is fully operational. This state typically indicates
  /// that the context is ready to handle requests or process work.
  ///
  /// ### Lifecycle Relationship:
  /// - `refresh()`: Sets up context but doesn't start it
  /// - `start()`: Transitions to running state
  /// - `stop()`: Transitions back to non-running state
  /// - `close()`: Always sets running to false
  /// {@endtemplate}
  bool _isRunning = false;

  /// {@template abstract_application_context.is_refreshed_field}
  /// Whether the application context has been refreshed.
  ///
  /// This flag indicates that the context has successfully completed
  /// the refresh process, which includes pod factory initialization,
  /// pod registration, and post-processing.
  ///
  /// ### Refresh Process:
  /// 1. Create fresh pod factory
  /// 2. Register pod definitions
  /// 3. Apply post-processors
  /// 4. Instantiate singleton pods
  /// 5. Publish ContextRefreshedEvent
  /// {@endtemplate}
  bool _isRefreshed = false;

  /// {@template abstract_application_context.startup_date_field}
  /// The startup date of the application context.
  ///
  /// This timestamp marks when the context was successfully refreshed
  /// and became active. It's useful for monitoring, uptime calculation,
  /// and timing-related application logic.
  ///
  /// ### Usage:
  /// ```dart
  /// Duration getUptime() {
  ///   return DateTime.now().difference(_startupDate!);
  /// }
  /// 
  /// String getFormattedStartupTime() {
  ///   return DateFormat('yyyy-MM-dd HH:mm:ss').format(_startupDate!);
  /// }
  /// ```
  /// {@endtemplate}
  DateTime? _startupDate;

  /// {@template abstract_application_context.environment_field}
  /// The environment associated with this application context.
  ///
  /// The environment manages property sources, active profiles, and
  /// configuration properties. It's essential for property resolution
  /// and environment-specific configuration.
  ///
  /// ### Property Source Hierarchy:
  /// 1. Command line arguments (highest precedence)
  /// 2. System properties
  /// 3. Environment variables
  /// 4. Application configuration files
  /// 5. Default properties (lowest precedence)
  /// {@endtemplate}
  Environment? _environment;

  /// {@template abstract_application_context.parent_field}
  /// The parent application context, if any.
  ///
  /// Parent-child context relationships enable hierarchical pod lookup
  /// where a child context can delegate to its parent when a pod is
  /// not found locally.
  ///
  /// ### Use Cases:
  /// - **Module Isolation**: Separate contexts for different application modules
  /// - **Testing**: Child test contexts with parent providing shared services
  /// - **Multi-tenant**: Tenant-specific contexts with shared infrastructure
  /// {@endtemplate}
  ApplicationContext? _parent;

  /// {@template abstract_application_context.application_event_bus_field}
  /// The application event bus associated with this application context.
  ///
  /// This event bus facilitates loose coupling between application
  /// components through event-driven communication patterns.
  ///
  /// ### Event Flow:
  /// 1. Publishers create and publish events
  /// 2. Event bus delivers events to registered listeners
  /// 3. Listeners process events asynchronously or synchronously
  /// 4. Error handlers manage delivery failures
  /// {@endtemplate}
  ApplicationEventBus? _applicationEventBus;

  /// {@template abstract_application_context.message_source_field}
  /// The message source associated with this application context.
  ///
  /// Provides internationalization support through message resolution
  /// and locale management. Can be hierarchical for fallback behavior.
  ///
  /// ### Resolution Process:
  /// 1. Look for message in specific locale bundle
  /// 2. Fall back to less specific locale (en_US → en)
  /// 3. Use default locale if specified
  /// 4. Return default message or throw if not found
  /// {@endtemplate}
  MessageSource? _messageSource;

  /// {@template abstract_application_context.application_startup_field}
  /// The application startup associated with this application context.
  ///
  /// Tracks application startup metrics and performance data for
  /// monitoring and optimization purposes.
  ///
  /// ### Tracked Metrics:
  /// - Context initialization time
  /// - Pod instantiation duration
  /// - Post-processor execution time
  /// - Total startup duration
  /// {@endtemplate}
  ApplicationStartup? _applicationStartup;

  /// {@template abstract_application_context.lifecycle_processor_field}
  /// The lifecycle processor associated with this application context.
  ///
  /// Manages the complete lifecycle of all pods within the context,
  /// ensuring proper initialization order and cleanup.
  ///
  /// ### Lifecycle Phases:
  /// - **Initialization**: `@PostConstruct` methods, aware interfaces
  /// - **Startup**: SmartLifecycle start, context started event
  /// - **Running**: Normal operation
  /// - **Shutdown**: SmartLifecycle stop, `@PreDestroy` methods
  /// - **Destruction**: Resource cleanup, context closed event
  /// {@endtemplate}
  LifecycleProcessor? _lifecycleProcessor;

  /// {@template abstract_application_context.main_application_class_field}
  /// The main application class associated with this application context.
  ///
  /// This class serves as the entry point for component scanning and
  /// provides metadata for framework operations like banner display
  /// and package resolution.
  ///
  /// ### Framework Usage:
  /// - Base package for component scanning
  /// - Banner display during startup
  /// - Application metadata and version information
  /// - Configuration class detection
  /// {@endtemplate}
  Class<Object>? _mainApplicationClass;

  /// {@template abstract_application_context.pod_factory_field}
  /// The pod factory associated with this application context.
  ///
  /// This is the core dependency injection container that manages
  /// pod definitions, instantiation, and dependency resolution.
  ///
  /// ### Responsibilities:
  /// - Pod definition registration and storage
  /// - Dependency injection and resolution
  /// - Singleton management and caching
  /// - Lifecycle coordination with context
  /// - Circular dependency detection and handling
  ///
  /// ### Access Pattern:
  /// Subclasses should access the pod factory through `getPodFactory()`
  /// rather than directly accessing this field to ensure proper
  /// lifecycle state checking.
  /// {@endtemplate}
  @protected
  ConfigurableListablePodFactory? podFactory;

  /// {@template abstract_application_context.lifecycle_methods_field}
  /// The lifecycle methods associated with this application context.
  ///
  /// These methods are annotated with lifecycle annotations like
  /// `@OnApplicationStopping` and `@OnApplicationStopped` and are
  /// invoked during the corresponding lifecycle phases.
  ///
  /// ### Supported Annotations:
  /// - `@OnApplicationStopping`: Called when context is stopping
  /// - `@OnApplicationStopped`: Called when context is fully stopped
  /// - `@OnApplicationStarting`: Called when context is starting
  /// - `@OnApplicationStarted`: Called when context is fully started
  ///
  /// ### Method Requirements:
  /// - Must be `static` methods
  /// - Can accept `ApplicationContext` parameter
  /// - Should not throw exceptions (handled gracefully)
  /// {@endtemplate}
  List<Method> _lifecycleMethods = [];

  /// {@template abstract_application_context.conversion_service_field}
  /// The conversion service to be used in this context.
  ///
  /// Handles type conversion between different data types during
  /// configuration processing, property resolution, and data binding.
  ///
  /// ### Built-in Conversions:
  /// - String to primitive types (int, double, bool, etc.)
  /// - String to DateTime with various formats
  /// - Collection and array conversions
  /// - Custom type conversions via converter registration
  ///
  /// ### Custom Converters:
  /// ```dart
  /// class MoneyConverter implements Converter<String, Money> {
  ///   @override
  ///   Money convert(String source) {
  ///     return Money.parse(source);
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  late ConversionService _conversionService;

  /// {@template abstract_application_context.constructor}
  /// Creates a new [AbstractApplicationContext] and scans for lifecycle methods.
  ///
  /// The constructor performs initial setup including:
  /// - Logger initialization for context operations
  /// - Conversion service setup with default converters
  /// - Lifecycle method discovery via reflection
  /// - Internal state initialization
  ///
  /// ### Lifecycle Method Discovery:
  /// Automatically discovers methods annotated with:
  /// - `@OnApplicationStopping`
  /// - `@OnApplicationStopped`
  /// 
  /// These methods are invoked during the corresponding lifecycle phases.
  ///
  /// ### Important:
  /// Subclasses should not override this constructor. Instead, override
  /// the template methods for custom initialization logic.
  /// {@endtemplate}
  /// 
  /// {@macro abstract_application_context}
  AbstractApplicationContext() {
    final methods = Runtime.getAllMethods().where((m) => m.getAnnotations().any((a) {
      return a.getType() == OnApplicationStopping || a.getType() == OnApplicationStopped;
    }));

    _lifecycleMethods.addAll(methods.map((m) => Method.declared(m, ProtectionDomain.system())));
    _conversionService = DefaultConversionService();
  }

  // ---------------------------------------------------------------------------------------------------------
  // OVERRIDDEN METHODS
  // ---------------------------------------------------------------------------------------------------------
  
  @override
  bool isAutoStartup() => true; // Auto-start by default
  
  @override
  bool isRunning() => _isRunning;

  @override
  bool isActive() => _isActive;

  @override
  bool isClosed() => _isClosed;
  
  @override
  FutureOr<void> start() {
    return synchronized(_lock, () async {
      if (!_isRunning) {
        _isRunning = true;
        await publishEvent(ContextStartedEvent.withClock(this, () => getStartTime()));

        await doStart();
      }
    });
  }
  
  @override
  FutureOr<void> stop([Runnable? callback]) {
    return synchronized(_lock, () async {
      if (_isRunning) {
        final stoppingMethods = List.from(_lifecycleMethods.where((m) => m.hasDirectAnnotation<OnApplicationStopping>()));
        
        for(final method in stoppingMethods) {
          final cls = method.getDeclaringClass();
          final instance = cls.isAbstract() ? null : cls.getNoArgConstructor()?.newInstance();

          final arguments = <String, Object?>{};
          final parameters = method.getParameters();
          final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
          
          if(contextArgName != null) {
            arguments[contextArgName] = this;
          }
          
          method.invoke(instance, arguments);
        }
        
        _isRunning = false;
        await publishEvent(ContextStoppedEvent.withClock(this, () => DateTime.now()));

        await doStop();

        final stoppedMethods = _lifecycleMethods.where((m) => m.hasDirectAnnotation<OnApplicationStopped>());
        
        for(final method in stoppedMethods) {
          final cls = method.getDeclaringClass();
          final instance = cls.isAbstract() ? null : cls.getNoArgConstructor()?.newInstance();

          final arguments = <String, Object?>{};
          final parameters = method.getParameters();
          final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
          
          if(contextArgName != null) {
            arguments[contextArgName] = this;
          }
          
          method.invoke(instance, arguments);
        }
      }
      
      callback?.run();
    });
  }
  
  @override
  String getApplicationName() {
    final name = getEnvironment().getProperty(JETLEAF_APPLICATION_NAME) ?? getEnvironment().getProperty(APPLICATION_NAME);
    return name ?? "JetLeafApplication";
  }
  
  @override
  DateTime getStartTime() => _startupDate ?? DateTime.now();

  @override
  Future<void> publishEvent(ApplicationEvent event) async {
    await _applicationEventBus?.onEvent(event);
  }

  @override
  void addPodFactoryPostProcessor(PodFactoryPostProcessor processor) {
    _podFactoryPostProcessors.add(processor);
  }

  @override
  Environment getEnvironment() {
    if (_environment == null) {
      return GlobalEnvironment();
    }

    return _environment!;
  }

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  @override
  void setParent(ApplicationContext parent) {
    _parent = parent;
    if (_parent != null) {
      final parentEnvironment = parent.getEnvironment();
      if (_environment == null) {
        setEnvironment(parentEnvironment);
      }
    }
  }

  @override
  ApplicationContext? getParent() => _parent;

  @override
  Future<void> addApplicationListener(ApplicationEventListener listener) async {
    await _applicationEventBus?.addApplicationListener(listener: listener);
  }

  @override
  Future<void> close() async {
    return synchronized(_lock, () async {
      if (_isClosed) {
        return;
      }

      _isClosed = true;
      
      try {
        // Stop lifecycle processors
        await _lifecycleProcessor?.onClose();

        // Publish close event
        await publishEvent(ContextClosedEvent.withClock(this, () => DateTime.now()));

        // Destroy singletons
        destroySingletons();

        // Perform actual cleanup
        await doClose();

        _isActive = false;
        _isRunning = false;
      } catch (e) {
        if(logger.getIsErrorEnabled()) {
          logger.error("Unable to close context due to some issues.", error: e);
        }
      }
    });
  }

  @override
  Future<void> refresh() async {
    return synchronized(_lock, () async {
      // Prepare this context for refreshing.
      await prepareRefresh();

      // Tell the subclass to refresh the internal bean factory.
      ConfigurableListablePodFactory podFactory = await doGetFreshPodFactory();
      this.podFactory = podFactory;

      // Prepare the pod factory for use in this context.
      await preparePodFactory();

      try {
        // Allows post-processing of the pod factory in context subclasses.
        await postProcessPodFactory();

        // Invoke factory processors registered as pods in the context.
        await invokePodFactoryPostProcessors();

        // Register pod processors that intercept pod creation.
        await registerPodAwareProcessors();

        // Initialize message source for this context.
        await initMessageSource();

        // Initialize event multicaster for this context.
        await initApplicationEventBus();

        // Initialize other special pods in specific context subclasses.
        await completeRefresh();

        // Check for listener pods and register them.
        await registerListeners();

        // Instantiate all remaining (non-lazy-init) singletons.
        await finishPodFactoryInitialization();

        // Last step: publish corresponding event.
        await finishRefresh();
      } on PodException catch (ex) {
        if (logger.getIsWarnEnabled()) {
          logger.warn("Exception encountered during context initialization - cancelling refresh attempt: $ex");
        }
        
        // Destroy already created singletons to avoid dangling resources.
        await destroyPods();

        // Reset 'active' flag.
        await cancelRefresh(ex);

        // Propagate exception to caller.
        throw ex;
      } finally {
        // Reset common introspection caches ...
        await resetCommonCaches();
      }
    });
  }

  @override
  String getMessage(String code, {List<Object>? args, Locale? locale, String? defaultMessage}) {
    if(_messageSource == null) {
      throw InvalidArgumentException("Message source has not been initialized yet");
    }

    return _messageSource!.getMessage(code, args: args, locale: locale, defaultMessage: defaultMessage);
  }

  @override
  void setMessageSource(MessageSource messageSource) {
    _messageSource = messageSource;
  }

  @override
  MessageSource getMessageSource() {
    if(_messageSource == null) {
      throw IllegalStateException("Cannot access message source since it has not been initialized yet.");
    }

    return _messageSource!;
  }

  @override
  void setApplicationEventBus(ApplicationEventBus applicationEventBus) {
    _applicationEventBus = applicationEventBus;
  }

  @override
  ApplicationEventBus getApplicationEventBus() {
    if(_applicationEventBus == null) {
      throw IllegalStateException("Cannot access application event bus since it has not been initialized yet.");
    }

    return _applicationEventBus!;
  }

  @override
  ApplicationStartup getApplicationStartup() {
    if(_applicationStartup == null) {
      throw IllegalStateException("Cannot access application startup since it has not been initialized yet.");
    }

    return _applicationStartup!;
  }

  @override
  void setApplicationStartup(ApplicationStartup applicationStartup) {
    _applicationStartup = applicationStartup;
  }

  @override
  void setMainApplicationClass(Class<Object> mainApplicationClass) {
    _mainApplicationClass = mainApplicationClass;
  }

  @override
  Class<Object> getMainApplicationClass() {
    if(_mainApplicationClass == null) {
      throw IllegalStateException("Cannot access main application class since it has not been initialized yet.");
    }

    return _mainApplicationClass!;
  }

  @override
  void setConversionService(ConversionService conversionService) {
    _conversionService = conversionService;
  }

  @override
  ConversionService getConversionService() => _conversionService;

  @override
  Future<T> get<T>(Class<T> type, [List<ArgumentValue>? args]) async {
    final f = getPodFactory();

    // Prefer local beans (without forcing eager init of parent beans)
    if (await _hasLocalPodsOfType(type)) {
      return await f.get(type, args);
    }

    // Fallback to parent
    if (_parent != null) {
      return await _parent!.get(type, args);
    }

    throw NoSuchPodDefinitionException.byTypeWithMessage(type, 'No pod of type ${type} found in context or ancestors');
  }

  @override
  Future<bool> containsPod(String podName) async {
    final f = getPodFactory();

    final localContains = await f.containsPod(podName);
    if (localContains) {
      return true;
    }

    if (_parent != null) {
      return await _parent!.containsPod(podName);
    }
    
    return false;
  }

  @override
  Future<bool> isSingleton(String podName) async {
    final f = getPodFactory();

    if (await f.containsLocalPod(podName)) {
      return await f.isSingleton(podName);
    }

    if (_parent != null) {
      return await _parent!.isSingleton(podName);
    }
    
    return false;
  }

  @override
  Future<bool> isPrototype(String podName) async {
    final f = getPodFactory();

    if (await f.containsLocalPod(podName)) {
      return await f.isPrototype(podName);
    }

    if (_parent != null) {
      return await _parent!.isPrototype(podName);
    }
    
    return false;
  }

  @override
  bool getAllowCircularReferences() => getPodFactory().getAllowCircularReferences();
  
  @override
  bool getAllowDefinitionOverriding() => getPodFactory().getAllowDefinitionOverriding();
  
  @override
  bool getAllowRawInjectionEvenWhenWrapped() => getPodFactory().getAllowRawInjectionEvenWhenWrapped();
  
  @override
  void setAllowRawInjectionEvenWhenWrapped(bool value) => getPodFactory().setAllowRawInjectionEvenWhenWrapped(value);

  @override
  Future<ObjectProvider<T>> getProvider<T>(Class<T> type, {String? podName, bool allowEagerInit = false}) async {
    final f = getPodFactory();

    if (_parent != null) {
      return await _parent!.getProvider(type, podName: podName, allowEagerInit: allowEagerInit);
    }

    return await f.getProvider(type, podName: podName, allowEagerInit: allowEagerInit);
  }

  @override
  Future<Class> getPodClass(String podName) async {
    final f = getPodFactory();

    if (await f.containsLocalPod(podName)) {
      return await f.getPodClass(podName);
    }

    if (_parent != null) {
      return await _parent!.getPodClass(podName);
    }
    
    throw NoSuchPodDefinitionException.byNameWithMessage(podName, 'No pod class for pod $podName');
  }

  @override
  Future<T> getPod<T>(String podName, [List<ArgumentValue>? args, Class<T>? type]) async {
    final f = getPodFactory();

    if (await f.containsLocalPod(podName)) {
      return await f.getPod<T>(podName, args, type);
    }

    if (_parent != null) {
      return await _parent!.getPod<T>(podName, args, type);
    }
    
    throw NoSuchPodDefinitionException.byNameWithMessage(podName, 'No pod $podName');
  }

  @override
  Future<Object> getObject(Class<Object> type, [List<ArgumentValue>? args]) async {
    final f = getPodFactory();

    if (await _hasLocalPodsOfType(type)) {
      return await f.getObject(type, args);
    }

    if (_parent != null) {
      return await _parent!.getObject(type, args);
    }
    
    throw NoSuchPodDefinitionException.byTypeWithMessage(type, 'No object of type $type');
  }

  @override
  Future<Object> getNamedObject(String podName, [List<ArgumentValue>? args]) async {
    final f = getPodFactory();

    if (await f.containsLocalPod(podName)) {
      return await f.getNamedObject(podName, args);
    }

    if (_parent != null) {
      return await _parent!.getNamedObject(podName, args);
    }
    
    throw NoSuchPodDefinitionException.byNameWithMessage(podName, 'No named pod $podName');
  }

  @override
  List<String> getAliases(String podName) {
    // aliases are metadata; always copy local collection before merging
    final f = getPodFactory();

    final local = List<String>.from(f.getAliases(podName));
    if (_parent != null) {
      local.addAll(_parent!.getAliases(podName));
    }

    return local;
  }

  @override
  Future<Object?> resolveDependency(DependencyDescriptor descriptor, [Set<String>? candidates]) async {
    final f = getPodFactory();

    final result = await f.resolveDependency(descriptor, candidates);
    if (result != null) {
      return result;
    }

    if (_parent != null) {
      return await _parent!.resolveDependency(descriptor, candidates);
    }
    
    return null;
  }

  @override
  void addSingletonCallback(String name, Class type, Consumer<Object> callback) {
    // local-only mutation. registering on parent implicitly is surprising.
    getPodFactory().addSingletonCallback(name, type, callback);
  }

  @override
  void addPodAwareProcessor(PodAwareProcessor processor) {
    // local-only mutation. registering on parent implicitly is surprising.
    getPodFactory().addPodAwareProcessor(processor);
  }
  
  @override
  void clearMetadataCache() {
    getPodFactory().clearMetadataCache();

    if (_parent != null) {
      _parent!.getPodFactory().clearMetadataCache();
    }
  }
  
  @override
  void clearSingletonCache() {
    getPodFactory().clearSingletonCache();

    if (_parent != null) {
      _parent!.getPodFactory().clearSingletonCache();
    }
  }
  
  @override
  bool containsDefinition(String name) {
    if (_parent != null && _parent!.getPodFactory().containsDefinition(name)) {
      return true;
    }

    return getPodFactory().containsDefinition(name);
  }
  
  @override
  Future<bool> containsLocalPod(String podName) => getPodFactory().containsLocalPod(podName);
  
  @override
  bool containsSingleton(String name) {
    if (_parent != null && _parent!.getPodFactory().containsSingleton(name)) {
      return true;
    }
    
    return getPodFactory().containsSingleton(name);
  }
  
  @override
  void copyConfigurationFrom(ConfigurablePodFactory otherFactory) {
    // local-only copy
    getPodFactory().copyConfigurationFrom(otherFactory);
  }
  
  @override
  Future<void> destroyPod(String podName, Object podInstance) async {
    if (_parent != null && await _parent!.getPodFactory().containsLocalPod(podName)) {
      return await _parent!.getPodFactory().destroyPod(podName, podInstance);
    }

    return await getPodFactory().destroyPod(podName, podInstance);
  }
  
  @override
  void destroyScopedPod(String podName) async {
    if (_parent != null && await _parent!.getPodFactory().containsLocalPod(podName)) {
      _parent!.getPodFactory().destroyScopedPod(podName);
      return;
    }

    getPodFactory().destroyScopedPod(podName);
  }
  
  @override
  void destroySingletons() {
    // lifecycle ops stay local; do not force parent to run its lifecycle from a child
    getPodFactory().destroySingletons();
  }
  
  @override
  Future<Set<A>> findAllAnnotationsOnPod<A>(String podName, Class<A> type) async {
    if (_parent != null && await _parent!.getPodFactory().containsDefinition(podName)) {
      return await _parent!.getPodFactory().findAllAnnotationsOnPod(podName, type);
    }

    return await getPodFactory().findAllAnnotationsOnPod(podName, type);
  }
  
  @override
  Future<A?> findAnnotationOnPod<A>(String podName, Class<A> type) async {
    if (_parent != null && await _parent!.getPodFactory().containsDefinition(podName)) {
      return await _parent!.getPodFactory().findAnnotationOnPod(podName, type);
    }

    return await getPodFactory().findAnnotationOnPod(podName, type);
  }
  
  @override
  PodDefinition getDefinition(String name) {
    if (_parent != null && _parent!.getPodFactory().containsDefinition(name)) {
      return _parent!.getPodFactory().getDefinition(name);
    }

    return getPodFactory().getDefinition(name);
  }
  
  @override
  List<String> getDefinitionNames() {
    final local = List<String>.from(getPodFactory().getDefinitionNames());
    if (_parent != null) {
      local.addAll(_parent!.getPodFactory().getDefinitionNames());
    }

    return local;
  }
  
  @override
  RootPodDefinition getMergedPodDefinition(String podName) {
    if (_parent != null && _parent!.getPodFactory().containsDefinition(podName)) {
      return _parent!.getPodFactory().getMergedPodDefinition(podName);
    }

    return getPodFactory().getMergedPodDefinition(podName);
  }
  
  @override
  int getNumberOfPodDefinitions() {
    int count = getPodFactory().getNumberOfPodDefinitions();

    if (_parent != null) {
      count += _parent!.getPodFactory().getNumberOfPodDefinitions();
    }

    return count;
  }
  
  @override
  PodFactory? getParentFactory() => _parent?.getPodFactory();
  
  @override
  int getPodAwareProcessorCount() {
    int count = getPodFactory().getPodAwareProcessorCount();

    if (_parent != null) {
      count += _parent!.getPodFactory().getPodAwareProcessorCount();
    }

    return count;
  }
  
  @override
  List<PodAwareProcessor> getPodAwareProcessors() {
    final list = List<PodAwareProcessor>.from(getPodFactory().getPodAwareProcessors());

    if (_parent != null) {
      list.addAll(_parent!.getPodFactory().getPodAwareProcessors());
    }

    return list;
  }
  
  @override
  PodExpressionResolver? getPodExpressionResolver() {
    if (_parent != null) {
      return _parent!.getPodFactory().getPodExpressionResolver();
    }

    return getPodFactory().getPodExpressionResolver();
  }
  
  @override
  Future<List<String>> getPodNames(Class type, {bool includeNonSingletons = false, bool allowEagerInit = false}) async {
    List<String> list = List<String>.from(await getPodFactory().getPodNames(type, includeNonSingletons: includeNonSingletons, allowEagerInit: allowEagerInit));
    
    if (_parent != null) {
      list.addAll(await _parent!.getPodFactory().getPodNames(type, includeNonSingletons: includeNonSingletons, allowEagerInit: allowEagerInit));
    }
    
    return list;
  }
  
  @override
  Future<List<String>> getPodNamesForAnnotation<A>(Class<A> type) async {
    List<String> list = List<String>.from(await getPodFactory().getPodNamesForAnnotation(type));
    
    if (_parent != null) {
      list.addAll(await _parent!.getPodFactory().getPodNamesForAnnotation(type));
    }
    
    return list;
  }
  
  @override
  Iterator<String> getPodNamesIterator() {
    final allNames = <String>{};
    
    // Add pod definition names first
    allNames.addAll(getDefinitionNames());
    
    // Add manually registered singleton names
    final singletonNames = getSingletonNames();
    for (final name in singletonNames) {
      if (!allNames.contains(name)) {
        allNames.add(name);
      }
    }
    
    return allNames.iterator;
  }
  
  @override
  Future<Map<String, T>> getPodsOf<T>(Class<T> type, {bool includeNonSingletons = false, bool allowEagerInit = false}) async {
    Map<String, T> map = Map<String, T>.from(await getPodFactory().getPodsOf(type, includeNonSingletons: includeNonSingletons, allowEagerInit: allowEagerInit));
    
    if (_parent != null) {
      map.addAll(await _parent!.getPodFactory().getPodsOf(type, includeNonSingletons: includeNonSingletons, allowEagerInit: allowEagerInit));
    }
    
    return map;
  }
  
  @override
  Future<Map<String, Object>> getPodsWithAnnotation<A>(Class<A> type) async {
    Map<String, Object> map = Map<String, Object>.from(await getPodFactory().getPodsWithAnnotation(type));
    
    if (_parent != null) {
      map.addAll(await _parent!.getPodFactory().getPodsWithAnnotation(type));
    }
    
    return map;
  }
  
  @override
  PodScope? getRegisteredScope(String scopeName) {
    if (_parent != null) {
      return _parent!.getPodFactory().getRegisteredScope(scopeName);
    }
    
    return getPodFactory().getRegisteredScope(scopeName);
  }
  
  @override
  List<String> getRegisteredScopeNames() {
    List<String> list = List<String>.from(getPodFactory().getRegisteredScopeNames());
    
    if (_parent != null) {
      list.addAll(_parent!.getPodFactory().getRegisteredScopeNames());
    }
    
    return list;
  }
  
  @override
  Future<Object?> getSingleton(String name, {bool allowEarlyReference = true, ObjectFactory<Object>? factory}) async {
    // prefer local singleton; if not found, delegate to parent (no exceptions swallowed)
    final f = getPodFactory();

    if (f.containsSingleton(name)) return await f.getSingleton(name, allowEarlyReference: allowEarlyReference, factory: factory);
    if (_parent != null) return await _parent!.getPodFactory().getSingleton(name, allowEarlyReference: allowEarlyReference, factory: factory);
    
    return null;
  }
  
  @override
  int getSingletonCount() {
    int count = getPodFactory().getSingletonCount();
    
    if (_parent != null) {
      count += _parent!.getPodFactory().getSingletonCount();
    }
    
    return count;
  }
  
  @override
  List<String> getSingletonNames() {
    List<String> list = List<String>.from(getPodFactory().getSingletonNames());
    
    if (_parent != null) {
      list.addAll(_parent!.getPodFactory().getSingletonNames());
    }
    
    return list;
  }
  
  @override
  bool isAutowireCandidate(String podName, DependencyDescriptor descriptor) {
    final f = getPodFactory();

    if (f.isAutowireCandidate(podName, descriptor)) {
      return true;
    }
    
    if (_parent != null) {
      return _parent!.getPodFactory().isAutowireCandidate(podName, descriptor);
    }
    
    return false;
  }
  
  @override
  bool isCachePodMetadata() {
    final f = getPodFactory();

    if (_parent != null) {
      return f.isCachePodMetadata() || _parent!.getPodFactory().isCachePodMetadata();
    }
    
    return f.isCachePodMetadata();
  }
  
  @override
  bool isActuallyInCreation(String podName) {
    final f = getPodFactory();

    if (f.isActuallyInCreation(podName)) {
      return true;
    }
    
    if (_parent != null) {
      return _parent!.getPodFactory().isActuallyInCreation(podName);
    }
    
    return false;
  }

  @override
  Future<bool> containsType(Class type, [bool allowPodProviderInit = false]) async {
    final f = getPodFactory();

    if (await f.containsType(type, allowPodProviderInit)) {
      return true;
    }
    
    if (_parent != null) {
      return _parent!.getPodFactory().containsType(type, allowPodProviderInit);
    }
    
    return false;
  }

  @override
  Future<bool> isTypeMatch(String name, Class typeToMatch, [bool allowPodProviderInit = false]) async {
    final f = getPodFactory();

    if (await f.isTypeMatch(name, typeToMatch, allowPodProviderInit)) {
      return true;
    }
    
    if (_parent != null) {
      return _parent!.getPodFactory().isTypeMatch(name, typeToMatch, allowPodProviderInit);
    }
    
    return false;
  }
  
  @override
  Future<bool> isNameInUse(String name) async {
    final f = getPodFactory();

    if (await f.isNameInUse(name)) {
      return true;
    }
    
    if (_parent != null) {
      return await _parent!.getPodFactory().isNameInUse(name);
    }
    
    return false;
  }
  
  @override
  Future<bool> isPodProvider(String podName, [RootPodDefinition? rpd]) async {
    final f = getPodFactory();

    if (await f.isPodProvider(podName, rpd)) {
      return true;
    }
    
    if (_parent != null) {
      return await _parent!.getPodFactory().isPodProvider(podName, rpd);
    }
    
    return false;
  }
  
  @override
  Future<void> preInstantiateSingletons() async {
    await getPodFactory().preInstantiateSingletons();
  }
  
  @override
  void registerAlias(String name, String alias) {
    // registration is local-only
    getPodFactory().registerAlias(name, alias);
  }
  
  @override
  Future<void> registerDefinition(String name, PodDefinition pod) async {
    await getPodFactory().registerDefinition(name, pod);
  }
  
  @override
  void registerIgnoredDependency(Class type) {
    getPodFactory().registerIgnoredDependency(type);
  }
  
  @override
  void registerResolvableDependency(Class type, [Object? autowiredValue]) {
    getPodFactory().registerResolvableDependency(type, autowiredValue);
  }
  
  @override
  void registerScope(String scopeName, PodScope scope) {
    getPodFactory().registerScope(scopeName, scope);
  }
  
  @override
  Future<void> registerSingleton(String name, Class type, {ObjectHolder<Object>? object, ObjectFactory<Object>? factory}) async {
    await getPodFactory().registerSingleton(name, type, object: object, factory: factory);
  }
  
  @override
  Future<void> removeDefinition(String name) async {
    await getPodFactory().removeDefinition(name);
  }
  
  @override
  void removeSingleton(String name) {
    getPodFactory().removeSingleton(name);
  }
  
  @override
  void setAllowCircularReferences(bool value) {
    getPodFactory().setAllowCircularReferences(value);
  }
  
  @override
  void setAllowDefinitionOverriding(bool value) {
    getPodFactory().setAllowDefinitionOverriding(value);
  }
  
  @override
  void setCachePodMetadata(bool cachePodMetadata) {
    getPodFactory().setCachePodMetadata(cachePodMetadata);
  }
  
  @override
  void setParentFactory(PodFactory? parentFactory) {
    getPodFactory().setParentFactory(parentFactory);
  }
  
  @override
  void setPodExpressionResolver(PodExpressionResolver? valueResolver) {
    getPodFactory().setPodExpressionResolver(valueResolver);
  }

  @override
  String getPackageName() => PackageNames.CORE;

  // ---------------------------------------------------------------------------------------------------------
  // PRIVATE METHODS
  // ---------------------------------------------------------------------------------------------------------

  /// Checks if the given [clazz] is assignable to [ApplicationContext]
  bool _isAssignableFromApplicationContext(Class clazz) {
    return Class<ApplicationContext>().isAssignableFrom(clazz);
  }

  // Helper: returns true if the local factory has at least one pod of the given type
  Future<bool> _hasLocalPodsOfType(Class type, {bool includeNonSingletons = false, bool allowEagerInit = false}) async {
    final f = getPodFactory();
    final names = await f.getPodNames(type, includeNonSingletons: includeNonSingletons, allowEagerInit: allowEagerInit);
    return names.isNotEmpty;
  }

  // ---------------------------------------------------------------------------------------------------------
  // PROTECTED METHODS
  // ---------------------------------------------------------------------------------------------------------

  /// {@template abstract_application_context_is_refreshed}
  /// Returns true if the application context has been refreshed.
  /// {@endtemplate}
  @protected
  bool getIsRefreshed() => _isRefreshed;
  
  /// {@template pod_factory_post_processors_field}
  /// The list of [PodFactoryPostProcessor]s to be applied to the pod factory.
  /// 
  /// These are processors that are applied to the pod factory after it has been created.
  /// {@endtemplate}
  @protected
  List<PodFactoryPostProcessor> getPodFactoryPostProcessors() => _podFactoryPostProcessors;

  /// {@template abstract_application_context_do_start}
  /// Template method invoked during [start] to perform startup logic.
  ///
  /// Subclasses can override this to initialize services, schedule jobs,
  /// or perform any tasks that need to occur when the application context starts.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> doStart() async {
  /// logger.info("Custom startup logic here");
  /// }
  /// ```
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> doStart() async {
    // Default implementation - subclasses can override
  }

  /// {@template abstract_application_context_do_stop}
  /// Template method invoked during [stop] to perform shutdown logic.
  ///
  /// Subclasses can override this to clean up resources, close connections,
  /// or perform graceful shutdown procedures.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> doStop() async {
  /// logger.info("Cleaning up resources before shutdown");
  /// }
  /// ```
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> doStop() async {
    // Default implementation - subclasses can override
  }

  /// {@template abstract_application_context_do_close}
  /// Template method for actual cleanup logic when the context is closed.
  ///
  /// Subclasses can override this to perform specific cleanup tasks such as
  /// releasing caches, closing thread pools, or persisting final state.
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> doClose() async {
    // Default implementation - subclasses can override
  }

  /// {@template prepare_refresh}
  /// Prepares the application context for a refresh.
  ///
  /// This method resets lifecycle flags, records the startup timestamp,
  /// and logs that the context is being refreshed. It is invoked internally
  /// before creating a fresh pod factory.
  ///
  /// Subclasses may override this to perform custom pre-refresh logic,
  /// such as resetting caches or preparing configuration sources.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> prepareRefresh() async {
  /// await super.prepareRefresh();
  /// logger.info("Preparing additional refresh state");
  /// }
  /// ```
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> prepareRefresh() async {
    _startupDate = DateTime.now();
    _isClosed = false;
    _isActive = true;

    if (logger.getIsInfoEnabled()) {
      logger.info("Starting refresh of ${runtimeType} application context...");
    }
  }

  /// {@template do_get_fresh_pod_factory}
  /// Returns a fresh [ConfigurableListablePodFactory] for this context.
  ///
  /// Subclasses must implement this to provide a new factory instance
  /// whenever the context is refreshed.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<ConfigurableListablePodFactory> doGetFreshPodFactory() async {
  /// return DefaultListablePodFactory();
  /// }
  /// ```
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<ConfigurableListablePodFactory> doGetFreshPodFactory();

  /// {@template prepare_pod_factory}
  /// Prepares the [ConfigurableListablePodFactory] for this context.
  ///
  /// Subclasses typically register default pods, configure singleton pods,
  /// or set up dependency wiring at this stage.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> preparePodFactory(ConfigurableListablePodFactory factory) async {
  /// factory.registerSingleton('myService', object: ObjectHolder(MyService()));
  /// }
  /// ```
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> preparePodFactory() async {}

  /// {@template post_process_pod_factory}
  /// Post-processes the [ConfigurableListablePodFactory] for this context.
  ///
  /// Subclasses can override this to apply additional decorators,
  /// inject cross-cutting concerns, or manipulate pod definitions
  /// before initialization is finalized.
  ///
  /// *This is part of Jetleaf – a framework developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> postProcessPodFactory() async {}

  /// {@template invoke_pod_factory_post_processors}
  /// Invokes all registered pod factory post-processors on the given
  /// [ConfigurableListablePodFactory].
  ///
  /// This step allows any user-defined or framework-level processors
  /// to modify pod metadata, enrich configurations, or validate settings
  /// before pods are created.
  ///
  /// Typically invoked immediately after [postProcessPodFactory].
  /// {@endtemplate}
  @protected
  Future<void> invokePodFactoryPostProcessors() async {}

  /// {@template register_pod_aware_processors}
  /// Registers all *PodAware* processors into the given
  /// [ConfigurableListablePodFactory].
  ///
  /// These processors are responsible for integrating pods that
  /// implement awareness interfaces (such as lifecycle callbacks
  /// or context-aware contracts).
  ///
  /// Subclasses may override this to register additional
  /// Jetleaf-specific processors.
  /// {@endtemplate}
  @protected
  Future<void> registerPodAwareProcessors() async {}

  /// {@template complete_refresh}
  /// Completes the refresh process for the given
  /// [ConfigurableListablePodFactory].
  ///
  /// This step finalizes the pod factory initialization, ensuring
  /// that all post-processors have been executed, all metadata
  /// validated, and the context is marked as "refreshed".
  ///
  /// Override to perform custom logic after the container
  /// has successfully completed initialization.
  /// {@endtemplate}
  @protected
  Future<void> completeRefresh() async {
    _lifecycleProcessor?.onRefresh();
    return Future.value();
  }

  /// {@template destroy_pods}
  /// Destroys all managed pods in the given
  /// [ConfigurableListablePodFactory].
  ///
  /// Called during shutdown or refresh cancellation to ensure
  /// graceful resource cleanup. This includes invoking
  /// registered destroy methods and releasing references.
  ///
  /// Subclasses can extend this for additional teardown steps.
  /// {@endtemplate}
  @protected
  Future<void> destroyPods() async {
    destroySingletons();
    return Future.value();
  }

  /// {@template cancel_refresh}
  /// Cancels the refresh process due to the provided [PodException].
  ///
  /// This method allows subclasses to roll back partially
  /// initialized state, release resources, and log or propagate
  /// errors consistently.
  ///
  /// Called whenever initialization fails in the middle of a
  /// refresh cycle.
  /// {@endtemplate}
  @protected
  Future<void> cancelRefresh(PodException exception) async {}

  /// {@template reset_common_caches}
  /// Resets common internal caches maintained by the container.
  ///
  /// This includes metadata caches, reflection results, and
  /// pod definition lookups that may persist across refresh cycles.
  ///
  /// Subclasses may override this to clear any additional
  /// framework-level caches.
  /// {@endtemplate}
  @protected
  Future<void> resetCommonCaches() async {
    clearMetadataCache();
    clearSingletonCache();
  }

  /// {@template init_message_source}
  /// Initializes the [MessageSource] for this context.
  ///
  /// This is invoked during refresh to set up i18n message resolution.
  /// By default, it discovers non-abstract subclasses of [MessageSource],
  /// wraps them in a [DelegatingMessageSource], and registers the result
  /// in the pod factory.
  ///
  /// Subclasses can override this method to provide a custom
  /// message source strategy.
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> initMessageSource() async {
    if (podFactory != null && await containsLocalPod(MESSAGE_SOURCE_POD_NAME)) {
      _messageSource = await getPod(MESSAGE_SOURCE_POD_NAME);
    } else {
      final mcl = Class<MessageSource>(null, PackageNames.CORE);
      final del = Class<DelegatingMessageSource>(null, PackageNames.CORE);
      final sources = <MessageSource>[];
      final classes = mcl.getSubClasses().where((cl) => cl.isInvokable());

      for(final cl in classes) {
        final defc = cl.getNoArgConstructor();
        if(defc != null) {
          final source = defc.newInstance();
          sources.add(source);
        } else {
          if(logger.getIsWarnEnabled()) {
            logger.warn("Message ${cl.getName()} does not have a no-arg constructor");
          }
        }
      }

      _messageSource = DelegatingMessageSource(sources);

      await registerSingleton(
        MESSAGE_SOURCE_POD_NAME,
        del,
        object: ObjectHolder<MessageSource>(
          _messageSource!,
          packageName: PackageNames.CORE,
          qualifiedName: del.getQualifiedName()
        )
      );
    }

    return Future.value();
  }

  /// {@template init_application_event_bus}
  /// Initializes the [ApplicationEventBus] for this context.
  ///
  /// This sets up the event publishing system. By default, it creates
  /// a [SimpleApplicationEventBus] and registers it in the pod factory.
  /// Subclasses may override this to supply a custom implementation.
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> initApplicationEventBus() async {
    if (podFactory != null && await containsLocalPod(APPLICATION_EVENT_BUS_POD_NAME)) {
      _applicationEventBus = await getPod<ApplicationEventBus>(APPLICATION_EVENT_BUS_POD_NAME);
    } else {
      final aeb = Class<SimpleApplicationEventBus>(null, PackageNames.CORE);
      _applicationEventBus = SimpleApplicationEventBus(podFactory);

      await registerSingleton(
        APPLICATION_EVENT_BUS_POD_NAME,
        aeb,
        object: ObjectHolder<ApplicationEventBus>(
          _applicationEventBus!,
          packageName: PackageNames.CORE,
          qualifiedName: aeb.getQualifiedName()
        )
      );
    }

    return Future.value();
  }

  /// {@template register_listeners}
  /// Registers all [ApplicationEventListener] pods in the [ConfigurableListablePodFactory].
  ///
  /// This enables Jetleaf components annotated as listeners to receive
  /// published application events automatically.
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> registerListeners() async {
    // Register ApplicationListener pods
    final al = Class<ApplicationEventListener>(null, PackageNames.CORE);

    final names = await getPodNames(al);
    for (final listenerName in names) {
      final listener = await getPod(listenerName);
      _applicationEventBus?.addApplicationListener(listener: listener, podName: listenerName);
    }

    return Future.value();
  }

  /// {@template finish_pod_factory_initialization}
  /// Finalizes the initialization of the [ConfigurableListablePodFactory].
  ///
  /// This step sets up the lifecycle processor and pre-instantiates
  /// all non-lazy singleton pods.
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> finishPodFactoryInitialization() async {
    // Initialize lifecycle processor
    await initLifecycleProcessor();

    // Instantiate all remaining non-lazy-init singletons
    await preInstantiateSingletons();

    return Future.value();
  }

  /// {@template init_lifecycle_processor}
  /// Initializes the [LifecycleProcessor] for this context.
  ///
  /// By default, it registers a [DefaultLifecycleProcessor] in the pod factory.
  /// Subclasses can override to supply a different lifecycle strategy.
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> initLifecycleProcessor() async {
    if (podFactory != null && await containsLocalPod(LIFECYCLE_PROCESSOR_POD_NAME)) {
      _lifecycleProcessor = await getPod(LIFECYCLE_PROCESSOR_POD_NAME);
    } else {
      final dlp = Class<DefaultLifecycleProcessor>(null, PackageNames.CORE);
      _lifecycleProcessor = DefaultLifecycleProcessor(podFactory);

      await registerSingleton(
        LIFECYCLE_PROCESSOR_POD_NAME,
        Class<DefaultLifecycleProcessor>(),
        object: ObjectHolder<LifecycleProcessor>(
          _lifecycleProcessor!,
          packageName: PackageNames.CORE,
          qualifiedName: dlp.getQualifiedName()
        )
      );
    }

    return Future.value();
  }

  /// {@template finish_refresh}
  /// Template method invoked during [refresh] to complete the refresh process.
  ///
  /// Subclasses can override this to perform additional initialization steps
  /// or to publish custom events.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> finishRefresh() async {
  /// logger.info("Custom finish refresh logic here");
  /// }
  /// ```
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  Future<void> finishRefresh() async {
    // Start lifecycle processor
    _lifecycleProcessor?.onRefresh();

    // Publish refresh event
    await publishEvent(ContextRefreshedEvent.withClock(this, () => DateTime.now()));

    if (logger.getIsDebugEnabled()) {
      logger.debug("${runtimeType} application context refreshed successfully.");
    }

    _isRefreshed = true;

    return Future.value();
  }
}