// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// ConfigurationPropertyPodProcessor — supports nested property binding.
// ---------------------------------------------------------------------------

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../../annotations/configuration.dart';
import '../../aware.dart';

/// {@template configuration_property_pod_processor}
/// A specialized JetLeaf [PodSmartInstantiationProcessor] that binds environment
/// configuration values into pods annotated with [`@ConfigurationProperty`].
///
/// The [ConfigurationPropertyPodProcessor] enables **declarative configuration
/// binding** directly into strongly typed objects, supporting:
///
/// - **Nested object binding**: Automatically instantiates and populates nested
///   configuration classes recursively, allowing rich, hierarchical property
///   structures (e.g., `server.datasource.url` → `Server.datasource.url`).
/// - **Type-safe conversion**: Uses the JetLeaf conversion service from the
///   [ConfigurableListablePodFactory] to coerce string values into the correct
///   target types (e.g., `int`, `bool`, enums, or custom types).
/// - **Validation and error reporting**: Enforces property presence and type
///   correctness when `validate = true` is specified in the annotation.
/// - **Unknown property control**: Optionally ignores missing keys or logs
///   warnings based on `ignoreUnknownFields`.
///
/// ### Example
/// ```dart
/// @ConfigurationProperty(prefix: 'server', validate: true)
/// class ServerProperties {
///   late String host;
///   late int port;
///   SecurityProperties security = SecurityProperties();
/// }
///
/// @ConfigurationProperty(prefix: 'server.security')
/// class SecurityProperties {
///   late bool enabled;
///   late String mode;
/// }
/// ```
///
/// With environment variables:
/// ```properties
/// server.host=localhost
/// server.port=8080
/// server.security.enabled=true
/// server.security.mode=STRICT
/// ```
///
/// JetLeaf will automatically bind these into an instance of
/// `ServerProperties`, including its nested `SecurityProperties`.
///
/// {@endtemplate}
class ConfigurationPropertyPodProcessor extends PodSmartInstantiationProcessor implements EnvironmentAware, PodFactoryAware, PriorityOrdered {
  /// The logger instance for this processor, used for diagnostics
  /// and property binding warnings.
  ///
  /// All warnings and errors related to configuration resolution or
  /// nested instantiation failures are routed through this logger.
  final Log _logger = LogFactory.getLog(ConfigurationPropertyPodProcessor);

  /// The active [Environment] from which configuration properties
  /// are resolved and mapped into annotated pod fields.
  ///
  /// This is injected automatically via [setEnvironment] by the
  /// JetLeaf context during initialization.
  late Environment _environment;

  /// The active [ConfigurableListablePodFactory] used to access
  /// conversion services and metadata during property binding.
  ///
  /// Set internally through [setPodFactory] and required for
  /// performing type conversion when assigning values.
  late ConfigurableListablePodFactory _podFactory;

  /// Creates a new [ConfigurationPropertyPodProcessor].
  ///
  /// This constructor initializes the processor for integration
  /// into the JetLeaf pod lifecycle. It does not perform any
  /// property binding until invoked by the [PodSmartInstantiationProcessor]
  /// contract during pod creation.
  /// 
  /// {@macro configuration_property_pod_processor}
  ConfigurationPropertyPodProcessor();

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  @override
  void setPodFactory(PodFactory podFactory) {
    if (podFactory is ConfigurableListablePodFactory) {
      _podFactory = podFactory;
    }
  }

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE - 20;

  @override
  Future<void> populateValues(Object pod, Class podClass, String name) async {
    if (!podClass.hasDirectAnnotation<ConfigurationProperty>()) return;

    final annotation = podClass.getDirectAnnotation<ConfigurationProperty>()!;
    final prefix = annotation.prefix;
    final ignoreUnknown = annotation.ignoreUnknownFields;
    final validate = annotation.validate;

    await _bindProperties(pod, podClass, prefix, ignoreUnknown, validate);
  }

  /// {@template configuration_property_binder.bind_properties}
  /// Recursively binds environment properties to the fields of a target object.
  ///
  /// This method performs **property-to-field mapping** based on the given [prefix],
  /// using metadata from the provided [targetClass].
  ///
  /// ### Binding process
  ///
  /// For each writable field in [targetClass]:
  ///
  /// 1. **Determine property key**  
  ///    Builds a property key by concatenating the [prefix] and the field name,
  ///    e.g. `server.port` for a field named `port` within a `server`-prefixed pod.
  ///
  /// 2. **Resolve property value**  
  ///    Attempts to fetch a raw value from the environment using
  ///    `_environment.getProperty(propertyKey)`.
  ///
  /// 3. **Nested binding**  
  ///    If no direct value is found and the field’s type is complex (i.e. not a
  ///    primitive or enum), a new instance is created (via
  ///    [_instantiateNested]) and recursively bound by calling
  ///    `_bindProperties` again with the nested [fieldType] and updated prefix.
  ///
  /// 4. **Type conversion**  
  ///    When a raw value is found, the method delegates to the conversion service
  ///    (`_podFactory.getConversionService()`) to convert it to the field’s target type.
  ///    If conversion succeeds, the value is assigned via reflection.
  ///
  /// 5. **Validation and error handling**
  ///    - If conversion fails and [validate] is `true`, an [IllegalStateException] is thrown.
  ///    - If no property is found and [validate] is `true`, an [IllegalStateException] is thrown.
  ///    - If [ignoreUnknown] is `false`, a warning is logged for missing properties.
  ///
  /// ### Parameters
  ///
  /// - **[target]** — The instance whose fields should be populated with configuration values.  
  /// - **[targetClass]** — Reflection metadata representing the class of [target]; used to access fields and types.  
  /// - **[prefix]** — The current configuration key prefix (e.g. `"server"` or `"datasource.primary"`).  
  /// - **[ignoreUnknown]** — If `true`, unknown or missing properties are silently skipped.  
  /// - **[validate]** — If `true`, missing or invalid values result in thrown exceptions.
  ///
  /// ### Notes
  ///
  /// - Uses reflection to inspect fields and determine writability.
  /// - Invokes conversion through the framework’s configured [ConversionService].
  /// - Supports recursive binding of nested configuration objects.
  /// - Logs missing or invalid keys using the framework’s logger.
  ///
  /// This method is **internal** and typically invoked by the
  /// `ConfigurationPropertyAnnotationProcessor` during the application
  /// context’s refresh or bootstrap phase.
  /// {@endtemplate}
  Future<void> _bindProperties(Object target, Class targetClass, String prefix, bool ignoreUnknown, bool validate) async {
    for (final field in targetClass.getFields()) {
      if (!field.isWritable()) continue;

      final fieldType = field.getReturnClass();
      final propertyKey =
          prefix.isEmpty ? field.getName() : '$prefix.${field.getName()}';

      // Try direct property match
      final rawValue = _environment.getProperty(propertyKey);

      // If not found, and the field type is a complex (non-primitive) class,
      // recursively bind nested properties.
      if (rawValue == null && !_isPrimitiveOrEnum(fieldType)) {
        final nestedInstance = field.getValue(target) ?? await _instantiateNested(fieldType, propertyKey);

        if (nestedInstance != null) {
          await _bindProperties(nestedInstance, fieldType, propertyKey, ignoreUnknown, validate);
          field.setValue(target, nestedInstance);
        }

        continue;
      }

      // Handle primitive or directly resolvable types
      if (rawValue != null) {
        final converted = _podFactory.getConversionService().convert(rawValue, fieldType);

        if (converted != null && fieldType.isInstance(converted)) {
          field.setValue(target, converted);
        } else if (validate) {
          throw IllegalStateException(
            'Failed to convert property "$propertyKey" value "$rawValue" '
            'to type ${fieldType.getSimpleName()} for '
            '${targetClass.getName()}.${field.getName()}',
          );
        }
      } else if (validate) {
        throw IllegalStateException('Missing required configuration property: "$propertyKey"');
      } else if (!ignoreUnknown) {
        _logger.warn(
          'No environment property found for "$propertyKey" while binding '
          '${targetClass.getName()}.${field.getName()}',
        );
      }
    }
  }

  /// {@template configuration_property_binder.is_primitive_or_enum}
  /// Determines whether a given class should be treated as a "primitive-like" type
  /// for configuration binding purposes.
  ///
  /// Returns `true` if:
  /// - [clazz] is a primitive type (int, double, bool, etc.)
  /// - [clazz] is an enum type
  /// - [clazz] is a core Dart type (its fully-qualified name starts with `dart.`)
  ///
  /// This method is used by `_bindProperties` to decide whether to recursively
  /// bind nested properties or handle the field as a simple value.
  /// {@endtemplate}
  bool _isPrimitiveOrEnum(Class clazz) {
    return clazz.isPrimitive() || clazz.isEnum() || clazz.getName().startsWith('dart.');
  }

  /// {@template configuration_property_binder.instantiate_nested}
  /// Attempts to create a new instance of a nested configuration class for
  /// recursive property binding.
  ///
  /// The method tries, in order:
  /// 1. A no-argument constructor via `getNoArgConstructor()`.
  /// 2. A default constructor via `getDefaultConstructor()`.
  /// 3. Any constructor with zero parameters.
  ///
  /// If no suitable constructor is found, throws [IllegalStateException] with
  /// the fully-qualified class name and property key for easier debugging.
  ///
  /// If instantiation fails for any reason, logs an error via `_logger` and
  /// returns `null`.
  ///
  /// ### Parameters
  /// - **[clazz]** — The class type to instantiate.
  /// - **[propertyKey]** — The full property key associated with this nested object
  ///   (used for error messages and logging).
  ///
  /// ### Returns
  /// A new instance of the class if instantiation succeeds, otherwise `null`.
  /// {@endtemplate}
  Future<Object?> _instantiateNested(Class clazz, String propertyKey) async {
    try {
      final ctor = clazz.getNoArgConstructor() ?? clazz.getDefaultConstructor() ?? clazz.getConstructors().firstWhere(
        (c) => c.getParameters().isEmpty,
        orElse: () => throw IllegalStateException(
          'No default constructor found for nested configuration class '
          '${clazz.getName()} (property: $propertyKey)',
        ),
      );

      return ctor.newInstance();
    } catch (e) {
      _logger.error(
        'Failed to instantiate nested configuration class: ${clazz.getName()}',
        error: e,
      );
      return null;
    }
  }
}
