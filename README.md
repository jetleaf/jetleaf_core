# jetleaf_core

🍃 The **core module** of the JetLeaf framework that provides the application context, dependency injection annotations, lifecycle management, event system, and internationalization support.

`jetleaf_core` is the foundation for building JetLeaf applications, integrating pod management, configuration, conditional processing, and application startup orchestration.

- Homepage: https://jetleaf.hapnium.com
- Repository: https://github.com/jetleaf/jetleaf_core
- License: See `LICENSE`

## Contents
- **[Features](#features)**
- **[Install](#install)**
- **[Quick Start](#quick-start)**
- **[Core Concepts](#core-concepts)**
  - **[Application Context](#application-context)**
  - **[Annotations](#annotations)**
  - **[Dependency Injection](#dependency-injection)**
  - **[Conditional Configuration](#conditional-configuration)**
  - **[Lifecycle Management](#lifecycle-management)**
  - **[Event System](#event-system)**
  - **[Message Source (i18n)](#message-source-i18n)**
- **[Usage](#usage)**
  - **[Creating an Application Context](#creating-an-application-context)**
  - **[Configuration Classes](#configuration-classes)**
  - **[Component Scanning](#component-scanning)**
  - **[Dependency Injection](#dependency-injection-1)**
  - **[Conditional Pods](#conditional-pods)**
  - **[Lifecycle Hooks](#lifecycle-hooks)**
  - **[Publishing Events](#publishing-events)**
  - **[Internationalization](#internationalization)**
- **[API Reference](#api-reference)**
- **[Testing](#testing)**
- **[Changelog](#changelog)**
- **[Contributing](#contributing)**
- **[Compatibility](#compatibility)**

## Features
- **Application Context** – Central container for managing application lifecycle, configuration, and pods.
- **Annotations** – Rich set of annotations for configuration, components, dependency injection, and conditional processing.
- **Dependency Injection** – `@Autowired`, `@Value`, `@RequiredAll` for automatic dependency wiring.
- **Configuration** – `@Configuration`, `@AutoConfiguration`, `@Pod` for defining pods and settings.
- **Stereotypes** – `@Component`, `@Service`, `@Repository`, `@Controller` for semantic component roles.
- **Conditional Processing** – `@Conditional`, `@ConditionalOnProperty`, `@ConditionalOnPod`, etc. for environment-specific configuration.
- **Lifecycle Management** – Context lifecycle (refresh, start, stop, close) and pod lifecycle hooks.
- **Event System** – Publish and listen to application events for decoupled communication.
- **Message Source** – Internationalization (i18n) support with locale-based message resolution.
- **Exit Code Management** – Graceful shutdown with exit code generation.

## Install
Add to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_core:
    hosted: https://onepub.dev/api/fahnhnofly/
    version: ^1.0.0
```

Minimum SDK: Dart ^3.9.0

Import:

```dart
import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_core/message.dart';
```

## Quick Start
```dart
import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';

// Define a service
@Service()
class UserService {
  void greet() => print('Hello from UserService!');
}

// Define a configuration
@Configuration()
class AppConfig {
  @Pod()
  Logger createLogger() => Logger('AppLogger');
}

// Create and run the application
void main() async {
  final context = AnnotationConfigApplicationContext([
    Class<AppConfig>(),
    Class<UserService>(),
  ]);

  await context.refresh();

  final userService = await context.getPod<UserService>('userService');
  userService.greet(); // Output: Hello from UserService!

  await context.close();
}
```

## Core Concepts

### Application Context
The `ApplicationContext` is the central interface for a JetLeaf application. It provides:
- **Dependency Injection**: Access to managed pods via `ListablePodFactory` and `HierarchicalPodFactory`
- **Environment Management**: Configuration and profile handling via `EnvironmentCapable`
- **Internationalization**: Message resolution via `MessageSource`
- **Event System**: Application-wide event publication
- **Lifecycle Management**: Context state tracking (active, closed)

Key implementations:
- `GenericApplicationContext` – Basic application context
- `AnnotationConfigApplicationContext` – Annotation-driven context with component scanning
- `AbstractApplicationContext` – Base implementation with lifecycle support

### Annotations
JetLeaf provides a rich set of annotations for declarative configuration:

#### Configuration Annotations
- **`@Configuration`** – Marks a class as a source of pod definitions
- **`@AutoConfiguration`** – Auto-discovered configuration class
- **`@Pod`** – Marks a method as a pod provider (factory method)

#### Stereotype Annotations
- **`@Component`** – Generic component for DI
- **`@Service`** – Business logic layer
- **`@Repository`** – Data access layer
- **`@Controller`** – Presentation/routing layer

#### Dependency Injection Annotations
- **`@Autowired`** – Marks a field for automatic dependency injection
- **`@RequiredAll`** – Auto-injects all eligible fields in a class
- **`@Value`** – Injects property values or pod expressions

#### Conditional Annotations
- **`@Conditional`** – Conditional registration based on custom conditions
- **`@ConditionalOnProperty`** – Conditional based on property values
- **`@ConditionalOnPod`** – Conditional based on pod existence
- **`@ConditionalOnMissingPod`** – Conditional when pod is missing
- **`@ConditionalOnClass`** – Conditional based on class presence

#### Lifecycle Annotations
- **`@PostConstruct`** – Method called after pod initialization
- **`@PreDestroy`** – Method called before pod destruction
- **`@Lazy`** – Lazy initialization of pods
- **`@DependsOn`** – Explicit pod dependency ordering

#### Other Annotations
- **`@Primary`** – Marks a pod as primary when multiple candidates exist
- **`@Qualifier`** – Specifies which pod to inject when multiple candidates exist
- **`@Scope`** – Defines the scope of a pod (singleton, prototype, etc.)
- **`@Order`** – Defines ordering for pods
- **`@Profile`** – Activates pods for specific profiles

### Dependency Injection
JetLeaf supports multiple injection strategies:

**Field Injection**:
```dart
@Service()
class OrderService {
  @Autowired()
  late UserService userService;
}
```

**Constructor Injection** (preferred):
```dart
@Service()
class OrderService {
  final UserService userService;
  
  OrderService(this.userService);
}
```

**Auto-injection**:
```dart
@Service()
@RequiredAll()
class OrderService {
  late UserService userService;       // Auto-injected
  late PaymentService paymentService; // Auto-injected
}
```

**Property Injection**:
```dart
@Component()
class DatabaseService {
  @Value('#{database.url}')
  late String databaseUrl;
  
  @Value('#{database.timeout:30}') // Default value
  late int timeout;
}
```

### Conditional Configuration
Control pod registration based on runtime conditions:

```dart
// Conditional on property
@ConditionalOnProperty(
  prefix: 'server',
  names: ['ssl.enabled'],
  havingValue: 'true',
)
@Configuration()
class SslServerConfig {
  @Pod()
  SslContext sslContext() => SslContext();
}

// Conditional on pod existence
@ConditionalOnPod(DatabaseConnection)
@Service()
class DatabaseMigrationService {
  final DatabaseConnection db;
  DatabaseMigrationService(this.db);
}

// Custom condition
class OnProductionEnvironmentCondition implements Condition {
  @override
  bool matches(ConditionalContext context, ClassType<Object> classType) {
    return context.environment.activeProfiles.contains('production');
  }
}

@Conditional([ClassType<OnProductionEnvironmentCondition>()])
@Configuration()
class ProductionConfig {}
```

### Lifecycle Management
Application contexts have a well-defined lifecycle:

1. **Creation** – Context is instantiated
2. **Refresh** – Pods are loaded, processed, and initialized
3. **Active** – Context is fully operational
4. **Close** – Resources are released, pods are destroyed

```dart
final context = AnnotationConfigApplicationContext([...]);

// Refresh to initialize
await context.refresh();
print(context.isActive()); // true

// Use the context
final service = await context.getPod<MyService>('myService');

// Close when done
await context.close();
print(context.isClosed()); // true
```

### Event System
Publish and listen to application events for decoupled communication:

```dart
// Define an event
class OrderCreatedEvent extends ApplicationEvent {
  final Order order;
  
  OrderCreatedEvent(Object source, this.order) : super(source);
}

// Publish an event
@Service()
class OrderService {
  final ApplicationContext context;
  
  OrderService(this.context);
  
  Future<void> createOrder(OrderRequest request) async {
    final order = await orderRepository.save(request);
    await context.publishEvent(OrderCreatedEvent(this, order));
  }
}

// Listen to events
@Component()
class OrderEventListener implements ApplicationEventListener<OrderCreatedEvent> {
  @override
  Future<void> onApplicationEvent(OrderCreatedEvent event) async {
    await emailService.sendConfirmation(event.order);
  }
}
```

### Message Source (i18n)
Internationalization support with locale-based message resolution:

```dart
final messageSource = ConfigurableMessageSource();

// Simple message
final greeting = messageSource.getMessage('greeting');

// Message with parameters
final welcome = messageSource.getMessage('welcome', args: ['John']);

// Message for specific locale
final bonjour = messageSource.getMessage('greeting', locale: Locale('fr'));
```

## Usage

### Creating an Application Context
```dart
import 'package:jetleaf_core/context.dart';

void main() async {
  // Create context with configuration classes
  final context = AnnotationConfigApplicationContext([
    Class<AppConfig>(),
    Class<DatabaseConfig>(),
  ]);

  // Initialize the context
  await context.refresh();

  // Access context information
  print('Application: ${context.getApplicationName()}');
  print('Context ID: ${context.getId()}');
  print('Start Time: ${context.getStartTime()}');

  // Use the context
  final service = await context.getPod<MyService>('myService');
  await service.doWork();

  // Shutdown
  await context.close();
}
```

### Configuration Classes
```dart
@Configuration()
class DatabaseConfig {
  @Pod()
  DatabaseConnection primaryDatabase() {
    return DatabaseConnection(
      url: 'postgresql://localhost:5432/primary',
      maxConnections: 20,
    );
  }
  
  @Pod('readOnlyDatabase')
  @Scope('prototype')
  DatabaseConnection readOnlyDatabase() {
    return DatabaseConnection(
      url: 'postgresql://localhost:5432/readonly',
      readOnly: true,
    );
  }
}
```

### Component Scanning
```dart
// Auto-discovered components
@Component()
class EmailService {
  final EmailProvider emailProvider;
  
  EmailService(this.emailProvider);
  
  Future<void> sendEmail(String to, String subject, String body) async {
    await emailProvider.send(to: to, subject: subject, body: body);
  }
}

@Service()
class UserService {
  @Autowired()
  late EmailService emailService;
  
  Future<void> registerUser(User user) async {
    await userRepository.save(user);
    await emailService.sendEmail(
      user.email,
      'Welcome!',
      'Welcome to our application!',
    );
  }
}
```

### Dependency Injection
```dart
@Service()
class OrderService {
  final UserService userService;
  final PaymentService paymentService;
  final InventoryService inventoryService;
  
  // Constructor injection (preferred)
  OrderService(
    this.userService,
    this.paymentService,
    this.inventoryService,
  );
  
  Future<Order> createOrder(CreateOrderRequest request) async {
    final user = await userService.findById(request.userId);
    await inventoryService.reserveItems(request.items);
    final payment = await paymentService.processPayment(request.payment);
    
    return Order(
      userId: user.id,
      items: request.items,
      payment: payment,
      createdAt: DateTime.now(),
    );
  }
}
```

### Conditional Pods
```dart
// Only register in development
@ConditionalOnProperty(
  prefix: 'app',
  names: ['debug'],
  havingValue: 'true',
)
@Component()
class DebugLogger {
  void log(String message) => print('[DEBUG] $message');
}

// Only register if Redis is available
@ConditionalOnClass('redis.RedisClient')
@Service()
class RedisCacheService {
  final RedisClient redis;
  
  RedisCacheService(this.redis);
  
  Future<String?> get(String key) => redis.get(key);
}
```

### Lifecycle Hooks
```dart
@Service()
class DatabaseService {
  late DatabaseConnection connection;
  
  @PostConstruct()
  Future<void> initialize() async {
    connection = await DatabaseConnection.connect();
    print('Database connected');
  }
  
  @PreDestroy()
  Future<void> cleanup() async {
    await connection.close();
    print('Database connection closed');
  }
}
```

### Publishing Events
```dart
@Service()
class UserService {
  final ApplicationContext context;
  
  UserService(this.context);
  
  Future<User> createUser(CreateUserRequest request) async {
    final user = await userRepository.save(request);
    
    // Publish domain event
    await context.publishEvent(UserCreatedEvent(this, user));
    
    return user;
  }
}

@Component()
class UserEventListener implements ApplicationEventListener<UserCreatedEvent> {
  @override
  Future<void> onApplicationEvent(UserCreatedEvent event) async {
    print('User created: ${event.user.email}');
    await emailService.sendWelcomeEmail(event.user.email);
  }
}
```

### Internationalization
```dart
@Configuration()
class MessageConfig {
  @Pod()
  MessageSource messageSource() {
    final source = ConfigurableMessageSource();
    source.setBasename('messages');
    return source;
  }
}

// Usage
final messageSource = await context.getPod<MessageSource>('messageSource');

// Get localized messages
final greeting = messageSource.getMessage('greeting');
final welcome = messageSource.getMessage('welcome', args: ['Alice']);
final bonjour = messageSource.getMessage('greeting', locale: Locale('fr'));
```

## API Reference

### Core Exports (`lib/core.dart`)
- **Condition Helpers**: Conditional processing utilities
- **Lifecycle**: Context lifecycle management
- **Aware Interfaces**: `EnvironmentAware`, `ApplicationContextAware`, etc.
- **Exceptions**: `PodException`, `ContextException`
- **Order Comparator**: `AnnotationAwareOrderComparator`

### Context Exports (`lib/context.dart`)
- **Core**: `ApplicationContext`, `GenericApplicationContext`, `AnnotationConfigApplicationContext`
- **Events**: `ApplicationEvent`, `ApplicationEventListener`
- **Exit Code**: `ExitCodeGenerator`, `ExitCodeEvent`
- **Helpers**: Context utilities
- **Module**: `ApplicationModule`
- **Registrar**: `PodRegistrar`

### Annotation Exports (`lib/annotation.dart`)
- **Lifecycle**: `@PostConstruct`, `@PreDestroy`, `@Lazy`, `@DependsOn`
- **Autowired**: `@Autowired`, `@RequiredAll`, `@Value`, `@Qualifier`
- **Configuration**: `@Configuration`, `@AutoConfiguration`, `@Pod`
- **Conditional**: `@Conditional`, `@ConditionalOnProperty`, `@ConditionalOnPod`, etc.
- **Others**: `@Primary`, `@Scope`, `@Order`, `@Profile`
- **Stereotypes**: `@Component`, `@Service`, `@Repository`, `@Controller`

### Message Exports (`lib/message.dart`)
- **MessageSource**: Internationalization interface
- **AbstractMessageSource**: Base implementation
- **ConfigurableMessageSource**: Configurable message source
- **MessageSourceLoader**: Message loading utilities

See `lib/` for the full export list and `lib/src/` for implementation details.

## Testing
Run tests with:

```bash
dart test
```

See `test/` for coverage of context lifecycle, annotations, conditional processing, events, and message resolution.

## Changelog
See `CHANGELOG.md`.

## Contributing
Issues and PRs are welcome at the GitHub repository.

1. Fork and create a feature branch.
2. Add tests for new functionality.
3. Run `dart test` and ensure lints pass.
4. Open a PR with a concise description and examples.

## Compatibility
- Dart SDK: `>=3.9.0 <4.0.0`
- Depends on `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`, `jetleaf_utils`, `jetleaf_env`, `jetleaf_pod` (see `pubspec.yaml`).

---

Built with 🍃 by the JetLeaf team.
