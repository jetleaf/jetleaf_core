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

import '../../aware.dart';
import 'helpers.dart';
import '../lifecycle/lifecycle.dart';
import '../../message/message_source.dart';
import 'application_type.dart';
import '../event/event_listener.dart';
import '../event/application_event.dart';
import '../lifecycle/lifecycle_processor.dart';
import 'pod_registrar.dart';

/// {@template application_context}
/// The central interface for a JetLeaf application context.
///
/// An [ApplicationContext] is the core container that provides:
/// - **Dependency Injection**: Access to managed pods via [ListablePodFactory] and [HierarchicalPodFactory]
/// - **Environment Management**: Configuration and profile handling via [EnvironmentCapable]
/// - **Internationalization**: Message resolution and localization via [MessageSource]
/// - **Event System**: Application-wide event publication through [publishEvent]
/// - **Lifecycle Management**: Context state tracking and lifecycle operations
///
/// This interface serves as the primary entry point for configuring, bootstrapping,
/// and interacting with a JetLeaf application at runtime.
///
/// ### Core Responsibilities:
/// - **Container Management**: Hosts and manages the complete dependency injection container
/// - **Configuration Centralization**: Provides unified access to application configuration
/// - **Lifecycle Coordination**: Manages context lifecycle from startup to shutdown
/// - **Event Distribution**: Facilitates loose coupling through event-driven architecture
/// - **Resource Access**: Provides access to framework and application resources
///
/// ### Basic Usage Example:
/// ```dart
/// void main() async {
///   // Create and configure application context
///   final context = MyApplicationContext();
///   
///   // Initialize the context (loads pods, processes configurations)
///   await context.refresh();
///
///   // Publish application startup event
///   context.publishEvent(ApplicationStartedEvent(context));
///
///   // Access context information
///   print("Application '${context.getApplicationName()}' started at: ${context.getStartTime()}");
///   print("Context ID: ${context.getId()}");
///   
///   // Use the context throughout application lifetime
///   final userService = context.getPod<UserService>();
///   await userService.initialize();
///   
///   // Properly close context on shutdown
///   await context.close();
/// }
/// ```
///
/// ### Context Hierarchy:
/// Application contexts can form parent-child relationships where child contexts
/// inherit configuration and can delegate pod lookups to their parents. This enables:
/// - **Modular Applications**: Separate contexts for different application modules
/// - **Testing Scenarios**: Isolated test contexts with shared parent services
/// - **Multi-tenant Systems**: Tenant-specific contexts with common infrastructure
///
/// ### Thread Safety:
/// Implementations should be thread-safe for concurrent access, particularly
/// for read operations like pod retrieval and configuration access. Lifecycle
/// operations (refresh, start, stop, close) should be properly synchronized.
///
/// See also:
/// - [ConfigurableApplicationContext] for lifecycle management and configuration
/// - [Environment] for environment and property management
/// - [MessageSource] for internationalization support
/// - [ApplicationEvent] for event system integration
/// {@endtemplate}
abstract class ApplicationContext implements EnvironmentAware, MessageSource, PodRegistry, ConfigurableListablePodFactory {
  /// {@template application_context_get_id}
  /// Returns a unique identifier for this application context.
  ///
  /// The identifier serves multiple purposes:
  /// - **Logging and Monitoring**: Distinguish between multiple contexts in logs
  /// - **JMX and Management**: Identify context in management systems
  /// - **Debugging**: Correlate context instances during development
  /// - **Serialization**: Provide context identity in distributed scenarios
  ///
  /// ### Identifier Characteristics:
  /// - Typically assigned during context creation
  /// - Should be unique within the same DVM/process
  /// - Usually includes context type and sequence information
  /// - Can be used in parent-child context relationships
  ///
  /// ### Example:
  /// ```dart
  /// final contextId = applicationContext.getId();
  /// print("Operating context: $contextId");
  /// logger.info("Context $contextId initialized successfully");
  /// 
  /// // Typical ID formats:
  /// // "AnnotationConfigApplicationContext-1"
  /// // "GenericApplicationContext-main"
  /// // "WebApplicationContext-dispatcher"
  /// ```
  /// {@endtemplate}
  String getId();
  
  /// {@template application_context_publish_event}
  /// Publishes the given [event] to all registered [ApplicationEventListener]s.
  ///
  /// This method implements the **Observer pattern** within the application context,
  /// allowing decoupled communication between application components.
  ///
  /// ### Event Delivery Guarantees:
  /// - **Synchronous Delivery**: Events are typically delivered synchronously
  /// - **Order Preservation**: Events are delivered in publication order
  /// - **Exception Handling**: Listener exceptions are caught and logged
  /// - **Thread Context**: Events are published in the caller's thread context
  ///
  /// ### Event Types:
  /// - **Context Lifecycle Events**: `ContextRefreshedEvent`, `ContextClosedEvent`
  /// - **Application Domain Events**: `UserCreatedEvent`, `OrderProcessedEvent`
  /// - **Framework Events**: Internal framework operation events
  ///
  /// ### Example:
  /// ```dart
  /// class OrderService {
  ///   final ApplicationContext context;
  ///   
  ///   OrderService(this.context);
  ///   
  ///   Future<Order> createOrder(OrderRequest request) async {
  ///     final order = Order.fromRequest(request);
  ///     
  ///     // Persist order
  ///     await orderRepository.save(order);
  ///     
  ///     // Publish domain event
  ///     context.publishEvent(OrderCreatedEvent(this, order));
  ///     
  ///     return order;
  ///   }
  /// }
  /// 
  /// class OrderEventListener implements ApplicationEventListener<OrderCreatedEvent> {
  ///   @override
  ///   void onApplicationEvent(OrderCreatedEvent event) {
  ///     // Send confirmation email
  ///     emailService.sendConfirmation(event.order);
  ///     
  ///     // Update inventory
  ///     inventoryService.reserveItems(event.order.items);
  ///   }
  /// }
  /// ```
  ///
  /// ### Error Handling:
  /// If a listener throws an exception, it is caught and logged, but other
  /// listeners will still receive the event. The publishing code is not
  /// affected by listener exceptions.
  /// {@endtemplate}
  Future<void> publishEvent(ApplicationEvent event);

  /// {@template application_context_is_active}
  /// Returns whether this application context is currently active.
  ///
  /// An active context has been successfully refreshed and is fully operational.
  /// This is the normal running state of a context between refresh and close.
  ///
  /// ### State Transitions:
  /// - **false → true**: When `refresh()` completes successfully
  /// - **true → false**: When `close()` is called
  /// - **Irreversible**: Once false, cannot become true again
  ///
  /// ### Usage:
  /// ```dart
  /// if (context.isActive()) {
  ///   // Safe to use context and retrieve pods
  ///   final service = context.getPod<MyService>();
  ///   service.doSomething();
  /// } else {
  ///   throw StateError('Context is not active');
  /// }
  /// ```
  /// {@endtemplate}
  bool isActive();

  /// {@template application_context_is_closed}
  /// Returns whether this application context has been closed.
  ///
  /// A closed context has completed its lifecycle and released all resources.
  /// Attempting to use a closed context will typically result in exceptions.
  ///
  /// ### Closed Context Behavior:
  /// - **Pod Access**: `IllegalStateException` when retrieving pods
  /// - **Event Publishing**: Events may be ignored or cause exceptions
  /// - **Configuration Access**: Environment and configuration may be unavailable
  /// - **Resource State**: Database connections, thread pools, etc. are closed
  ///
  /// ### Lifecycle:
  /// ```dart
  /// final context = MyApplicationContext();
  /// print(context.isClosed()); // false
  /// 
  /// await context.refresh();
  /// print(context.isClosed()); // false
  /// 
  /// await context.close();
  /// print(context.isClosed()); // true
  /// ```
  /// {@endtemplate}
  bool isClosed();

  /// {@template application_context_start_time}
  /// Returns the startup time of this context as a [DateTime].
  ///
  /// The startup time represents when the context transitioned to active state
  /// after successful refresh. This is useful for:
  ///
  /// ### Use Cases:
  /// - **Uptime Monitoring**: Calculate how long the context has been running
  /// - **Performance Analysis**: Measure initialization time and track over restarts
  /// - **Logging and Auditing**: Correlate events with context lifetime
  /// - **Scheduling**: Schedule tasks relative to context startup
  ///
  /// ### Example:
  /// ```dart
  /// final startTime = context.getStartTime();
  /// final uptime = DateTime.now().difference(startTime);
  /// 
  /// print('Context started: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime)}');
  /// print('Uptime: ${uptime.inHours}h ${uptime.inMinutes.remainder(60)}m');
  /// 
  /// // Use in monitoring
  /// if (uptime.inDays > 30) {
  ///   logger.warn('Context has been running for over 30 days');
  /// }
  /// ```
  /// {@endtemplate}
  DateTime getStartTime();

  /// {@template application_context_name}
  /// Returns the name of this application.
  ///
  /// The application name is typically derived from:
  /// - Explicit configuration via `application.name` property
  /// - Main application class name
  /// - Framework default naming
  /// - Deployment environment configuration
  ///
  /// ### Usage:
  /// ```dart
  /// final appName = context.getApplicationName();
  /// 
  /// // Use in logging
  /// logger.info('Application $appName starting up');
  /// 
  /// // Use in monitoring
  /// metrics.gauge('app.name', appName);
  /// 
  /// // Use in UI or API responses
  /// return {
  ///   'app': appName,
  ///   'version': '1.0.0',
  ///   'status': 'running'
  /// };
  /// ```
  /// {@endtemplate}
  String getApplicationName();

  /// {@template application_context_display_name}
  /// Returns the display name of this application context.
  ///
  /// The display name is typically more descriptive than the application name
  /// and may include additional context information like:
  /// - Context type and role
  /// - Module or component information
  /// - Environment-specific identifiers
  /// - Instance sequence numbers
  ///
  /// ### Example Display Names:
  /// - "Main Application Context (Production)"
  /// - "Web MVC Dispatcher Servlet Context"
  /// - "Test Context #1 for UserServiceTests"
  /// - "Batch Processing Context - JobLauncher"
  ///
  /// ### Usage:
  /// ```dart
  /// print('Operating context: ${context.getDisplayName()}');
  /// // Output: "Operating context: AnnotationConfigApplicationContext - MyApp"
  /// ```
  /// {@endtemplate}
  String getDisplayName();

  /// {@template application_context_parent}
  /// Returns the parent context, if any.
  ///
  /// Parent-child context relationships enable hierarchical configuration
  /// where child contexts inherit pods and configuration from their parents.
  ///
  /// ### Hierarchical Benefits:
  /// - **Configuration Inheritance**: Child contexts inherit parent configuration
  /// - **Pod Delegation**: Children can access pods from parent contexts
  /// - **Module Isolation**: Separate modules with shared base configuration
  /// - **Testing Flexibility**: Test contexts with production-like parent setup
  ///
  /// ### Example:
  /// ```dart
  /// final parentContext = GenericApplicationContext();
  /// await parentContext.refresh();
  /// 
  /// final childContext = GenericApplicationContext.withParent(parentContext);
  /// 
  /// // Child can access parent pods
  /// final parentService = childContext.getPod<ParentService>(); // From parent
  /// final childService = childContext.getPod<ChildService>();   // From child
  /// 
  /// print('Child parent: ${childContext.getParent()?.getId()}'); // Parent ID
  /// ```
  /// {@endtemplate}
  ApplicationContext? getParent();

  /// {@template application_context_supports}
  /// Returns whether this context supports the given [applicationType].
  ///
  /// This method allows the framework and application code to determine
  /// what kind of application environment this context is designed for.
  ///
  /// ### Common Application Types:
  /// - [ApplicationType.WEB]: Web applications with HTTP server support
  /// - [ApplicationType.NONE]: Standalone applications without web stack
  /// - [ApplicationType.BATCH]: Batch processing applications
  /// - [ApplicationType.CLI]: Command-line interface applications
  ///
  /// ### Usage:
  /// ```dart
  /// if (context.supports(ApplicationType.WEB)) {
  ///   // Configure web-specific components
  ///   context.registerPod(WebController);
  ///   context.registerPod(RequestMappingHandler);
  /// } else if (context.supports(ApplicationType.CLI)) {
  ///   // Configure CLI-specific components
  ///   context.registerPod(CommandLineRunner);
  ///   context.registerPod(CommandProcessor);
  /// }
  /// ```
  /// {@endtemplate}
  bool supports(ApplicationType applicationType);

  /// Returns the [Environment] that supports this component or context.
  ///
  /// The supporting environment provides access to property sources,
  /// active and default profiles, and configuration data that influence
  /// how the current context or container is initialized.
  ///
  /// This environment is typically used to resolve placeholders, load
  /// environment-specific settings, or determine profile-based activation
  /// before the container refresh phase.
  ///
  /// Example:
  /// ```dart
  /// final env = applicationContext.getSupportingEnvironment();
  /// final port = env.getProperty('server.port');
  /// ```
  ///
  /// Returns the [Environment] instance backing this context.
  /// Never `null`.
  AbstractEnvironment getSupportingEnvironment();

  /// {@template application_context_get_main_application_class}
  /// Returns the main application class.
  /// 
  /// This is the class that was used to bootstrap the application and serves
  /// as the primary configuration source and entry point.
  ///
  /// ### Framework Usage:
  /// - **Component Scanning**: Base package for annotation scanning
  /// - **Configuration Detection**: Source for `@Configuration` classes
  /// - **Banner Display**: Used in startup banner presentation
  /// - **Metadata Access**: Provides application metadata and version info
  ///
  /// ### Example:
  /// ```dart
  /// final mainClass = context.getMainApplicationClass();
  /// 
  /// print('Main application class: ${mainClass.getSimpleName()}');
  /// print('Package: ${mainClass.getPackage()?.getName()}');
  /// 
  /// // Check for specific annotations
  /// if (mainClass.hasAnnotation<JetLeafApplication>()) {
  ///   print('This is a JetLeaf application');
  /// }
  /// ```
  /// {@endtemplate}
  Class<Object> getMainApplicationClass();

  /// {@template application_context_get_environment}
  /// 🫘 Returns the [Environment] associated with the current context.
  ///
  /// The [Environment] provides unified access to configuration mechanisms
  /// including profiles, property sources, and configuration properties.
  ///
  /// ### Environment Capabilities:
  /// - **Profile Management**: Active profile detection and validation
  /// - **Property Resolution**: Hierarchical property source resolution
  /// - **Configuration Abstraction**: Unified access to various config sources
  /// - **Type Conversion**: Automatic type conversion for property values
  ///
  /// ### Typical Usage:
  /// ```dart
  /// final env = context.getEnvironment();
  /// 
  /// // Check active profiles
  /// if (env.acceptsProfiles({'dev', 'debug'})) {
  ///   print('Running in development mode');
  ///   enableDebugFeatures();
  /// } else if (env.acceptsProfiles({'production'})) {
  ///   print('Running in production mode');
  ///   enableProductionFeatures();
  /// }
  /// 
  /// // Access configuration properties
  /// final dbUrl = env.getProperty('database.url');
  /// final maxConnections = env.getProperty('database.pool.max-size', int.fromString);
  /// final enableCache = env.getProperty('cache.enabled', bool.fromString, defaultValue: false);
  /// 
  /// // Work with property sources
  /// for (final source in env.getPropertySources()) {
  ///   print('Property source: ${source.getName()}');
  /// }
  /// ```
  /// {@endtemplate}
  Environment getEnvironment();

  /// {@template application_context_get_pod_factory}
  /// 🫘 Returns the underlying [ConfigurableListablePodFactory].
  ///
  /// The [ConfigurableListablePodFactory] is the core dependency injection
  /// container responsible for:
  /// - Pod definition registration and storage
  /// - Dependency injection and resolution
  /// - Singleton management and caching
  /// - Lifecycle coordination
  /// - Circular dependency detection and handling
  ///
  /// ### Advanced Operations:
  /// Accessing the pod factory directly enables advanced scenarios that
  /// go beyond basic pod retrieval:
  ///
  /// ```dart
  /// final factory = context.getPodFactory();
  /// 
  /// // Programmatic pod registration
  /// factory.registerDefinition('customService', 
  ///   RootPodDefinition(type: Class<CustomService>()));
  /// 
  /// // Query pod definitions
  /// final podNames = factory.getDefinitionNames();
  /// final hasService = factory.containsDefinition('myService');
  /// 
  /// // Check pod relationships
  /// final dependencies = factory.getDependenciesForPod('userService');
  /// 
  /// // Manual singleton registration
  /// factory.registerSingleton('config', ConfigService());
  /// 
  /// // Advanced pod retrieval with type safety
  /// final service = factory.getPod<MyService>('myService');
  /// 
  /// // Check pod existence and type compatibility
  /// if (factory.isTypeMatch('dataSource', Class<DataSource>())) {
  ///   final ds = factory.getPod<DataSource>('dataSource');
  /// }
  /// ```
  ///
  /// ### Important Notes:
  /// - Use with caution in application code - prefer dependency injection
  /// - Be aware of lifecycle state when performing operations
  /// - Consider thread safety for concurrent access
  /// - Factory modifications may require context refresh to take effect
  /// {@endtemplate}
  ConfigurableListablePodFactory getPodFactory();

  /// {@template application_context_get_lifecycle_processor}
  /// 🆕 Returns the [LifecycleProcessor] associated with the current context.
  ///
  /// The [LifecycleProcessor] is responsible for coordinating the lifecycle
  /// of pods and other components within the context, including:
  /// - Pod initialization and destruction
  /// - Dependency injection and resolution
  /// - Circular dependency detection and handling
  /// - Lifecycle callbacks for pods
  ///
  /// ### Usage:
  /// ```dart
  /// final processor = context.getLifecycleProcessor();
  /// 
  /// // Register a pod with lifecycle callbacks
  /// processor.registerPod('myPod', MyPod());
  /// 
  /// // Perform lifecycle operations
  /// processor.onRefresh();
  /// processor.onClose();
  /// ```
  /// {@endtemplate}
  LifecycleProcessor getLifecycleProcessor();
}

// =================================== CONFIGURABLE APPLICATION CONTEXT =======================================

/// {@template configurable_application_context}
/// A specialized [ApplicationContext] that allows for full configuration
/// and lifecycle management.
///
/// [ConfigurableApplicationContext] extends the basic context interface with
/// comprehensive lifecycle control and configuration capabilities, making it
/// suitable for application bootstrap and runtime management.
///
/// ### Enhanced Capabilities:
/// - **Lifecycle Management**: Full control over context lifecycle phases
/// - **Programmatic Configuration**: Add initializers, listeners, and processors
/// - **Dynamic Reconfiguration**: Refresh context to reload configuration
/// - **Resource Management**: Proper cleanup and resource disposal
/// - **Event System Integration**: Complete event listener management
///
/// ### Typical Usage Pattern:
/// ```dart
/// class MyApplicationContext extends AbstractApplicationContext 
///     implements ConfigurableApplicationContext {
///   
///   @override
///   Future<void> refresh() async {
///     // Custom refresh logic
///     await super.refresh();
///   }
///   
///   @override
///   Future<void> start() async {
///     // Custom startup logic
///     await super.start();
///   }
/// }
/// 
/// void main() async {
///   final context = MyApplicationContext();
///   
///   // Configure context before refresh
///   context.addApplicationListener(MyEventListener());
///   context.addPodFactoryPostProcessor(MyPostProcessor());
///   
///   // Initialize context
///   await context.refresh();
///   
///   // Start context (if not auto-startup)
///   await context.start();
///   
///   // Application runs...
///   
///   // Proper shutdown
///   await context.stop();
///   await context.close();
/// }
/// ```
///
/// ### Lifecycle Phases:
/// 1. **Configuration**: Add listeners, initializers, processors
/// 2. **Refresh**: Load configuration, instantiate pods, publish events
/// 3. **Start**: Transition to running state, start lifecycle pods
/// 4. **Running**: Normal operation, event processing
/// 5. **Stop**: Transition to stopped state, stop lifecycle pods
/// 6. **Close**: Release resources, destroy pods, close context
///
/// See also:
/// - [ApplicationContext] for the basic context interface
/// - [SmartLifecycle] for lifecycle management
/// - [Closeable] for resource cleanup
/// {@endtemplate}
abstract class ConfigurableApplicationContext extends SmartLifecycle implements ApplicationContext, ApplicationStartupAware, Closeable, ConfigurableListablePodFactory {
  /// {@template configurable_application_context_add_listener}
  /// Adds an [ApplicationEventListener] to be notified of all [ApplicationEvent]s.
  ///
  /// Event listeners receive all application events published through the context's
  /// event system, enabling reactive programming patterns and loose coupling.
  ///
  /// ### Listener Registration:
  /// - Listeners are typically registered before context refresh
  /// - Can be added dynamically at runtime
  /// - Receive events in registration order (unless ordered)
  /// - Automatically removed when context is closed
  ///
  /// ### Example:
  /// ```dart
  /// class PerformanceMonitor implements ApplicationEventListener<ApplicationEvent> {
  ///   @override
  ///   void onApplicationEvent(ApplicationEvent event) {
  ///     // Monitor all application events
  ///     metrics.increment('application.events.${event.runtimeType}');
  ///   }
  /// }
  /// 
  /// class DomainEventListener implements ApplicationEventListener<UserCreatedEvent> {
  ///   @override
  ///   void onApplicationEvent(UserCreatedEvent event) {
  ///     // React to specific domain events
  ///     analytics.trackUserCreation(event.user);
  ///   }
  /// }
  /// 
  /// // Registration
  /// context.addApplicationListener(PerformanceMonitor());
  /// context.addApplicationListener(DomainEventListener());
  /// ```
  ///
  /// ### Ordering and Filtering:
  /// Listeners can implement [Ordered] or use `@Order` annotation to control
  /// execution order. For type-specific handling, implement the generic
  /// [ApplicationEventListener] interface.
  /// {@endtemplate}
  Future<void> addApplicationListener(ApplicationEventListener listener);

  /// {@template configurable_application_context_set_parent}
  /// Sets the parent of this application context.
  ///
  /// Establishes a parent-child relationship where this context becomes
  /// the child and inherits configuration and pods from the parent.
  ///
  /// ### Parent-Child Semantics:
  /// - **Configuration Inheritance**: Child inherits parent's environment setup
  /// - **Pod Delegation**: Child can access pods from parent context
  /// - **Lifecycle Independence**: Child lifecycle independent from parent
  /// - **Event Isolation**: Events not propagated between parent and child
  ///
  /// ### Usage:
  /// ```dart
  /// // Create parent context with shared services
  /// final parentContext = GenericApplicationContext();
  /// parentContext.registerSingleton('dataSource', DataSource());
  /// parentContext.registerSingleton('configService', ConfigService());
  /// await parentContext.refresh();
  /// 
  /// // Create child context with module-specific services
  /// final childContext = GenericApplicationContext();
  /// childContext.setParent(parentContext);
  /// childContext.registerSingleton('userService', UserService());
  /// await childContext.refresh();
  /// 
  /// // Child can access both its own and parent's pods
  /// final userService = childContext.getPod<UserService>(); // From child
  /// final dataSource = childContext.getPod<DataSource>();   // From parent
  /// ```
  ///
  /// ### Important:
  /// Parent must be set before context refresh and cannot be changed afterward.
  /// {@endtemplate}
  void setParent(ApplicationContext parent);

  /// {@template configurable_application_context_set_main_application_class}
  /// Sets the main application class.
  /// 
  /// This method configures the primary application class that serves as
  /// the bootstrap entry point and configuration source.
  ///
  /// ### Framework Integration:
  /// - Used for component scanning base package determination
  /// - Provides metadata for banner display and version information
  /// - Serves as reference for configuration class detection
  /// - Used in logging and monitoring context identification
  ///
  /// ### Example:
  /// ```dart
  /// @Configuration
  /// @ComponentScan
  /// class MyApplication {
  ///   // Application configuration
  /// }
  /// 
  /// void main() {
  ///   final context = GenericApplicationContext();
  ///   context.setMainApplicationClass(Class<MyApplication>());
  ///   await context.refresh();
  /// }
  /// ```
  /// {@endtemplate}
  void setMainApplicationClass(Class<Object> mainApplicationClass);

  /// {@template configurable_application_context_set_message_source}
  /// Sets the [MessageSource] used for resolving internationalized messages.
  ///
  /// The message source provides internationalization (i18n) capabilities
  /// for applications that need to support multiple languages and locales.
  ///
  /// ### Message Source Features:
  /// - **Parameterized Messages**: Support for placeholders and arguments
  /// - **Locale Resolution**: Automatic locale detection and fallback
  /// - **Hierarchical Sources**: Parent-child message source relationships
  /// - **Reloadable Bundles**: Hot-reload of message bundles in development
  ///
  /// ### Example:
  /// ```dart
  /// // Set up a resource bundle message source
  /// final messageSource = ResourceBundleMessageSource();
  /// messageSource.setBasename('messages');
  /// messageSource.setDefaultEncoding('UTF-8');
  /// messageSource.setCacheSeconds(300); // Cache for 5 minutes
  /// 
  /// context.setMessageSource(messageSource);
  /// 
  /// // Usage in application components
  /// class InternationalizedService {
  ///   final MessageSource messageSource;
  ///   
  ///   InternationalizedService(this.messageSource);
  ///   
  ///   String getWelcomeMessage(String username, Locale locale) {
  ///     return messageSource.getMessage(
  ///       'welcome.message',
  ///       args: [username],
  ///       locale: locale,
  ///       defaultMessage: 'Welcome, $username!'
  ///     );
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  void setMessageSource(MessageSource messageSource);

  /// {@template configurable_application_context_get_message_source}
  /// Returns the configured [MessageSource].
  ///
  /// Provides access to the internationalization infrastructure for
  /// resolving localized messages throughout the application.
  ///
  /// ### Throws:
  /// - [IllegalStateException] if the message source has not been initialized
  ///
  /// ### Example:
  /// ```dart
  /// // Access message source directly
  /// final messages = context.getMessageSource();
  /// 
  /// // Resolve messages with different strategies
  /// final welcomeMsg = messages.getMessage(
  ///   'user.welcome',
  ///   args: ['John'],
  ///   locale: Locale('en', 'US')
  /// );
  /// 
  /// final errorMsg = messages.getMessage(
  ///   'validation.email.invalid',
  ///   defaultMessage: 'Please enter a valid email address'
  /// );
  /// 
  /// // Use in exception messages
  /// throw ValidationException(
  ///   messages.getMessage('error.validation.failed')
  /// );
  /// 
  /// // Use in logging with localization
  /// logger.info(messages.getMessage('app.startup.complete'));
  /// ```
  /// {@endtemplate}
  MessageSource getMessageSource();

  /// {@template configurable_application_context_set_application_event_bus}
  /// Sets the [ApplicationEventBus] for this application context.
  ///
  /// The event bus is the central hub for event-driven communication within
  /// the application, supporting both synchronous and asynchronous event
  /// processing patterns.
  ///
  /// ### Event Bus Capabilities:
  /// - **Event Publication**: Publish events to registered listeners
  /// - **Listener Registration**: Dynamic listener management
  /// - **Error Handling**: Configurable error handling strategies
  /// - **Filtering**: Event filtering and conditional delivery
  /// - **Ordering**: Listener execution order control
  ///
  /// ### Typical initialization:
  /// ```dart
  /// // Create and configure event bus
  /// final eventBus = ApplicationEventBus();
  /// eventBus.setErrorHandler((event, listener, error) {
  ///   logger.error('Event delivery failed', error: error);
  /// });
  /// 
  /// context.setApplicationEventBus(eventBus);
  /// 
  /// // Usage in application components
  /// class OrderService {
  ///   final ApplicationEventBus eventBus;
  ///   
  ///   OrderService(this.eventBus);
  ///   
  ///   Future<Order> processOrder(Order order) async {
  ///     // Business logic...
  ///     
  ///     // Publish domain event
  ///     eventBus.publish(OrderProcessedEvent(this, order));
  ///     
  ///     return order;
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  void setApplicationEventBus(ApplicationEventBus applicationEventBus);

  /// {@template configurable_application_context_get_application_event_bus}
  /// Returns the [ApplicationEventBus] currently associated with
  /// this application context.
  ///
  /// The event bus enables publish-subscribe communication patterns
  /// throughout the application, promoting loose coupling between
  /// components.
  ///
  /// ### Example:
  /// ```dart
  /// // Access event bus for manual event publishing
  /// final eventBus = context.getApplicationEventBus();
  /// 
  /// // Publish application lifecycle events
  /// eventBus.publish(ApplicationStartedEvent(context));
  /// 
  /// // Publish domain events
  /// eventBus.publish(UserRegisteredEvent(user));
  /// eventBus.publish(PaymentReceivedEvent(payment));
  /// 
  /// // Publish system events
  /// eventBus.publish(CacheClearedEvent());
  /// eventBus.publish(ConfigurationUpdatedEvent(newConfig));
  /// 
  /// // Register listeners programmatically
  /// eventBus.subscribe<OrderShippedEvent>((event) {
  ///   trackingService.updateShipmentStatus(event.orderId, event.trackingNumber);
  /// });
  /// ```
  /// {@endtemplate}
  ApplicationEventBus getApplicationEventBus();

  /// {@template configurable_application_context_add_pod_factory_post_processor}
  /// Adds a [PodFactoryPostProcessor] to be applied to the pod factory.
  ///
  /// Pod factory post-processors are powerful extension points that can
  /// modify pod definitions, change configuration, or apply custom
  /// transformations to the pod factory before pods are instantiated.
  ///
  /// ### Common Use Cases:
  /// - **Property Resolution**: Process `${...}` placeholders in pod definitions
  /// - **Configuration Enhancement**: Add additional metadata to pod definitions
  /// - **Validation**: Validate pod definitions before instantiation
  /// - **Proxy Creation**: Wrap pods with proxies for AOP or other concerns
  ///
  /// ### Example:
  /// ```dart
  /// class CustomPostProcessor implements PodFactoryPostProcessor {
  ///   @override
  ///   Future<void> postProcessFactory(ConfigurableListablePodFactory factory) async {
  ///     // Modify pod definitions before instantiation
  ///     final names = factory.getDefinitionNames();
  ///     for (final name in names) {
  ///       final definition = factory.getDefinition(name);
  ///       
  ///       // Apply custom logic
  ///       if (definition.type.hasAnnotation<Profiled>()) {
  ///         definition.lifecycle.isLazy = true;
  ///       }
  ///     }
  ///   }
  /// }
  /// 
  /// // Registration
  /// context.addPodFactoryPostProcessor(CustomPostProcessor());
  /// context.addPodFactoryPostProcessor(PropertySourcesPlaceholderProcessor());
  /// ```
  ///
  /// ### Execution Order:
  /// Processors are executed in priority order as defined by the
  /// [Ordered] interface or `@Order` annotation.
  /// {@endtemplate}
  void addPodFactoryPostProcessor(PodFactoryPostProcessor processor);

  /// {@template configurable_application_context_refresh}
  /// Refreshes this application context:
  /// - Loads or reloads pod definitions.
  /// - Instantiates singletons.
  /// - Initializes application components.
  /// - Publishes lifecycle events.
  ///
  /// The refresh process is the core initialization sequence that
  /// transitions the context from configured to active state.
  ///
  /// ### Refresh Sequence:
  /// 1. **Prepare Refresh**: Validate state, prepare internal structures
  /// 2. **Obtain Fresh Factory**: Create new pod factory instance
  /// 3. **Prepare Factory**: Register core pods and configuration
  /// 4. **Post-process Factory**: Apply pod factory post-processors
  /// 5. **Register Processors**: Register pod-aware processors
  /// 6. **Initialize Message Source**: Set up internationalization
  /// 7. **Init Application Event Bus**: Initialize event system
  /// 8. **Register Listeners**: Register application event listeners
  /// 9. **Instantiate Singletons**: Create non-lazy singleton pods
  /// 10. **Finish Refresh**: Complete initialization, publish events
  ///
  /// ### Example:
  /// ```dart
  /// try {
  ///   await context.refresh();
  ///   print('Context refreshed successfully');
  ///   print('Active pods: ${context.getPodDefinitionNames()}');
  /// } on PodDefinitionException catch (e) {
  ///   print('Pod configuration error: ${e.message}');
  ///   exit(1);
  /// } on Exception catch (e) {
  ///   print('Context refresh failed: $e');
  ///   exit(1);
  /// }
  /// ```
  ///
  /// ### Throws:
  /// - [IllegalStateException] if the context has not been properly configured
  /// - [PodDefinitionException] if pod definitions are invalid
  /// - Various runtime exceptions if initialization fails
  ///
  /// ### Important:
  /// This method should be called exactly once during the context lifecycle.
  /// {@endtemplate}
  Future<void> setup();
}

// ======================================== APPLICATION CONTEXT INITIALIZER ==============================

/// {@template application_context_initializer}
/// Strategy interface for initializing an [ApplicationContext] before it is
/// refreshed.
///
/// Application context initializers provide a hook for programmatic
/// configuration of the context before the refresh process begins. They
/// are particularly useful for:
///
/// ### Common Use Cases:
/// - **Programmatic Configuration**: Register pods or adjust settings via code
/// - **Environment Setup**: Configure profiles or property sources
/// - **Custom Validation**: Validate context configuration before refresh
/// - **Integration Setup**: Prepare integration with external systems
/// - **Feature Flags**: Enable/disable features based on configuration
///
/// ### Execution Context:
/// - Initializers are called **after** the context is created
/// - But **before** the pod factory is refreshed
/// - In the order defined by [Ordered] or `@Order` annotation
/// - All initializers are called even if one fails
///
/// ### Example:
/// ```dart
/// class DatabaseInitializer implements ApplicationContextInitializer<GenericApplicationContext> {
///   @override
///   void initialize(GenericApplicationContext context) {
///     // Configure database settings before refresh
///     final env = context.getEnvironment();
///     
///     if (env.acceptsProfiles({'cloud'})) {
///       // Use cloud database configuration
///       context.getPodFactory().registerSingleton(
///         'dataSource',
///         CloudDataSource(env.getProperty('cloud.db.url'))
///       );
///     } else {
///       // Use local database configuration
///       context.getPodFactory().registerSingleton(
///         'dataSource', 
///         LocalDataSource(env.getProperty('local.db.path'))
///       );
///     }
///     
///     logger.info('Database configuration initialized');
///   }
/// }
/// 
/// class SecurityInitializer implements ApplicationContextInitializer<GenericApplicationContext> {
///   @override
///   void initialize(GenericApplicationContext context) {
///     // Set up security configuration
///     context.getPodFactory().registerSingleton(
///       'securityConfig',
///       SecurityConfig(
///         enabled: context.getEnvironment().getProperty('security.enabled', bool.fromString, true),
///         jwtSecret: context.getEnvironment().getRequiredProperty('security.jwt.secret')
///       )
///     );
///   }
/// }
/// 
/// void main() async {
///   final ctx = GenericApplicationContext();
///   
///   // Register initializers
///   ctx.addApplicationContextInitializer(DatabaseInitializer());
///   ctx.addApplicationContextInitializer(SecurityInitializer());
///   
///   // Initializers will be called during refresh
///   await ctx.refresh();
/// }
/// ```
/// {@endtemplate}
@Generic(ApplicationContextInitializer)
abstract class ApplicationContextInitializer<T extends ConfigurableApplicationContext> {
  /// {@macro application_context_initializer}
  ///
  /// {@template application_context_initializer_initialize}
  /// Initialize the given [applicationContext] before refresh.
  ///
  /// This method is called during the context refresh process, after
  /// the context is created but before any pods are instantiated. It
  /// provides an opportunity to programmatically configure the context.
  ///
  /// ### Parameters:
  /// - [applicationContext]: The application context being initialized
  ///
  /// ### Typical Operations:
  /// - Register additional pod definitions
  /// - Configure the environment or property sources
  /// - Set up application-specific context attributes
  /// - Validate configuration state
  /// - Register custom factories or processors
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void initialize(GenericApplicationContext context) {
  ///   // Access and modify the pod factory
  ///   final factory = context.getPodFactory();
  ///   factory.registerSingleton('appMetadata', AppMetadata(
  ///     version: '1.0.0',
  ///     buildTime: DateTime.now()
  ///   ));
  ///   
  ///   // Configure based on environment
  ///   final env = context.getEnvironment();
  ///   if (env.acceptsProfiles({'testing'})) {
  ///     factory.registerSingleton('emailService', MockEmailService());
  ///   } else {
  ///     factory.registerSingleton('emailService', ProductionEmailService(
  ///       apiKey: env.getRequiredProperty('email.api.key')
  ///     ));
  ///   }
  ///   
  ///   // Set custom context attributes
  ///   context.setAttribute('deployment.region', 'us-west-2');
  /// }
  /// ```
  ///
  /// ### Error Handling:
  /// Exceptions thrown from initializers will typically prevent the
  /// context from refreshing successfully. Initializers should handle
  /// their own exceptions or throw meaningful error messages.
  /// {@endtemplate}
  void initialize(T applicationContext);
}