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

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import 'context/application_context.dart';
import 'context/event/application_event.dart';
import 'message/message_source.dart';

/// {@template pod_factory_aware}
/// 🫘 Interface for components that need access to the [PodFactory].
///
/// The [PodFactoryAware] interface is part of JetLeaf's **Aware interface pattern**,
/// which provides a standardized way for framework-managed components to receive
/// callback notifications about their runtime environment.
///
/// ### When to Implement:
/// Implement this interface when your component needs to:
/// - **Programmatically access** other pods not available through constructor injection
/// - **Perform dynamic lookups** based on runtime conditions
/// - **Access container metadata** or advanced DI features
/// - **Implement custom lifecycle logic** that requires container interaction
///
/// ### Framework Integration:
/// - Called automatically by the framework after pod instantiation
/// - Invoked before any `@PostConstruct` methods
/// - The provided [PodFactory] is fully configured and operational
///
/// ### Example Usage:
/// ```dart
/// class DynamicServiceLocator implements PodFactoryAware {
///   late PodFactory _podFactory;
///
///   @override
///   void setPodFactory(PodFactory podFactory) {
///     _podFactory = podFactory;
///   }
///
///   T getService<T>(String serviceName) {
///     return _podFactory.getPod<T>(serviceName);
///   }
///
///   bool hasService(String serviceName) {
///     return _podFactory.containsPod(serviceName);
///   }
/// }
/// ```
///
/// ### Best Practices:
/// - Store the [PodFactory] reference in a **late final** field
/// - Avoid expensive operations in the setter method
/// - Prefer constructor injection over [PodFactoryAware] when possible
/// - Use for advanced scenarios where static dependency resolution is insufficient
///
/// See also:
/// - [PodFactory] for the dependency injection container interface
/// - [ApplicationContextAware] for application context access
/// - [PodNameAware] for pod name awareness
/// {@endtemplate}
abstract interface class PodFactoryAware {
  /// {@template pod_factory_aware.set_pod_factory}
  /// Sets the [PodFactory] that created and manages this component.
  ///
  /// This method is called by the JetLeaf framework **once** during component
  /// initialization, immediately after construction and before any other
  /// lifecycle callbacks.
  ///
  /// ### Implementation Notes:
  /// - The provided [podFactory] is guaranteed to be non-null
  /// - The method should store the reference for later use
  /// - Avoid complex initialization logic in this method
  /// - Throwing exceptions may prevent the component from being fully initialized
  ///
  /// ### Parameters:
  /// - [podFactory]: The fully configured PodFactory instance that created this component
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void setPodFactory(PodFactory podFactory) {
  ///   _podFactory = podFactory;
  ///   // Optional: perform simple initialization that requires PodFactory
  ///   _initializeCache();
  /// }
  /// ```
  /// {@endtemplate}
  void setPodFactory(PodFactory podFactory);
}

/// {@template pod_name_aware}
/// 🫘 Interface for components that need to know their assigned pod name.
///
/// The [PodNameAware] interface allows framework-managed components to
/// discover their registration name within the dependency injection container.
///
/// ### Common Use Cases:
/// - **Logging and Diagnostics**: Include pod name in log messages
/// - **Dynamic Configuration**: Load configuration based on pod identity
/// - **Conditional Behavior**: Implement logic that varies by pod name
/// - **Metadata Association**: Associate additional metadata with the pod
///
/// ### Framework Integration:
/// - Called automatically after pod instantiation
/// - Invoked after [PodFactoryAware] but before `@PostConstruct` methods
/// - The provided name matches the registration name in the PodFactory
///
/// ### Example Usage:
/// ```dart
/// @Component
/// class NamedService implements PodNameAware {
///   late String _podName;
///   final List<String> _operations = [];
///
///   @override
///   void setPodName(String name) {
///     _podName = name;
///   }
///
///   void performOperation(String operation) {
///     _operations.add(operation);
///     print('Service "$_podName" performed: $operation');
///   }
///
///   String getServiceInfo() {
///     return 'Service "$_podName" has performed ${_operations.length} operations';
///   }
/// }
/// ```
///
/// ### Best Practices:
/// - Use pod names for identification, not for business logic when possible
/// - Consider using `@Qualifier` annotations for disambiguation instead
/// - Pod names may change between different environments or configurations
///
/// See also:
/// - [PodFactoryAware] for container access
/// - [ApplicationContextAware] for broader context awareness
/// {@endtemplate}
abstract interface class PodNameAware {
  /// {@template pod_name_aware.set_pod_name}
  /// Sets the name under which this component is registered in the PodFactory.
  ///
  /// This method is called automatically by the framework during component
  /// initialization with the exact name used for pod registration.
  ///
  /// ### Parameters:
  /// - [name]: The registration name of this pod in the PodFactory
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void setPodName(String name) {
  ///   _podName = name;
  ///   logger.info('Pod "$name" initialized successfully');
  /// }
  /// ```
  /// {@endtemplate}
  void setPodName(String name);
}

/// {@template application_context_aware}
/// 🫘 Interface for components that need access to the [ApplicationContext].
///
/// The [ApplicationContextAware] interface provides components with access to
/// the broader application context, enabling interaction with application-level
/// services, lifecycle management, and event system.
///
/// ### Key Capabilities:
/// - **Event Publication**: Publish application events to the context
/// - **Resource Access**: Access application-scoped resources and services
/// - **Lifecycle Management**: Participate in application startup/shutdown
/// - **Profile Detection**: Check active profiles and environment settings
/// - **Internationalization**: Access message sources and localization
///
/// ### Framework Integration:
/// - Called during application context initialization phase
/// - Invoked after [PodFactoryAware] and [PodNameAware] callbacks
/// - The context is fully configured but not yet refreshed when called
///
/// ### Example Usage:
/// ```dart
/// @Component
/// class EventPublisherService implements ApplicationContextAware {
///   late ApplicationContext _applicationContext;
///
///   @override
///   void setApplicationContext(ApplicationContext applicationContext) {
///     _applicationContext = applicationContext;
///   }
///
///   void publishUserEvent(User user, String action) {
///     final event = UserEvent(this, user, action);
///     _applicationContext.publishEvent(event);
///   }
///
///   bool isProduction() {
///     return _applicationContext.getEnvironment()
///         .acceptsProfiles({'production'});
///   }
/// }
/// ```
///
/// ### Best Practices:
/// - Use for application-level concerns, not business logic
/// - Prefer constructor injection for application-scoped dependencies
/// - Be cautious about circular dependencies with the context
/// - Consider using [ApplicationEventPublisherAware] for event-specific needs
///
/// See also:
/// - [ApplicationContext] for the application context interface
/// - [ApplicationEventBusAware] for event bus access
/// - [MessageSourceAware] for internationalization support
/// {@endtemplate}
abstract interface class ApplicationContextAware {
  /// {@template application_context_aware.set_application_context}
  /// Sets the [ApplicationContext] that this component runs in.
  ///
  /// This method is called by the framework during the application context
  /// initialization process, providing access to the full application context.
  ///
  /// ### Parameters:
  /// - [applicationContext]: The ApplicationContext instance managing this component
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void setApplicationContext(ApplicationContext applicationContext) {
  ///   _applicationContext = applicationContext;
  ///   // Register as application listener if needed
  ///   _applicationContext.addApplicationListener(this);
  /// }
  /// ```
  /// {@endtemplate}
  void setApplicationContext(ApplicationContext applicationContext);
}

/// {@template message_source_aware}
/// 🫘 Interface for components that need access to a [MessageSource].
///
/// The [MessageSourceAware] interface enables components to access
/// internationalization (i18n) and localization services for resolving
/// parameterized messages in different locales.
///
/// ### Key Features:
/// - **Message Resolution**: Resolve message codes to localized strings
/// - **Parameter Support**: Handle parameterized messages with placeholders
/// - **Locale Awareness**: Support multiple languages and regions
/// - **Fallback Handling**: Graceful degradation when messages are missing
///
/// ### Framework Integration:
/// - Called during component initialization when a MessageSource is available
/// - The MessageSource may be null if no message source is configured
/// - Typically configured via the ApplicationContext's message source
///
/// ### Example Usage:
/// ```dart
/// @Component
/// class InternationalizedService implements MessageSourceAware {
///   MessageSource? _messageSource;
///
///   @override
  ///   void setMessageSource(MessageSource? messageSource) {
  ///     _messageSource = messageSource;
  ///   }
///
///   String getWelcomeMessage(String username, Locale locale) {
///     return _messageSource?.getMessage(
///       'welcome.message',
///       args: [username],
///       locale: locale,
///       defaultMessage: 'Welcome, $username!'
///     ) ?? 'Welcome, $username!';
///   }
///
///   String getErrorMessage(String errorCode, Locale locale) {
///     return _messageSource?.getMessage(
///       'error.$errorCode',
///       locale: locale,
///       defaultMessage: 'An error occurred.'
///     ) ?? 'An error occurred.';
///   }
/// }
/// ```
///
/// ### Best Practices:
/// - Always provide sensible default messages
/// - Handle null MessageSource gracefully in production code
/// - Use consistent message code naming conventions
/// - Consider locale fallback chains for better user experience
///
/// See also:
/// - [MessageSource] for the message source interface
/// - [ApplicationContextAware] for broader context access
/// {@endtemplate}
abstract interface class MessageSourceAware {
  /// {@template message_source_aware.set_message_source}
  /// Sets the [MessageSource] that this component can use for message resolution.
  ///
  /// This method is called by the framework when a MessageSource is available
  /// in the application context. The MessageSource may be null if no message
  /// source has been configured.
  ///
  /// ### Parameters:
  /// - [messageSource]: The MessageSource instance, or null if not available
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void setMessageSource(MessageSource? messageSource) {
  ///   _messageSource = messageSource;
  ///   if (_messageSource == null) {
  ///     logger.warn('No MessageSource configured, using default messages');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  void setMessageSource(MessageSource? messageSource);
}

/// {@template application_event_bus_aware}
/// 🫘 Interface for components that need access to the [ApplicationEventBus].
///
/// The [ApplicationEventBusAware] interface provides components with direct
/// access to the application's event bus for publishing and subscribing to
/// application events in an event-driven architecture.
///
/// ### Event-Driven Architecture Benefits:
/// - **Loose Coupling**: Components communicate through events without direct dependencies
/// - **Asynchronous Processing**: Support for async event handling
/// - **Extensibility**: Easy to add new event listeners without modifying publishers
/// - **Audit Trail**: Events provide natural audit points in system behavior
///
/// ### Framework Integration:
/// - Called during component initialization when event bus is available
/// - The event bus may be null if event system is disabled
/// - Events are typically processed synchronously in the calling thread
///
/// ### Example Usage:
/// ```dart
/// @Component
/// class OrderService implements ApplicationEventBusAware {
///   ApplicationEventBus? _eventBus;
///
///   @override
///   void setApplicationEventBus(ApplicationEventBus? applicationEventBus) {
///     _eventBus = applicationEventBus;
///   }
///
///   Future<Order> createOrder(OrderRequest request) async {
///     final order = Order.fromRequest(request);
///     
///     // Publish domain event
///     _eventBus?.publish(OrderCreatedEvent(this, order));
///     
///     // Publish integration event
///     _eventBus?.publish(OrderPlacedEvent(this, order));
///     
///     return order;
///   }
///
///   void subscribeToPaymentEvents() {
///     _eventBus?.subscribe<PaymentReceivedEvent>((event) {
///       _fulfillOrder(event.orderId);
///     });
///   }
/// }
/// ```
///
/// ### Best Practices:
/// - Use domain events for business logic, system events for technical concerns
/// - Keep event objects immutable and serializable
/// - Consider event ordering and idempotency in distributed systems
/// - Use `@EventListener` annotation for simpler event handling when possible
///
/// See also:
/// - [ApplicationEventBus] for the event bus interface
/// - [ApplicationEvent] for base event class
/// - [ApplicationContextAware] for alternative event publishing via context
/// {@endtemplate}
abstract interface class ApplicationEventBusAware {
  /// {@template application_event_bus_aware.set_application_event_bus}
  /// Sets the [ApplicationEventBus] that this component can use for event operations.
  ///
  /// This method is called by the framework when an ApplicationEventBus is
  /// available. The event bus may be null if the event system is not enabled
  /// or configured.
  ///
  /// ### Parameters:
  /// - [applicationEventBus]: The ApplicationEventBus instance, or null if not available
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void setApplicationEventBus(ApplicationEventBus? applicationEventBus) {
  ///   _eventBus = applicationEventBus;
  ///   if (_eventBus != null) {
  ///     _setupEventSubscriptions();
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  void setApplicationEventBus(ApplicationEventBus? applicationEventBus);
}

/// {@template conversion_service_aware}
/// 🫘 Interface for components that need access to a [ConversionService].
///
/// The [ConversionServiceAware] interface enables components to perform
/// runtime type conversions between different data types, formats, and
/// representations using the framework's unified conversion system.
///
/// ### Conversion Capabilities:
/// - **Type Conversion**: Convert between basic types (String, int, bool, etc.)
/// - **Custom Converters**: Register and use application-specific converters
/// - **Format Parsing**: Parse and format dates, numbers, and custom formats
/// - **Collection Conversion**: Convert between different collection types
/// - **Null-Safe**: Handle null values appropriately during conversion
///
/// ### Framework Integration:
/// - Called during component initialization when ConversionService is available
/// - The service may be null if no conversion service is configured
/// - Default conversion service provides common type conversions
///
/// ### Example Usage:
/// ```dart
/// @Component
/// class ConfigurationProcessor implements ConversionServiceAware {
///   ConversionService? _conversionService;
///
///   @override
///   void setConversionService(ConversionService? conversionService) {
///     _conversionService = conversionService;
///   }
///
///   T getConfiguration<T>(String key, T defaultValue) {
///     final value = _environment.getProperty(key);
///     if (value == null) {
///       return defaultValue;
///     }
///     
///     return _conversionService?.convert<T>(value) ?? defaultValue;
///   }
///
///   List<int> parseIdList(String idListString) {
///     return _conversionService?.convert<List<int>>(idListString) ?? [];
///   }
///
///   DateTime? parseDate(String dateString) {
///     return _conversionService?.convert<DateTime>(dateString);
///   }
/// }
/// ```
///
/// ### Best Practices:
/// - Always provide fallback values when conversion may fail
/// - Handle conversion exceptions gracefully
/// - Use specific converter interfaces for complex conversion logic
/// - Consider performance implications for frequent conversions
///
/// See also:
/// - [ConversionService] for the conversion service interface
/// - [Converter] for custom type converter implementations
/// - [GenericConverter] for generic conversion implementations
/// {@endtemplate}
abstract interface class ConversionServiceAware {
  /// {@template conversion_service_aware.set_conversion_service}
  /// Sets the [ConversionService] that this component can use for type conversions.
  ///
  /// This method is called by the framework when a ConversionService is
  /// available in the application context. The service may be null if no
  /// conversion service has been configured.
  ///
  /// ### Parameters:
  /// - [conversionService]: The ConversionService instance, or null if not available
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void setConversionService(ConversionService? conversionService) {
  ///   _conversionService = conversionService;
  ///   if (_conversionService == null) {
  ///     logger.warn('No ConversionService available, limited conversion support');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  void setConversionService(ConversionService? conversionService);
}

// ==================================== ENVIRONMENT AWARE ====================================

/// {@template environment_aware}
/// 🫘 Interface for components that can be configured with an [Environment].
///
/// The [EnvironmentAware] interface allows components to access and interact
/// with the application's environment configuration, including profiles,
/// property sources, and configuration metadata.
///
/// ### Environment Capabilities:
/// - **Profile Management**: Check active and default profiles
/// - **Property Resolution**: Access configuration properties from various sources
/// - **Configuration Detection**: Determine application configuration state
/// - **Feature Toggling**: Enable/disable features based on environment
///
/// ### Framework Integration:
/// - Called during component initialization with non-null Environment
/// - The environment is fully configured with all property sources
/// - Profiles are activated and property resolution is operational
///
/// ### Example Usage:
/// ```dart
/// @Component
/// class EnvironmentAwareService implements EnvironmentAware {
///   late Environment _environment;
///
///   @override
///   void setEnvironment(Environment environment) {
///     _environment = environment;
///   }
///
///   bool isFeatureEnabled(String featureName) {
///     return _environment.getProperty(
///       'features.$featureName.enabled',
///       bool.fromString,
///       defaultValue: false
///     );
///   }
///
///   String getDataSourceUrl() {
///     return _environment.getRequiredProperty('datasource.url');
///   }
///
///   bool isDevelopment() {
///     return _environment.acceptsProfiles({'development'});
///   }
///
///   bool isProduction() {
///     return _environment.acceptsProfiles({'production'});
///   }
/// }
/// ```
///
/// ### Best Practices:
/// - Use for environment-specific configuration, not business logic
/// - Provide sensible default values for optional properties
/// - Use `getRequiredProperty` for mandatory configuration
/// - Consider using `@ConfigurationProperties` for structured configuration
///
/// See also:
/// - [Environment] for the environment interface
/// - [ApplicationContextAware] for alternative environment access
/// - [ConfigurationProperties] for type-safe configuration binding
/// {@endtemplate}
abstract interface class EnvironmentAware {
  /// {@template environment_aware.set_environment}
  /// Sets the [Environment] that this component runs in.
  ///
  /// This method is called by the framework with a fully configured
  /// Environment instance that contains all active property sources
  /// and profile information.
  ///
  /// ### Parameters:
  /// - [environment]: The Environment instance for this application context
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void setEnvironment(Environment environment) {
  ///   _environment = environment;
  ///   // Validate required configuration
  ///   _validateConfiguration();
  /// }
  /// ```
  /// {@endtemplate}
  void setEnvironment(Environment environment);
}

// ==================================== ENTRY APPLICATION AWARE ====================================

/// {@template entry_application_aware}
/// 🚀 Interface for components that need access to the entry application class.
///
/// The [EntryApplicationAware] interface provides components with knowledge
/// of the main application class, enabling framework integration points that
/// need to understand the application's entry point and structure.
///
/// ### Typical Use Cases:
/// - **Framework Integration**: Components that need to interact with application bootstrap
/// - **Configuration Scanning**: Components that perform classpath scanning relative to main class
/// - **Metadata Inspection**: Access annotations or metadata on the main application class
/// - **Plugin Systems**: Plugins that need application class information for registration
///
/// ### Framework Integration:
/// - Called during application bootstrap process
/// - Provides the Class object representing the main application class
/// - Useful for framework components rather than application business logic
///
/// ### Example Usage:
/// ```dart
/// @Component
/// class ApplicationMetadataService implements EntryApplicationAware {
///   late Class<Object> _entryApplication;
///
///   @override
///   void setEntryApplication(Class<Object> entryApplication) {
///     _entryApplication = entryApplication;
///   }
///
///   String getApplicationName() {
///     return _entryApplication.getSimpleName();
///   }
///
///   bool hasAnnotation<T>() {
///     return _entryApplication.hasAnnotation<T>();
///   }
///
///   Package getApplicationPackage() {
///     return _entryApplication.getPackage();
///   }
///
///   List<Class> findConfigurationClasses() {
///     return _entryApplication.getPackage()
///         .getClasses()
///         .where((cls) => cls.hasAnnotation<Configuration>())
///         .toList();
///   }
/// }
/// ```
///
/// ### Best Practices:
/// - Primarily for framework-level components, not application business logic
/// - Use for scanning and metadata purposes rather than runtime behavior
/// - Consider performance implications when performing reflection operations
/// - Cache expensive metadata operations when possible
///
/// See also:
/// - [ApplicationContextAware] for broader application context access
/// - [PodFactoryAware] for dependency injection container access
/// {@endtemplate}
abstract interface class EntryApplicationAware {
  /// {@template entry_application_aware.set_entry_application}
  /// Sets the entry application class that this component can reference.
  ///
  /// This method is called by the framework during bootstrap with the
  /// Class object representing the main application entry point.
  ///
  /// ### Parameters:
  /// - [entryApplication]: The Class object representing the main application class
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// void setEntryApplication(Class<Object> entryApplication) {
  ///   _entryApplication = entryApplication;
  ///   logger.info('Application class: ${entryApplication.getQualifiedName()}');
  /// }
  /// ```
  /// {@endtemplate}
  void setEntryApplication(Class<Object> entryApplication);
}