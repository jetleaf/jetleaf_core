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

/// {@template annotations_library}
/// A comprehensive annotation library for Dart that provides declarative configuration
/// and metadata for dependency injection, lifecycle management, component scanning,
/// and application configuration.
/// 
/// This library enables developers to use annotations to configure application components,
/// define dependency injection rules, manage object lifecycles, and create conditional
/// configurations without boilerplate code.
/// 
/// ## Core Features
/// 
/// - **Dependency Injection**: Declarative dependency injection with `@Autowired` and `@Pod`
/// - **Lifecycle Management**: Control object creation, initialization, and destruction
/// - **Component Stereotyping**: Mark classes as specific component types with stereotypes
/// - **Conditional Configuration**: Conditional pod registration based on environment or conditions
/// - **Configuration Classes**: Java-style `@Configuration` classes for programmatic setup
/// - **Comprehensive Metadata**: Rich annotation set for complete application configuration
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:your_package/annotations.dart';
/// 
/// @Configuration
/// class AppConfig {
///   @Pod
///   DataSource dataSource() {
///     return PrimaryDataSource();
///   }
/// }
/// 
/// @Repository
/// class UserRepository {
///   final DataSource _dataSource;
///   
///   @Autowired
///   UserRepository(this._dataSource);
///   
///   @PostConstruct
///   void init() {
///     print('UserRepository initialized');
///   }
///   
///   @PreDestroy  
///   void cleanup() {
///     print('UserRepository cleaning up');
///   }
/// }
/// 
/// @Service
/// @Conditional(ProductionCondition)
/// class UserService {
///   final UserRepository _repository;
///   
///   UserService(this._repository);
///   
///   @Async
///   Future<void> processUser(String userId) async {
///     // Async processing
///   }
/// }
/// ```
/// 
/// ## Annotation Categories
/// 
/// ### Lifecycle Annotations
/// Control object lifecycle including creation, initialization, and destruction phases.
/// 
/// ### Dependency Injection
/// Declarative dependency injection with autowiring and explicit pod definitions.
/// 
/// ### Configuration
/// Java-style configuration classes and conditional pod registration.
/// 
/// ### Component Stereotypes
/// Mark classes with specific roles in the application architecture.
/// 
/// ## Module Exports
/// 
/// This library exports the following annotation categories:
/// 
/// - [Lifecycle Annotations]: `@PostConstruct`, `@PreDestroy`, `@Lazy`, etc.
/// - [Dependency Injection]: `@Autowired`, `@Qualifier`, `@Value`
/// - [Configuration]: `@Configuration`, `@Pod`, `@Conditional`
/// - [Component Stereotypes]: `@Component`, `@Service`, `@Repository`, `@Controller`
/// - [Pod Annotations]: `@Pod`, `@Primary`, `@Scope`
/// - [Other Annotations]: Miscellaneous utility annotations
/// 
/// ## Core Annotations Deep Dive
/// 
/// ### Lifecycle Management
/// 
/// ```dart
/// @Component
/// class LifecycleDemo {
///   @PostConstruct
///   void initialize() {
///     // Called after dependencies are injected, before the pod is used
///     print('LifecycleDemo initialized and ready for use');
///   }
///   
///   @PreDestroy
///   void cleanup() {
///     // Called when application context is closing, for resource cleanup
///     print('LifecycleDemo cleaning up resources');
///   }
///   
///   @Lazy
///   void expensiveOperation() {
///     // This method might be lazily initialized
///   }
/// }
/// 
/// @Component
/// @Scope('prototype')
/// class PrototypeScopedService {
///   // New instance created every time it's requested
///   int instanceId = DateTime.now().microsecondsSinceEpoch;
/// }
/// ```
/// 
/// ### Dependency Injection
/// 
/// ```dart
/// @Configuration
/// class DependencyConfig {
///   @Pod
///   @Primary
///   DataSource primaryDataSource() {
///     return PrimaryDataSource();
///   }
///   
///   @Pod
///   DataSource backupDataSource() {
///     return BackupDataSource();
///   }
/// }
/// 
/// @Service
/// class UserService {
///   // Constructor injection (preferred)
///   final UserRepository _repository;
///   
///   UserService(this._repository);
///   
///   // Field injection
///   @Autowired
///   late EmailService _emailService;
///   
///   // Setter injection
///   NotificationService? _notificationService;
///   
///   @Autowired
///   set notificationService(NotificationService service) {
///     _notificationService = service;
///   }
///   
///   // Qualified injection when multiple pods of same type exist
///   @Autowired
///   @Qualifier('backupDataSource')
///   late DataSource _backupDataSource;
///   
///   // Value injection from configuration
///   @Value('${app.timeout:5000}')
///   late int timeout;
/// }
/// ```
/// 
/// ### Conditional Configuration
/// 
/// ```dart
/// // Condition based on environment
/// class ProductionCondition implements Condition {
///   @override
///   bool matches(ConditionContext context) {
///     return const bool.fromEnvironment('dart.vm.product') == true;
///   }
/// }
/// 
/// class DevelopmentCondition implements Condition {
///   @override
///   bool matches(ConditionContext context) {
///     return const bool.fromEnvironment('dart.vm.product') == false;
///   }
/// }
/// 
/// // Conditional pod registration
/// @Configuration
/// class ConditionalConfig {
///   @Pod
///   @Conditional(ProductionCondition)
///   DataSource productionDataSource() {
///     return ProductionDataSource();
///   }
///   
///   @Pod
///   @Conditional(DevelopmentCondition)
///   DataSource developmentDataSource() {
///     return DevelopmentDataSource();
///   }
///   
///   @Pod
///   @Profile('cloud')
///   CloudService cloudService() {
///     return AwsCloudService();
///   }
/// }
/// 
/// // Conditional component scanning
/// @Service
/// @Conditional(ProductionCondition)
/// class ProductionOnlyService {
///   // This service only registers in production environment
/// }
/// ```
/// 
/// ### Component Stereotypes
/// 
/// ```dart
/// // Generic component - the base stereotype
/// @Component
/// class GenericComponent {
///   // Base component with no specific architectural role
/// }
/// 
/// // Service layer component - business logic facade
/// @Service
/// class UserService {
///   // Contains business logic, transaction boundaries
///   void createUser(User user) {
///     // Business logic here
///   }
/// }
/// 
/// // Data access component - repository pattern
/// @Repository
/// class UserRepository {
///   // Data access logic, exception translation
///   Future<User?> findById(String id) async {
///     // Data access code
///   }
/// }
/// 
/// // Presentation layer component - web controllers
/// @Controller
/// class UserController {
///   // Handles HTTP requests, input validation
///   @RequestMapping('/users')
///   void getUsers() {
///     // Web request handling
///   }
/// }
/// 
/// // Configuration component - setup and configuration
/// @Configuration
/// @ComponentScan('package:example/app')
/// class AppConfig {
///   // Configuration pods and setup
///   @Pod
///   ObjectMapper objectMapper() => ObjectMapper();
/// }
/// ```
/// 
/// ### Advanced Usage Patterns
/// 
/// ```dart
/// // Composed annotations (meta-annotations)
/// @Service
/// @Transactional
/// @Secure(roles: ['ADMIN'])
/// class AdminService {
///   // Combines multiple concerns in one annotation
/// }
/// 
/// // Custom stereotype annotation
/// @Component
/// class CustomService {
///   const CustomService();
/// }
/// 
/// // Using custom stereotype
/// @CustomService
/// class SpecializedService {
///   // Custom component type with specific behavior
/// }
/// 
/// // Conditional method-level annotations
/// @Service
/// class AdvancedService {
///   @Async
///   @Retryable(maxAttempts: 3)
///   Future<void> unreliableOperation() async {
///     // This method will be executed asynchronously with retry logic
///   }
///   
///   @Scheduled(fixedRate: 5000)
///   void scheduledTask() {
///     // Executed every 5 seconds
///   }
///   
///   @Cacheable('users')
///   User getUser(String id) {
///     // Result will be cached with key 'users'
///   }
/// }
/// ```
/// 
/// ## Configuration Patterns
/// 
/// ### Java-Style Configuration
/// ```dart
/// @Configuration
/// @EnableScheduling
/// @EnableCaching
/// @ComponentScan(['package:example/service', 'package:example/repository'])
/// class RootConfig {
///   @Pod
///   @Primary
///   DataSource dataSource() {
///     return HikariDataSource();
///   }
///   
///   @Pod
///   PlatformTransactionManager transactionManager(DataSource dataSource) {
///     return DataSourceTransactionManager(dataSource);
///   }
/// }
/// ```
/// 
/// ### Annotation-Based Configuration
/// ```dart
/// @Service
/// @Transactional
/// class TransactionalService {
///   // All methods run in transaction context
/// }
/// 
/// @Repository
/// class JdbcRepository {
///   // Exception translation enabled
/// }
/// ```
/// 
/// ### Mixed Configuration
/// ```dart
/// @Configuration
/// @Import({ClassType<DatabaseConfig>(), ClassType<SecurityConfig>()})
/// class AppConfig {
///   // Import other configuration classes
/// }
/// 
/// @Configuration
/// class DatabaseConfig {
///   @Pod
///   DataSource dataSource() {
///     // Database configuration
///   }
/// }
/// ```
/// 
/// ## Best Practices
/// 
/// - Prefer constructor injection for required dependencies
/// - Use field injection for optional dependencies
/// - Leverage `@PostConstruct` for initialization logic, not constructors
/// - Always use `@PreDestroy` for resource cleanup
/// - Use component stereotypes appropriately for architectural clarity
/// - Apply `@Conditional` annotations for environment-specific configurations
/// - Use `@Primary` to resolve ambiguity when multiple pods of same type exist
/// - Leverage `@Qualifier` for explicit pod selection
/// - Consider using `@Lazy` for expensive-to-create pods
/// - Use `@Profile` for deployment environment-specific configurations
/// 
/// ## Integration Patterns
/// 
/// - **Web Applications**: Use `@Controller` for HTTP request handling
/// - **Microservices**: Leverage `@Service` for business logic components
/// - **Data Access**: Use `@Repository` for data access components
/// - **Batch Processing**: Apply `@Component` for batch job steps
/// - **Configuration**: Use `@Configuration` for complex setup scenarios
/// - **Testing**: Utilize `@Profile` for test-specific configurations
/// 
/// ## Performance Considerations
/// 
/// - Use `@Lazy` for pods that are expensive to create but rarely used
/// - Avoid excessive use of `@PostConstruct` with heavy operations
/// - Consider prototype scope for stateful components to avoid threading issues
/// - Use conditional annotations to avoid registering unused pods
/// - Leverage component scanning filters to limit annotation processing
/// - Cache annotation metadata where appropriate for performance
/// 
/// {@endtemplate}
library;

/// Lifecycle management annotations for object initialization and destruction.
export 'src/annotations/lifecycle.dart';

/// Dependency injection annotations for autowiring and qualifiers.
export 'src/annotations/autowired.dart';

/// Configuration annotations for Java-style configuration classes.
export 'src/annotations/configuration.dart' hide CommonConfiguration;

/// Conditional annotations for environment-based pod registration.
export 'src/annotations/conditional.dart';

/// Miscellaneous utility annotations for various purposes.
export 'src/annotations/others.dart';

/// Pod/pod definition and scoping annotations.
export 'src/annotations/pod.dart';

/// Component stereotype annotations for architectural roles.
export 'src/annotations/stereotype.dart';

/// Intercept annotations
export 'src/annotations/intercept.dart';