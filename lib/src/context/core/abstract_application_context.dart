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

import '../../aware.dart';
import '../../message/delegating_message_source.dart';
import '../../message/message_source.dart';
import '../base/application_module.dart';
import '../base/helpers.dart';
import '../lifecycle/_lifecycle_processor.dart';
import '../base/application_context.dart';
import '../event/application_event.dart';
import '../event/event_listener.dart';
import '../event/simple_application_event_bus.dart';
import '../lifecycle/application_annotated_lifecycle_processor.dart';
import '../lifecycle/lifecycle_processor.dart';
import '../base/pod_factory_customizer.dart';
import '../processors/default_aware_processor.dart';
import 'pod_post_processor_manager.dart';

/// {@template abstract_application_context}
/// The base implementation of a configurable **Jetleaf Application Context**.
///
/// `AbstractApplicationContext` provides the foundational lifecycle management,
/// environment handling, event bus initialization, and pod factory orchestration
/// that all Jetleaf application contexts build upon.
///
/// ### Key Features:
/// - **Lifecycle Management**: Standardized `setup()`, `start()`, `stop()`, and `close()` lifecycle
/// - **Event System**: Integrated event publishing for context lifecycle events
/// - **Environment Integration**: Property source management and profile handling
/// - **Pod Factory Orchestration**: Complete pod lifecycle from registration to destruction
/// - **Internationalization**: Built-in message source support
/// - **Resource Management**: Proper cleanup and resource disposal
///
/// ### Core Lifecycle Events:
/// - `ContextSetupEvent`: Published when context is successfully setup
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
///     // Register core application pods before setup
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
///   await context.setup(); // Prepares, initializes, and publishes setup event
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
/// - `preparePodFactory()`: Register pods and configure factory before setup
/// - `postProcessPodFactory()`: Apply custom processing after factory setup
///
/// ### Auto-Startup Behavior:
/// By default, `isAutoStartup()` returns `true`, meaning the context will
/// automatically start after setup unless overridden by subclasses.
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
abstract class AbstractApplicationContext implements ConfigurableApplicationContext {
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
  /// is not set in the environment. It follows standard Jetleaf-inspired
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

  /// {@template abstract_application_context.application_timezone_property}
  /// The property key used to configure the application's default timezone.
  ///
  /// This property defines the timezone context for the entire application,
  /// influencing components that rely on time-based operations, such as
  /// caching, scheduling, and logging.
  ///
  /// ### Usage:
  /// ```yaml
  /// application:
  ///   timezone: UTC
  /// ```
  ///
  /// If not explicitly set, the system timezone or a predefined framework
  /// default may be used.
  /// {@endtemplate}
  static final String APPLICATION_TIMEZONE = "application.timezone";

  /// {@template abstract_application_context.lifecycle_processor_pod_name}
  /// The reserved pod name for the [ConversionService] within the Jetleaf context.
  ///
  /// This pod is responsible for managing the conversion of values to and from
  /// different types, such as strings to numbers or objects to JSON.
  ///
  /// ### Responsibilities:
  /// - Converting values to and from different types
  /// - Managing the conversion of values to and from different types
  ///
  /// {@endtemplate}
  static final String CONVERSION_SERVICE_POD_NAME = "conversionService";

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
  /// - **Context Events**: Lifecycle events like setup, start, stop
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

  /// The internal JetLeaf pod name for the global conversion service.
  ///
  /// This constant identifies the registered [ConversionService] instance
  /// within the JetLeaf dependency container. It is primarily used for
  /// resolving type converters and format adapters at runtime.
  ///
  /// Framework components (e.g. validation, data binding, configuration)
  /// rely on this pod name to retrieve the default conversion layer.
  ///
  /// Example:
  /// ```dart
  /// final conversionService = context.getPodByName(JETLEAF_CONVERSION_SERVICE_POD_NAME);
  /// ```
  ///
  /// See also:
  /// - [ConversionService] — the interface defining type conversion behavior.
  /// - [Environment] — for dependency lookups within JetLeaf pods.
  static final String JETLEAF_CONVERSION_SERVICE_POD_NAME = "jetleaf.internal.conversionService";

  /// {@template abstract_application_context.logger_field}
  /// The logger associated with this application context.
  ///
  /// Subclasses should use this logger for all logging activities
  /// related to context lifecycle, configuration, and operations.
  ///
  /// ### Logging Levels:
  /// - `TRACE`: Detailed internal operations
  /// - `DEBUG`: Configuration steps and lifecycle transitions
  /// - `INFO`: Major lifecycle events (setup, start, stop)
  /// - `WARN`: Non-critical issues and deprecations
  /// - `ERROR`: Critical failures and exceptions
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// Future<void> setup() async {
  ///   logger.debug('Starting context setup...');
  ///   try {
  ///     await super.setup();
  ///     logger.info('Context setup successfully');
  ///   } catch (e) {
  ///     logger.error('Context setup failed', error: e);
  ///     rethrow;
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  @protected
  Log get logger => LogFactory.getLog(runtimeType);

  /// {@template abstract_application_context.pod_factory_post_processors_field}
  /// The list of [PodFactoryPostProcessor]s to be applied to the pod factory.
  ///
  /// These processors are invoked during the setup process after the
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

  /// {@template abstract_application_context.application_event_listeners_field}
  /// The list of [ApplicationEventListener]s to be notified of application events.
  ///
  /// These listeners are invoked during the setup process after the
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
  final List<ApplicationEventListener> _applicationEventListeners = [];

  /// {@template abstract_application_context.is_active_field}
  /// Whether the application context is active.
  ///
  /// A context is considered active after successful setup and
  /// remains active until it is closed. Active contexts can serve
  /// pods and handle requests.
  ///
  /// ### State Transitions:
  /// - `false` → `true`: When setup() completes successfully
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
  /// - Once closed, a context cannot be setup or restarted
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
  /// - `setup()`: Sets up context but doesn't start it
  /// - `start()`: Transitions to running state
  /// - `stop()`: Transitions back to non-running state
  /// - `close()`: Always sets running to false
  /// {@endtemplate}
  bool _isRunning = false;

  /// {@template abstract_application_context.is_setup_field}
  /// Whether the application context has been setup.
  ///
  /// This flag indicates that the context has successfully completed
  /// the setup process, which includes pod factory initialization,
  /// pod registration, and post-processing.
  ///
  /// ### Setup Process:
  /// 1. Create fresh pod factory
  /// 2. Register pod definitions
  /// 3. Apply post-processors
  /// 4. Instantiate singleton pods
  /// 5. Publish ContextSetupEvent
  /// {@endtemplate}
  bool _isSetupReady = false;

  /// {@template abstract_application_context.startup_date_field}
  /// The startup date of the application context.
  ///
  /// This timestamp marks when the context was successfully setup
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

  /// {@template abstract_application_context.lifecycle_processor_field}
  /// The lifecycle processor associated with this application context.
  ///
  /// This processor is responsible for managing the complete lifecycle of all pods within the context,
  /// ensuring proper initialization order and cleanup.
  ///
  /// ### Supported Annotations:
  /// - `@OnApplicationStopping`: Called when context is stopping
  /// - `@OnApplicationStopped`: Called when context is fully stopped
  ///
  /// ### Method Requirements:
  /// - Can accept `ApplicationContext` parameter
  /// - Should not throw exceptions (handled gracefully)
  /// {@endtemplate}
  late ApplicationAnnotatedLifecycleProcessor _annotatedLifecycleProcessor;

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
    _conversionService = DefaultConversionService();
    _annotatedLifecycleProcessor = ApplicationAnnotatedLifecycleProcessor(this);
  }

  // ---------------------------------------------------------------------------------------------------------
  // OVERRIDDEN METHODS
  // ---------------------------------------------------------------------------------------------------------

  @override
  bool isAutoStartup() => true; // Auto-start by default

  @override
  bool isRunning() => _isRunning || _isActive;

  @override
  bool isActive() => _isActive;

  @override
  bool isClosed() => _isClosed;

  @override
  String getApplicationName() {
    final jan = getEnvironment().getProperty(JETLEAF_APPLICATION_NAME);
    final an = getEnvironment().getProperty(APPLICATION_NAME);
    final app = _mainApplicationClass?.getName();

    return jan ?? an ?? app ?? "JetLeafApplication";
  }

  @override
  DateTime getStartTime() => _startupDate ?? DateTime.now();

  @override
  Future<void> publishEvent(ApplicationEvent event) async {
    await _applicationEventBus?.onEvent(event);

    final parent = getParent();
    if (parent != null) {
      return await parent.publishEvent(event);
    }

    return Future.value();
  }

  @override
  LifecycleProcessor getLifecycleProcessor() {
    return _lifecycleProcessor ??= DefaultLifecycleProcessor(this);
  }

  @override
  void addPodFactoryPostProcessor(PodFactoryPostProcessor processor) {
    _podFactoryPostProcessors.add(processor);

    try {
      Comparator<Object>? comparator;
      if (getPodFactory() is DefaultListablePodFactory) {
        final comp = (getPodFactory() as DefaultListablePodFactory).getDependencyComparator();
        if (comp != null) {
          comparator = comp;
        }
      }

      comparator ??= OrderComparator.INSTANCE;
      _podFactoryPostProcessors.sort(comparator.compare);
    } catch (_) {}
  }

  /// {@macro abstract_application_context.pod_factory_post_processors_field}
  /// This method returns the list of pod factory post processors registered with this application context.
  ///
  /// ### Usage:
  /// ```dart
  /// final postProcessors = context.getPodFactoryPostProcessors();
  /// ```
  List<PodFactoryPostProcessor> getPodFactoryPostProcessors() => _podFactoryPostProcessors;

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
    if (_applicationEventBus == null) {
      await _applicationEventBus?.addApplicationListener(listener: listener);
    }

    _applicationEventListeners.add(listener);
  }

  @override
  String getMessage(String code, {List<Object>? args, Locale? locale, String? defaultMessage}) {
    if (_messageSource == null) {
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
    if (_messageSource == null) {
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
    if (_applicationEventBus == null) {
      throw IllegalStateException("Cannot access application event bus since it has not been initialized yet.");
    }

    return _applicationEventBus!;
  }

  @override
  ApplicationStartup getApplicationStartup() {
    if (_applicationStartup == null) {
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
    if (_mainApplicationClass == null) {
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
  String getPackageName() => PackageNames.CORE;

  /// {@template abstract_application_context_application_event_listeners_field}
  /// The list of [ApplicationEventListener]s to be notified of application events.
  /// {@endtemplate}
  List<ApplicationEventListener> getApplicationEventListeners() => _applicationEventListeners;

  @override
  FutureOr<void> start() async {
    if (!_isRunning) {
      _isRunning = true;
      await publishEvent(ContextStartedEvent.withClock(this, () => getStartTime()));
      await doStart();
    }

    return Future.value();
  }

  @override
  FutureOr<void> stop([Runnable? callback]) async {
    if (_isRunning) {
      _annotatedLifecycleProcessor.onStopping();

      _isRunning = false;
      await publishEvent(ContextStoppedEvent.withClock(this, () => DateTime.now()));
      await doStop();

      _annotatedLifecycleProcessor.onStopped();
    }

    callback?.run();
    return Future.value();
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      return;
    }

    _isClosed = true;

    try {
      // Stop lifecycle processors
      await getLifecycleProcessor().onClose();

      // Publish close event
      await publishEvent(ContextClosedEvent.withClock(this, () => DateTime.now()));

      // Perform actual cleanup
      await doClose();

      // Destroy singletons
      await destroyPods();

      // Reset common caches
      await resetCommonCaches();

      _applicationEventBus = null;
      _messageSource = null;
      _environment = null;
      _parent = null;
      _podFactoryPostProcessors.clear();
      _applicationEventListeners.clear();

      _lifecycleProcessor = null;
      _applicationStartup = null;
      _mainApplicationClass = null;

      _isActive = false;
      _isRunning = false;
    } catch (e) {
      if (logger.getIsErrorEnabled()) {
        logger.error("Unable to close context due to some issues.", error: e);
      }
    }

    return Future.value();
  }

  @override
  Future<void> setup() async {
    // Start setup step
    StartupStep step = getApplicationStartup().start("context.setup");

    // Prepare this context for setup.
    await prepareSetup();

    // Tell the subclass to setup the internal pod factory.
    final podFactory = await doGetFreshPodFactory();

    // Prepare the pod factory for use in this context.
    await preparePodFactory(podFactory);

    try {
      // Allows post-processing of the pod factory in context subclasses.
      await postProcessPodFactory(podFactory);

      /// Finds all registered [PodFactoryCustomizer] implementations and
      /// invokes them to customize the provided [PodFactory] instance
      /// before the container is setup.
      await findAllPodFactoryCustomizersAndApplicationModulesCustomize(podFactory);

      // Start post process step
      StartupStep postProcess = getApplicationStartup().start("context.pods.post-process");

      // Invoke factory processors registered as pods in the context.
      await invokePodFactoryPostProcessors(podFactory);

      // Register pod processors that intercept pod creation.
      await registerPodProcessors(podFactory);

      postProcess.end();

      // Initialize message source for this context.
      await initializeMessageSource();

      // Initialize event multicaster for this context.
      await initializeApplicationEventBus();

      // Initialize other special pods in specific context subclasses.
      await doSetup(podFactory);

      // Setup the pod expression resolver for this context.
      await findPodExpressionResolver();

      // Check for listener pods and register them.
      await registerListeners();

      // Instantiate all remaining (non-lazy-init) singletons.
      await completePodFactoryInitialization(podFactory);

      // Last step: publish corresponding event.
      await finishSetup(podFactory);
    } catch (ex, st) {
      if (logger.getIsErrorEnabled()) {
        logger.error(
          "Failed to initialize application context '${getDisplayName()}': ${ex.runtimeType}. Aborting setup operation.",
          error: ex,
          stacktrace: st
        );
      }

      // Destroy already created singletons to avoid dangling resources.
      await destroyPods();

      // Reset 'active' flag.
      await cancelSetup(ex);

      // Propagate exception to caller.
      rethrow;
    } finally {
      step.end();
    }

    return Future.value();
  }

  // ---------------------------------------------------------------------------------------------------------
  // PROTECTED METHODS
  // ---------------------------------------------------------------------------------------------------------

  /// {@template abstract_application_context_is_setup}
  /// Returns true if the application context has been setup.
  /// {@endtemplate}
  @protected
  bool getIsSetupReady() => _isSetupReady;

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
  @mustCallSuper
  Future<void> doStart() async => Future.value();

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
  @mustCallSuper
  Future<void> doStop() async => Future.value();

  /// {@template abstract_application_context_do_close}
  /// Template method for actual cleanup logic when the context is closed.
  ///
  /// Subclasses can override this to perform specific cleanup tasks such as
  /// releasing caches, closing thread pools, or persisting final state.
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> doClose() async {}

  /// {@template prepare_refresh}
  /// Prepares the application context for a setup.
  ///
  /// This method resets lifecycle flags, records the startup timestamp,
  /// and logs that the context is being setup. It is invoked internally
  /// before creating a fresh pod factory.
  ///
  /// Subclasses may override this to perform custom pre-setup logic,
  /// such as resetting caches or preparing configuration sources.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> prepareRefresh() async {
  /// await super.prepareRefresh();
  /// logger.info("Preparing additional setup state");
  /// }
  /// ```
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> prepareSetup() async {
    _startupDate = DateTime.now();
    _isClosed = false;
    _isActive = true;

    if (logger.getIsInfoEnabled()) {
      logger.info("Starting setup of ${getDisplayName()} application context...");
    }

    final env = getEnvironment();
    if (env is ConfigurableEnvironment) {
      env.validateRequiredProperties();
    }

    return Future.value();
  }

  /// {@template do_get_fresh_pod_factory}
  /// Returns a fresh [ConfigurableListablePodFactory] for this context.
  ///
  /// Subclasses must implement this to provide a new factory instance
  /// whenever the context is setup.
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
  Future<ConfigurableListablePodFactory> doGetFreshPodFactory() async {
    await refreshPodFactory();
    return getPodFactory();
  }

  @protected
  @mustCallSuper
  Future<void> refreshPodFactory() async => Future.value();

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
  @mustCallSuper
  Future<void> preparePodFactory(ConfigurableListablePodFactory podFactory) async {
    podFactory.addPodProcessor(DefaultAwareProcessor(this));

    if (podFactory is AbstractAutowirePodFactory) {
      final aapf = podFactory as AbstractAutowirePodFactory;

      aapf.ignoreDependencyInterface(Class<EnvironmentAware>(null, PackageNames.CORE));
      aapf.ignoreDependencyInterface(Class<EntryApplicationAware>(null, PackageNames.CORE));
      aapf.ignoreDependencyInterface(Class<PodNameAware>(null, PackageNames.CORE));
      aapf.ignoreDependencyInterface(Class<MessageSourceAware>(null, PackageNames.CORE));
      aapf.ignoreDependencyInterface(Class<ConversionServiceAware>(null, PackageNames.CORE));
      aapf.ignoreDependencyInterface(Class<ApplicationContextAware>(null, PackageNames.CORE));
      aapf.ignoreDependencyInterface(Class<ApplicationStartupAware>(null, PackageNames.CORE));
      aapf.ignoreDependencyInterface(Class<ApplicationEventBusAware>(null, PackageNames.CORE));
    }

    podFactory.registerResolvableDependency(Class<PodFactory>(null, PackageNames.POD));
    podFactory.registerResolvableDependency(Class<ApplicationEventBus>(null, PackageNames.CORE));
    podFactory.registerResolvableDependency(Class<ApplicationContext>(null, PackageNames.CORE));

    return Future.value();
  }

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
  @mustCallSuper
  Future<void> postProcessPodFactory(ConfigurableListablePodFactory podFactory) async => Future.value();

  /// Finds all registered [PodFactoryCustomizer] and [ApplicationModule] implementations and
  /// invokes them to customize the provided [PodFactory] instance
  /// before the container is setup.
  ///
  /// This method is typically called during the pre-setup phase of the
  /// application startup lifecycle, giving each customizer a chance to
  /// modify the factory — for example, by registering additional pods,
  /// setting configuration properties, or altering existing definitions.
  ///
  /// Implementations of [PodFactoryCustomizer] are usually discovered
  /// through the application context or dependency-injection container.
  ///
  /// Example:
  /// ```dart
  /// // During context initialization:
  /// await findAllPodFactoryCustomizersAndApplicationModulesCustomize(podFactory);
  /// ```
  ///
  /// * [podFactory] — the [PodFactory] instance to customize before setup.
  /// * Throws [Exception] if any customizer invocation fails.
  @protected
  @mustCallSuper
  Future<void> findAllPodFactoryCustomizersAndApplicationModulesCustomize(ConfigurableListablePodFactory podFactory) async {
    final type = Class<PodFactoryCustomizer>(null, PackageNames.CORE);
    final subClasses = type.getSubClasses();

    for (final subClass in subClasses) {
      // We have to skip proxy classes since they are not necessary in this scope.
      if (ClassUtils.isProxyClass(subClass)) {
        continue;
      }

      final constructor = subClass.getNoArgConstructor();
      if (constructor != null) {
        try {
          final instance = constructor.newInstance();
          if (instance is PodFactoryCustomizer) {
            await instance.customize(podFactory);
          }
        } catch (_) {
          if (logger.getIsWarnEnabled()) {
            logger.warn("Unable to instantiate the class of ${subClass.getQualifiedName()}, no no-arg constructor found");
          }
        }
      }
    }

    final am = Class<ApplicationModule>(null, PackageNames.CORE);
    final amSubClasses = am.getSubClasses();

    for (final subClass in amSubClasses) {
      // We have to skip proxy classes since they are not necessary in this scope.
      if (ClassUtils.isProxyClass(subClass)) {
        continue;
      }

      final constructor = subClass.getNoArgConstructor();
      if (constructor != null) {
        try {
          final instance = constructor.newInstance();
          if (instance is ApplicationModule) {
            await instance.configure(this);
          }
        } catch (_) {
          if (logger.getIsWarnEnabled()) {
            logger.warn("Unable to instantiate the class of ${subClass.getQualifiedName()}, no no-arg constructor found");
          }
        }
      }
    }
  }

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
  @mustCallSuper
  Future<void> invokePodFactoryPostProcessors(ConfigurableListablePodFactory podFactory) async => PodPostProcessorManager(podFactory).invokePodFactoryPostProcessor(getPodFactoryPostProcessors());

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
  @mustCallSuper
  Future<void> registerPodProcessors(ConfigurableListablePodFactory podFactory) async => PodPostProcessorManager(podFactory).registerPodProcessors();

  /// Performs any extra processing before the [podFactory] is finalized.
  ///
  /// This method is called during the setup phase of the application context,
  /// allowing subclasses to perform additional initialization or setup tasks
  /// before the `ConfigurableListablePodFactory` becomes fully available.
  ///
  /// ### Annotations
  /// - `@protected` — intended for use within this class or subclasses only.
  /// - `@mustCallSuper` — overriding implementations **must** call `super.doRefresh`.
  ///
  /// ### Parameters
  /// - [podFactory]: The pod factory being finalized, which can be inspected or modified.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// @mustCallSuper
  /// Future<void> doRefresh(ConfigurableListablePodFactory podFactory) async {
  ///   // Custom initialization logic
  ///   await super.doRefresh(podFactory);
  /// }
  /// ```
  @protected
  @mustCallSuper
  Future<void> doSetup(ConfigurableListablePodFactory podFactory) async => Future.value();

  /// {@template destroy_pods}
  /// Destroys all managed pods in the given
  /// [ConfigurableListablePodFactory].
  ///
  /// Called during shutdown or setup cancellation to ensure
  /// graceful resource cleanup. This includes invoking
  /// registered destroy methods and releasing references.
  ///
  /// Subclasses can extend this for additional teardown steps.
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> destroyPods() async {
    final pf = getPodFactory();
    pf.destroySingletons();

    return Future.value();
  }

  /// {@template cancel_refresh}
  /// Cancels the setup process due to the provided [PodException].
  ///
  /// This method allows subclasses to roll back partially
  /// initialized state, release resources, and log or propagate
  /// errors consistently.
  ///
  /// Called whenever initialization fails in the middle of a
  /// setup cycle.
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> cancelSetup(Object exception) async {
    _isActive = false;
    return await resetCommonCaches();
  }

  /// {@template reset_common_caches}
  /// Resets common internal caches maintained by the container.
  ///
  /// This includes metadata caches, reflection results, and
  /// pod definition lookups that may persist across setup cycles.
  ///
  /// Subclasses may override this to clear any additional
  /// framework-level caches.
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> resetCommonCaches() async {
    clearMetadataCache();
    clearSingletonCache();

    return Future.value();
  }

  /// {@template init_message_source}
  /// Initializes the [MessageSource] for this context.
  ///
  /// This is invoked during setup to set up i18n message resolution.
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
  @mustCallSuper
  Future<void> initializeMessageSource() async {
    final factory = getPodFactory();

    if (await factory.containsLocalPod(MESSAGE_SOURCE_POD_NAME)) {
      _messageSource = await factory.getPod(MESSAGE_SOURCE_POD_NAME);

      if (logger.getIsTraceEnabled()) {
        logger.trace("Using message source ${_messageSource!.runtimeType}");
      }
    } else {
      final mcl = Class<MessageSource>(null, PackageNames.CORE);
      final del = Class<DelegatingMessageSource>(null, PackageNames.CORE);
      final sources = <MessageSource>[];
      final classes = mcl.getSubClasses().where((cl) => cl.isInvokable());

      for (final cl in classes) {
        final defc = cl.getNoArgConstructor() ?? cl.getBestConstructor([]) ?? cl.getDefaultConstructor();
        if (defc != null) {
          final source = defc.newInstance();
          sources.add(source);
        } else {
          if (logger.getIsWarnEnabled()) {
            logger.warn("Message ${cl.getName()} does not have a no-arg constructor");
          }
        }
      }

      _messageSource = DelegatingMessageSource(sources);

      await factory.registerSingleton(
        MESSAGE_SOURCE_POD_NAME,
        del,
        object: ObjectHolder<MessageSource>(
          _messageSource!,
          packageName: PackageNames.CORE,
          qualifiedName: del.getQualifiedName(),
        ),
      );

      if (logger.getIsTraceEnabled()) {
        logger.trace("No message source found, using default message source ${_messageSource!.runtimeType}");
      }
    }

    return Future.value();
  }

  /// {@template configurable_pod_factory.find_pod_expression_resolver}
  /// Locates and registers a [PodExpressionResolver] within the current
  /// [PodFactory] context.
  ///
  /// This method searches the configured [PodFactory] for an available
  /// [PodExpressionResolver] of type `Class<PodExpressionResolver>` in
  /// the **POD** package.  
  /// If a resolver is found, it is automatically retrieved and registered
  /// via [setPodExpressionResolver].
  ///
  /// ### Behavior
  /// - Performs a type-based lookup using [factory.containsType].
  /// - Lazily initializes and stores the resolver if present.
  /// - Safe to call multiple times — subsequent calls will overwrite
  ///   any previously registered resolver.
  ///
  /// ### Example
  /// ```dart
  /// await configurableFactory.findPodExpressionResolver();
  ///
  /// final resolver = configurableFactory.getPodExpressionResolver();
  /// final context = resolver.createContext();
  /// ```
  ///
  /// This mechanism ensures that expression evaluation within pod
  /// definitions (e.g., `@Value` or `@Conditional`) is properly resolved
  /// at runtime.
  /// {@endtemplate}
  @protected
  Future<void> findPodExpressionResolver() async {
    final factory = getPodFactory();
    final type = Class<PodExpressionResolver>(null, PackageNames.POD);

    if (await factory.containsType(type) && factory.getPodExpressionResolver() == null) {
      final resolver = await factory.get<PodExpressionResolver>(type);
      setPodExpressionResolver(resolver);
    }
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
  @mustCallSuper
  Future<void> initializeApplicationEventBus() async {
    final factory = getPodFactory();

    if (await factory.containsLocalPod(APPLICATION_EVENT_BUS_POD_NAME)) {
      _applicationEventBus = await factory.getPod<ApplicationEventBus>(APPLICATION_EVENT_BUS_POD_NAME);

      if (logger.getIsTraceEnabled()) {
        logger.trace("Using application event bus ${_applicationEventBus!.runtimeType}");
      }
    } else {
      final aeb = Class<SimpleApplicationEventBus>(null, PackageNames.CORE);
      _applicationEventBus = SimpleApplicationEventBus(factory);

      await factory.registerSingleton(
        APPLICATION_EVENT_BUS_POD_NAME,
        aeb,
        object: ObjectHolder<ApplicationEventBus>(
          _applicationEventBus!,
          packageName: PackageNames.CORE,
          qualifiedName: aeb.getQualifiedName(),
        ),
      );

      if (logger.getIsTraceEnabled()) {
        logger.trace("No application event bus found, using default application event bus ${_applicationEventBus!.runtimeType}");
      }
    }

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
  @mustCallSuper
  Future<void> initializeLifecycleProcessor(ConfigurableListablePodFactory podFactory) async {
    if (await podFactory.containsLocalPod(LIFECYCLE_PROCESSOR_POD_NAME)) {
      _lifecycleProcessor = await podFactory.getPod<LifecycleProcessor>(LIFECYCLE_PROCESSOR_POD_NAME);

      if (logger.getIsTraceEnabled()) {
        logger.trace("Using lifecycle processor ${_lifecycleProcessor!.runtimeType}");
      }
    } else {
      final dlp = Class<DefaultLifecycleProcessor>(null, PackageNames.CORE);
      final defaultLp = DefaultLifecycleProcessor(podFactory);
      _lifecycleProcessor = defaultLp;

      await podFactory.registerSingleton(
        LIFECYCLE_PROCESSOR_POD_NAME,
        Class<DefaultLifecycleProcessor>(),
        object: ObjectHolder<LifecycleProcessor>(
          defaultLp,
          packageName: PackageNames.CORE,
          qualifiedName: dlp.getQualifiedName(),
        ),
      );

      if (logger.getIsTraceEnabled()) {
        logger.trace("No lifecycle processor found, using default lifecycle processor ${_lifecycleProcessor!.runtimeType}");
      }
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
  @mustCallSuper
  Future<void> registerListeners() async {
    final eventBus = getApplicationEventBus();

    for (final listener in getApplicationEventListeners()) {
      eventBus.addApplicationListener(listener: listener);
    }

    // Register ApplicationListener pods
    final al = Class<ApplicationEventListener>(null, PackageNames.CORE);
    final names = await getPodNames(al, includeNonSingletons: true);

    for (final name in names) {
      final listener = await getPod(name, null, al);
      eventBus.addApplicationListener(listener: listener, podName: name);
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
  @mustCallSuper
  Future<void> completePodFactoryInitialization(ConfigurableListablePodFactory podFactory) async {
    // Initialize ConversionService
    final cc = Class<ConversionService>(null, PackageNames.CONVERT);
    if (await podFactory.containsPod(CONVERSION_SERVICE_POD_NAME) && await podFactory.containsType(cc)) {
      podFactory.setConversionService(await podFactory.getPod(CONVERSION_SERVICE_POD_NAME, null, cc));
    }

    // Freeze configuration
    if (podFactory is DefaultListablePodFactory) {
      podFactory.freezeConfiguration();
    }

    // Instantiate all remaining non-lazy-init singletons
    await preInstantiateSingletons();
    await _annotatedLifecycleProcessor.onSingletonReady();

    // Publish completed initialization event
    await publishEvent(CompletedInitializationEvent.withClock(this, () => DateTime.now()));

    return Future.value();
  }

  /// {@template finish_refresh}
  /// Template method invoked during [setup] to complete the setup process.
  ///
  /// Subclasses can override this to perform additional initialization steps
  /// or to publish custom events.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> finishRefresh() async {
  /// logger.info("Custom finish setup logic here");
  /// }
  /// ```
  ///
  /// *This is part of Jetleaf – a framework which developers can use to build web applications.*
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> finishSetup(ConfigurableListablePodFactory podFactory) async {
    await resetCommonCaches();

    // Initialize lifecycle processor
    await initializeLifecycleProcessor(podFactory);

    // Start lifecycle processor
    await getLifecycleProcessor().onRefresh();

    // Publish setup event
    await publishEvent(ContextSetupEvent.withClock(this, () => DateTime.now()));

    if (logger.getIsDebugEnabled()) {
      logger.debug("${getDisplayName()}: $runtimeType application context setup successfully.");
    }

    _isSetupReady = true;
    await publishEvent(ContextReadyEvent.withClock(this, () => DateTime.now()));

    // Publish ready event
    return Future.value();
  }

  /// {@template jet_pod_factory_assert_active}
  /// Ensures that the current JetLeaf Pod Factory is in an active state before
  /// performing any operation that depends on an initialized or setup
  /// application context.
  ///
  /// This safeguard method validates the internal lifecycle state of the
  /// `PodFactory` by checking two key conditions:
  ///
  /// 1. **Closed State** — If the factory has already been shut down
  ///    (indicated by `_isClosed`), an [IllegalStateException] is thrown with
  ///    a message indicating that the factory has been closed and cannot be
  ///    accessed further.
  ///
  /// 2. **Inactive State** — If the factory has not yet been activated or
  ///    setup (i.e., `_isActive` is `false` but `_isClosed` is also
  ///    `false`), it indicates that the Pod container has not completed its
  ///    bootstrap or dependency registration phase. In this case, an
  ///    [IllegalStateException] is thrown to prevent premature access to
  ///    pods or configuration objects.
  ///
  /// This check is invoked internally by lifecycle-sensitive methods such as
  /// `getPod()`, `createPod()`, or other dependency resolution logic within
  /// JetLeaf’s container infrastructure.
  ///
  /// ### Example
  /// ```dart
  /// void initializePod() {
  ///   _assertThatPodFactoryIsActive();
  ///   final myService = getPod<MyService>();
  ///   myService.initialize();
  /// }
  /// ```
  ///
  /// In the example above, the `_assertThatPodFactoryIsActive()` call ensures
  /// that the container has been setup before any `Pod` retrieval occurs.
  ///
  /// ### Throws
  /// - [IllegalStateException] — If the factory is closed or not yet active.
  ///
  /// ### See also
  /// - [IllegalStateException]
  /// - [getDisplayName] — Used to display a readable context name in the
  ///   exception message.
  /// {@endtemplate}
  void _assertThatPodFactoryIsActive() {
    if (!_isActive) {
      if (_isClosed) {
        throw IllegalStateException('${getDisplayName()} has been closed');
      }

      throw IllegalStateException('${getDisplayName()} has not been setup yet');
    }
  }

  // ------------------------------------------------------------------------------------------------------
  // POD FACTORY METHODS
  // ------------------------------------------------------------------------------------------------------

  @override
  Future<T> get<T>(Class<T> type, [List<ArgumentValue>? args]) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().get(type, args);
  }

  @override
  Future<bool> isSingleton(String podName) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().isSingleton(podName);
  }

  @override
  Future<bool> isPrototype(String podName) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().isPrototype(podName);
  }

  @override
  bool getAllowCircularReferences() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getAllowCircularReferences();
  }

  @override
  bool getAllowDefinitionOverriding() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getAllowDefinitionOverriding();
  }

  @override
  bool getAllowRawInjection() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getAllowRawInjection();
  }

  @override
  Future<ObjectProvider<T>> getProvider<T>(Class<T> type, {String? podName, bool allowEagerInit = false}) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getProvider(type, podName: podName, allowEagerInit: allowEagerInit);
  }

  @override
  Future<Class> getPodClass(String podName) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getPodClass(podName);
  }

  @override
  Future<T> getPod<T>(String podName, [List<ArgumentValue>? args, Class<T>? type]) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getPod<T>(podName, args, type);
  }

  @override
  Future<Object> getObject(Class<Object> type, [List<ArgumentValue>? args]) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getObject(type, args);
  }

  @override
  Future<Object> getNamedObject(String podName, [List<ArgumentValue>? args]) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getNamedObject(podName, args);
  }

  @override
  Future<Object?> resolveDependency(DependencyDescriptor descriptor, [Set<String>? candidates]) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().resolveDependency(descriptor, candidates);
  }

  @override
  void addSingletonCallback(String name, Class type, Consumer<Object> callback) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().addSingletonCallback(name, type, callback);
  }

  @override
  void addPodProcessor(PodProcessor processor) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().addPodProcessor(processor);
  }

  @override
  void clearMetadataCache() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().clearMetadataCache();
  }

  @override
  void clearSingletonCache() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().clearSingletonCache();
  }

  @override
  bool containsSingleton(String name) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().containsSingleton(name);
  }

  @override
  void copyConfigurationFrom(ConfigurablePodFactory otherFactory) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().copyConfigurationFrom(otherFactory);
  }

  @override
  Future<void> destroyPod(String podName, Object podInstance) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().destroyPod(podName, podInstance);
  }

  @override
  void destroyScopedPod(String podName) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().destroyScopedPod(podName);
  }

  @override
  void destroySingletons() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().destroySingletons();
  }

  @override
  Future<Set<A>> findAllAnnotationsOnPod<A>(String podName, Class<A> type) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().findAllAnnotationsOnPod(podName, type);
  }

  @override
  Future<A?> findAnnotationOnPod<A>(String podName, Class<A> type) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().findAnnotationOnPod(podName, type);
  }

  @override
  RootPodDefinition getMergedPodDefinition(String podName) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getMergedPodDefinition(podName);
  }

  @override
  PodFactory? getParentFactory() => _parent?.getPodFactory();

  @override
  int getPodProcessorCount() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getPodProcessorCount();
  }

  @override
  List<PodProcessor> getPodProcessors() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getPodProcessors();
  }

  @override
  PodExpressionResolver? getPodExpressionResolver() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getPodExpressionResolver();
  }

  @override
  Future<List<String>> getPodNames(Class type, {bool includeNonSingletons = false, bool allowEagerInit = false}) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getPodNames(type, includeNonSingletons: includeNonSingletons, allowEagerInit: allowEagerInit);
  }

  @override
  Future<List<String>> getPodNamesForAnnotation<A>(Class<A> type) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getPodNamesForAnnotation(type);
  }

  @override
  Iterator<String> getPodNamesIterator() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getPodNamesIterator();
  }

  @override
  Future<Map<String, T>> getPodsOf<T>(Class<T> type, {bool includeNonSingletons = false, bool allowEagerInit = false}) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getPodsOf(type, includeNonSingletons: includeNonSingletons, allowEagerInit: allowEagerInit);
  }

  @override
  Future<Map<String, Object>> getPodsWithAnnotation<A>(Class<A> type) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getPodsWithAnnotation(type);
  }

  @override
  PodScope? getRegisteredScope(String scopeName) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getRegisteredScope(scopeName);
  }

  @override
  List<String> getRegisteredScopeNames() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getRegisteredScopeNames();
  }

  @override
  Future<Object?> getSingleton(String name, {bool allowEarlyReference = true, ObjectFactory<Object>? factory}) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().getSingleton(name, allowEarlyReference: allowEarlyReference, factory: factory);
  }

  @override
  int getSingletonCount() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getSingletonCount();
  }

  @override
  List<String> getSingletonNames() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().getSingletonNames();
  }

  @override
  bool isAutowireCandidate(String podName, DependencyDescriptor descriptor) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().isAutowireCandidate(podName, descriptor);
  }

  @override
  bool isCachePodMetadata() {
    _assertThatPodFactoryIsActive();

    return getPodFactory().isCachePodMetadata();
  }

  @override
  bool isActuallyInCreation(String podName) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().isActuallyInCreation(podName);
  }

  @override
  Future<bool> containsType(Class type, [bool allowPodProviderInit = false]) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().containsType(type, allowPodProviderInit);
  }

  @override
  Future<bool> isTypeMatch(String name, Class typeToMatch, [bool allowPodProviderInit = false]) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().isTypeMatch(name, typeToMatch, allowPodProviderInit);
  }

  @override
  Future<bool> isPodProvider(String podName, [RootPodDefinition? rpd]) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().isPodProvider(podName, rpd);
  }

  @override
  Future<void> preInstantiateSingletons() async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().preInstantiateSingletons();
  }

  @override
  void registerIgnoredDependency(Class type) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().registerIgnoredDependency(type);
  }

  @override
  void registerResolvableDependency(Class type, [Object? autowiredValue]) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().registerResolvableDependency(type, autowiredValue);
  }

  @override
  void registerScope(String scopeName, PodScope scope) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().registerScope(scopeName, scope);
  }

  @override
  Future<void> registerSingleton(String name, Class type, {ObjectHolder<Object>? object, ObjectFactory<Object>? factory}) async {
    _assertThatPodFactoryIsActive();

    return await getPodFactory().registerSingleton(name, type, object: object, factory: factory);
  }

  @override
  void removeSingleton(String name) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().removeSingleton(name);
  }

  @override
  void setCachePodMetadata(bool cachePodMetadata) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().setCachePodMetadata(cachePodMetadata);
  }

  @override
  void setParentFactory(PodFactory? parentFactory) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().setParentFactory(parentFactory);
  }

  @override
  void setPodExpressionResolver(PodExpressionResolver? valueResolver) {
    _assertThatPodFactoryIsActive();

    return getPodFactory().setPodExpressionResolver(valueResolver);
  }
}