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

/// {@template context_library}
/// A comprehensive application context management library for Dart that provides
/// the foundation for dependency injection, lifecycle management, event handling,
/// and application configuration.
/// 
/// This library serves as the core container infrastructure for Dart applications,
/// offering sophisticated context management with support for annotation-based
/// configuration, event publication, graceful shutdown, and modular application
/// development.
/// 
/// ## Core Features
/// 
/// - **Dependency Injection Container**: Advanced IoC container with pod/pod
///   lifecycle management
/// - **Annotation-Driven Configuration**: Use annotations to configure application
///   components without XML or code configuration
/// - **Application Events**: Publish-subscribe event model for loose coupling
///   between components
/// - **Graceful Shutdown**: Controlled application shutdown with exit code
///   management
/// - **Modular Architecture**: Support for application modules and conditional
///   component registration
/// - **Type Filtering**: Advanced type filtering for conditional pod registration
/// - **Lifecycle Management**: Comprehensive lifecycle callbacks and keep-alive
///   mechanisms
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:your_package/context.dart';
/// 
/// @Component
/// class UserService {
///   void createUser(String username) {
///     print('Creating user: $username');
///   }
/// }
/// 
/// @EventListener
/// class UserEventListener {
///   void handleUserCreated(UserCreatedEvent event) {
///     print('User created: ${event.username}');
///   }
/// }
/// 
/// void main() async {
///   // Create annotation-based application context
///   final context = AnnotationConfigApplicationContext();
///   
///   // Register component classes
///   context.register(UserService);
///   context.register(UserEventListener);
///   
///   // Initialize the application context
///   await context.refresh();
///   
///   // Use the application
///   final userService = context.getPod<UserService>();
///   userService.createUser('john_doe');
///   
///   // Gracefully shutdown
///   await context.close();
/// }
/// ```
/// 
/// ## Architecture Overview
/// 
/// The library is organized into several cohesive packages:
/// 
/// - **Core Context**: Fundamental application context implementations
/// - **Event System**: Application event publication and listening
/// - **Exit Code Management**: Graceful shutdown with proper exit codes
/// - **Type Filtering**: Conditional component registration
/// - **Application Metadata**: Application type, modules, and configuration
/// 
/// ## Module Exports
/// 
/// ### Core Context Implementations
/// - [GenericApplicationContext]: Flexible general-purpose application context
/// - [AbstractApplicationContext]: Base class with common context functionality
/// - [AnnotationConfigApplicationContext]: Annotation-driven configuration context
/// 
/// ### Event System
/// - [ApplicationEvent]: Base class for all application events
/// - [EventListener]: Mechanism for handling application events
/// 
/// ### Exit Code Management
/// - [ExitCode]: Standardized application exit codes
/// - [ExitCodeGenerator]: Strategy for generating application exit codes
/// 
/// ### Type Filtering
/// - [TypeFilter]: Conditional type filtering for component scanning
/// 
/// ### Application Metadata & Helpers
/// - [KeepAlive]: Lifecycle management for long-running components
/// - [Helpers]: Utility functions for context operations
/// - [ApplicationContext]: Core application context interface
/// - [ApplicationType]: Enumeration of application types (web, console, etc.)
/// - [ApplicationModule]: Modular application configuration
/// - [PodRegistrar]: Interface for pod/pod registration
/// 
/// ## Core Components Deep Dive
/// 
/// ### Application Context Hierarchy
/// 
/// ```dart
/// // Using generic application context for maximum flexibility
/// final genericContext = GenericApplicationContext();
/// await genericContext.registerPod('userService', UserService());
/// await genericContext.refresh();
/// 
/// // Using annotation-based configuration for convenience
/// final annotationContext = AnnotationConfigApplicationContext();
/// annotationContext.scan('package:example/test.dart');
/// await annotationContext.refresh();
/// 
/// // Custom application context extending abstract base
/// class CustomApplicationContext extends AbstractApplicationContext {
///   @override
///   Future<void> onRefresh() async {
///     // Custom refresh logic
///     await super.onRefresh();
///   }
/// }
/// ```
/// 
/// ### Event System in Action
/// 
/// ```dart
/// // Define custom application event
/// class UserCreatedEvent extends ApplicationEvent {
///   final String username;
///   
///   UserCreatedEvent(this.username) : super(DateTime.now());
/// }
/// 
/// // Event listener with conditional handling
/// @EventListener
/// class NotificationService {
///   @EventListener
///   void onUserCreated(UserCreatedEvent event) {
///     // Send welcome notification
///     print('Sending welcome notification to ${event.username}');
///   }
///   
///   @EventListener(condition: "#event.premium")
///   void onPremiumUserCreated(UserCreatedEvent event) {
///     // Special handling for premium users
///     print('Sending premium welcome package to ${event.username}');
///   }
/// }
/// 
/// // Publishing events
/// class UserService {
///   final ApplicationEventPublisher eventPublisher;
///   
///   void createUser(String username, bool isPremium) {
///     // Business logic
///     final event = UserCreatedEvent(username);
///     eventPublisher.publishEvent(event);
///   }
/// }
/// ```
/// 
/// ### Exit Code Management
/// 
/// ```dart
/// // Custom exit code generator
/// class CustomExitCodeGenerator implements ExitCodeGenerator {
///   @override
///   int generateExitCode(ApplicationContext context) {
///     if (context.hasFailedPods()) {
///       return ExitCode.SOFTWARE;
///     }
///     return ExitCode.OK;
///   }
/// }
/// 
/// // Graceful shutdown with exit codes
/// void main() async {
///   final context = AnnotationConfigApplicationContext();
///   
///   try {
///     await context.refresh();
///     await runApplication(context);
///     exit(ExitCode.OK);
///   } catch (error) {
///     logger.error('Application failed', error);
///     exit(ExitCode.SOFTWARE);
///   } finally {
///     await context.close();
///   }
/// }
/// ```
/// 
/// ### Advanced Type Filtering
/// 
/// ```dart
/// // Custom type filter for conditional registration
/// class DevelopmentOnlyFilter implements TypeFilter {
///   @override
///   bool match(Type type) {
///     return const bool.fromEnvironment('dart.vm.product') == false;
///   }
/// }
/// 
/// // Using filters in component scanning
/// @Component
/// @Conditional(DevelopmentOnlyFilter)
/// class DevelopmentService {
///   // This service only registers in development mode
/// }
/// 
/// // Annotation-based filtering
/// @Component
/// @Profile('development')
/// class DevDataSource {
///   // Development-specific data source
/// }
/// ```
/// 
/// ## Configuration Patterns
/// 
/// ### Programmatic Configuration
/// ```dart
/// final context = GenericApplicationContext();
/// context
///   ..registerPod('primaryDataSource', PrimaryDataSource())
///   ..registerPod('userRepository', UserRepository())
///   ..registerPod('userService', UserService());
/// 
/// await context.refresh();
/// ```
/// 
/// ### Annotation-Based Configuration
/// ```dart
/// @Configuration
/// class AppConfig {
///   @Pod
///   DataSource dataSource() => PrimaryDataSource();
///   
///   @Pod
///   UserRepository userRepository(DataSource dataSource) => 
///       UserRepository(dataSource);
/// }
/// 
/// final context = AnnotationConfigApplicationContext();
/// context.register(AppConfig);
/// await context.refresh();
/// ```
/// 
/// ### Modular Application Setup
/// ```dart
/// class CoreModule implements ApplicationModule {
///   @override
///   void configurePods(PodRegistrar registrar) {
///     registrar.register(CoreService);
///   }
/// }
/// 
/// class WebModule implements ApplicationModule {
///   @override
///   void configurePods(PodRegistrar registrar) {
///     registrar.register(WebController);
///   }
/// }
/// 
/// final context = GenericApplicationContext();
/// context.registerModule(CoreModule());
/// context.registerModule(WebModule());
/// ```
/// 
/// ## Integration Patterns
/// 
/// - **Console Applications**: Managed lifecycle for command-line tools
/// - **Web Applications**: Context management for HTTP servers
/// - **Microservices**: Lightweight contexts for service instances
/// - **Batch Processing**: Job execution with proper resource management
/// - **Testing**: Isolated contexts for unit and integration tests
/// 
/// ## Best Practices
/// 
/// - Use `@EventListener` for loose coupling between components
/// - Implement proper cleanup in `@PreDestroy` methods
/// - Use exit codes for clear application state communication
/// - Leverage type filtering for environment-specific configurations
/// - Use application modules for better organization in large applications
/// - Always call `context.close()` for proper resource cleanup
/// - Monitor context lifecycle events for debugging and monitoring
/// 
/// ## Performance Considerations
/// 
/// - Limit the number of eagerly initialized pods in large applications
/// - Use lazy initialization for rarely used components
/// - Consider context hierarchy for shared resources
/// - Cache expensive lookups in frequently accessed components
/// - Monitor event listener performance in high-volume event systems
/// - Use appropriate keep-alive strategies for long-running operations
/// 
/// {@endtemplate}
library;

/// Core application context implementations and abstractions.
export 'src/context/core/generic_application_context.dart';
export 'src/context/core/abstract_application_context.dart';
export 'src/context/core/annotation_config_application_context.dart';

/// Application event publication and listener infrastructure.
export 'src/context/event/application_event.dart';
export 'src/context/event/event_listener.dart';

/// Exit code management for graceful application shutdown.
export 'src/context/exit_code/exit_code.dart';
export 'src/context/exit_code/exit_code_generator.dart';

/// Type filtering for conditional component registration.
export 'src/context/type_filters/type_filter.dart';

/// Lifecycle management, utilities, and core application interfaces.
export 'src/context/keep_alive.dart';
export 'src/context/helpers.dart';
export 'src/context/application_context.dart';
export 'src/context/application_type.dart';
export 'src/context/application_module.dart';
export 'src/context/pod_registrar.dart';