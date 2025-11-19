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
  Future<Object?> processBeforeInstantiation(Class podClass, String name) async {
    // Only process classes annotated with @ConfigurationProperty
    if (podClass.hasDirectAnnotation<ConfigurationProperty>()) {
      final annotation = podClass.getDirectAnnotation<ConfigurationProperty>()!;
      final prefix = annotation.prefix;
      final ignoreUnknown = annotation.ignoreUnknownFields;
      final validate = annotation.validate;

      // 1. Resolve all property values (recursively)
      // This gathers values for both final (constructor) and late (setter) fields.
      final resolvedValues = await _resolvePropertyValues(podClass, prefix, ignoreUnknown, validate);

      // 2. Try to find a constructor to use
      // We prefer a parameterized constructor if available, especially for final fields.
      final ctor = podClass.getConstructors().find((c) => c.getParameters().isNotEmpty);

      if (ctor != null) {
        // 3. Build arguments from the resolved values
        final args = _buildConstructorArgs(ctor, resolvedValues);

        // 4. Instantiate the pod with the resolved constructor arguments
        final instance = ctor.newInstance(args.named, args.positional);
        
        if (instance != null) {
          // 5. Populate any remaining writable fields (that might not have been in the constructor)
          try {
            _populateFields(instance, podClass, resolvedValues);
          } catch (_) { 
            // Ignore - fields are already set by constructor (final fields)
          }

          return _podFactory.getConversionService().convert(instance, Class.fromQualifiedName(podClass.getQualifiedName()));
        }
      }
    }

    return super.processBeforeInstantiation(podClass, name);
  }

  @override
  Future<void> populateValues(Object pod, Class podClass, String name) async {
    if (!podClass.hasDirectAnnotation<ConfigurationProperty>()) return;

    final annotation = podClass.getDirectAnnotation<ConfigurationProperty>()!;
    final prefix = annotation.prefix;
    final ignoreUnknown = annotation.ignoreUnknownFields;
    final validate = annotation.validate;

    // Resolve properties and populate fields
    // This handles cases where processBeforeInstantiation didn't create the instance
    // (e.g. default constructor was used by the container).
    final resolvedValues = await _resolvePropertyValues(podClass, prefix, ignoreUnknown, validate);
    _populateFields(pod, podClass, resolvedValues);
  }

  /// Resolves all fields of the [targetClass] into a map of values.
  ///
  /// This method handles:
  /// - Direct property resolution from the environment.
  /// - Recursive resolution and instantiation of nested configuration objects.
  /// - Type conversion.
  Future<Map<String, Object?>> _resolvePropertyValues(Class targetClass, String prefix, bool ignoreUnknown, bool validate) async {
    final values = <String, Object?>{};

    for (final field in targetClass.getFields()) {
      final fieldName = field.getName();
      final propertyKey = prefix.isEmpty ? fieldName : '$prefix.$fieldName';
      final fieldType = field.getReturnClass();

      // 1. Try direct property match
      Object? rawValue = _environment.getProperty(propertyKey);

      // 2. Nested configuration
      // If not found and complex type, try to instantiate nested object
      if (rawValue == null && !_isPrimitiveOrEnum(fieldType)) {
        rawValue = await _createNestedInstance(fieldType, propertyKey);
      }

      // 3. Convert and Store
      if (rawValue != null) {
        // If it's a primitive/simple from env, convert it.
        // If it's an object from _createNestedInstance, it's already the right type.
        if (_isPrimitiveOrEnum(fieldType) || rawValue is String) {
          final converted = _podFactory.getConversionService().convert(rawValue, fieldType);
          if (converted != null) {
            values[fieldName] = converted;
          } else if (validate) {
            throw IllegalStateException(
              'Failed to convert environment property "$propertyKey" to type '
              '${fieldType.getSimpleName()} for field $fieldName of ${targetClass.getName()}',
            );
          }
        } else {
          // Already an object (nested instance)
          values[fieldName] = rawValue;
        }
      } else {
        // Handle missing
        if (validate) {
          throw IllegalStateException('Missing required configuration property: "$propertyKey"');
        } else if (!ignoreUnknown) {
          _logger.warn(
            'No environment property found for "$propertyKey" while binding '
            '${targetClass.getName()}.${field.getName()}',
          );
        }
      }
    }

    return values;
  }

  /// Creates and binds a nested configuration object.
  Future<Object?> _createNestedInstance(Class clazz, String prefix) async {
    // Check if the nested class has its own annotation overrides, otherwise default to loose binding
    bool validate = false;
    bool ignoreUnknown = true;
    if (clazz.hasDirectAnnotation<ConfigurationProperty>()) {
      final ann = clazz.getDirectAnnotation<ConfigurationProperty>()!;
      validate = ann.validate;
      ignoreUnknown = ann.ignoreUnknownFields;
    }

    // 1. Resolve values for the nested class (recursively handles deeper nesting)
    final values = await _resolvePropertyValues(clazz, prefix, ignoreUnknown, validate);

    // 2. Determine instantiation strategy
    // Try parameterized constructor first (for final fields), then default
    Constructor? ctor = clazz.getConstructors().find((c) => c.getParameters().isNotEmpty);
    final hasParameterizedConstructor = ctor != null;
    
    ctor ??= clazz.getNoArgConstructor() ?? clazz.getDefaultConstructor();

    if (ctor == null) {
      _logger.error('No suitable constructor found for nested configuration class ${clazz.getName()}');
      return null;
    }

    // 3. Instantiate based on constructor type
    Object? instance;
    
    if (hasParameterizedConstructor) {
      final args = _buildConstructorArgs(ctor, values);
      final result = ctor.newInstance(args.named, args.positional);
      
      // Wrapped in try/catch to gracefully handle final fields
      if (result != null) {
        try {
          _populateFields(result, clazz, values);
        } catch (_) {
          // Ignore - final fields are already set by constructor
        }

        instance = _podFactory.getConversionService().convert(result, Class.fromQualifiedName(clazz.getQualifiedName()));
      }
    } else {
      final result = ctor.newInstance({}, []);
      
      if (result != null) {
        _populateFields(result, clazz, values);
      }

      instance = _podFactory.getConversionService().convert(result, Class.fromQualifiedName(clazz.getQualifiedName()));
    }

    return instance;
  }

  /// Populates writable fields on an [instance] using the [resolvedValues].
  void _populateFields(Object instance, Class clazz, Map<String, Object?> resolvedValues) {
    for (final field in clazz.getFields()) {
      if (!field.isWritable()) continue;

      final name = field.getName();
      if (resolvedValues.containsKey(name)) {
        final value = resolvedValues[name];
        // Ensure type safety before setting
        if (value != null && field.getReturnClass().isInstance(value)) {
          field.setValue(instance, value);
        }
      }
    }
  }

  /// Builds constructor arguments from the resolved values map.
  _ConstructorArguments _buildConstructorArgs(Constructor ctor, Map<String, Object?> values) {
    final args = _ConstructorArguments();

    for (final param in ctor.getParameters()) {
      final name = param.getName();

      // We assume parameter names match field names (standard Dart 'this.field' pattern)
      if (values.containsKey(name)) {
        final val = values[name];
        if (param.isNamed()) {
          args.named[name] = val;
        } else {
          args.positional.insert(param.getIndex(), val);
        }
      } else {
        // If missing, add null for positional to maintain order/count
        if (!param.isNamed()) {
          args.positional.insert(param.getIndex(), null);
        }
      }
    }
    return args;
  }

  /// {@template configuration_property_binder.is_primitive_or_enum}
  /// Determines whether a given class should be treated as a "primitive-like" type
  /// for configuration binding purposes.
  /// {@endtemplate}
  bool _isPrimitiveOrEnum(Class clazz) {
    return clazz.isPrimitive() || clazz.isEnum() || clazz.getName().startsWith('dart.');
  }
}

/// Helper class to hold resolved constructor arguments.
class _ConstructorArguments {
  final Map<String, Object?> named = {};
  final List<Object?> positional = [];
}
