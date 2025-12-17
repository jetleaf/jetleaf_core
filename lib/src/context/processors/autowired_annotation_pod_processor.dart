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
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../../annotations/autowired.dart';
import '../../annotations/others.dart';
import '../../aware.dart';
import '../base/application_context.dart';

/// {@template jetleaf_class_AutowiredAnnotationPodProcessor}
/// A Pod processor in Jetleaf that handles dependency injection
/// through the `@Autowired`, `@Value`, and `@RequiredAll` annotations.
///
/// This processor automatically inspects a Pod's fields at instantiation
/// time and injects the required dependencies or values:
///
/// - `@Autowired` → Injects a dependency from the Jetleaf container.
/// - `@Value` → Injects a configuration/environment value, with type conversion.
/// - `@RequiredAll` → Ensures all non-primitive fields are automatically resolved.
///
/// ### Example
/// ```dart
/// class DatabaseService {
///   final String url;
///
///   DatabaseService(this.url);
/// }
///
/// class MyService {
///   @Autowired
///   late DatabaseService db;
///
///   @Value('service.timeout')
///   late int timeout;
/// }
///
/// // Inside Jetleaf
/// final factory = ConfigurableListablePodFactory();
/// final processor = AutowiredAnnotationPodProcessor(factory);
///
/// // When the Pod is created, Jetleaf will:
/// // - Inject DatabaseService into `db`
/// // - Resolve the config value "service.timeout" into `timeout`
/// ```
///
/// ### When to use
/// - If you want to **declaratively inject dependencies** using annotations.
/// - If you want to **inject configuration values** into Pods.
/// - If you need **automatic field population** without writing boilerplate code.
///
/// This class is part of **Jetleaf** – a framework developers can use
/// to build web applications.
/// {@endtemplate}
class AutowiredAnnotationPodProcessor extends PodSmartInstantiationProcessor implements PodFactoryAware, ApplicationContextAware, PriorityOrdered {
  /// The [ConfigurableListablePodFactory] used to resolve dependencies
  /// and configuration values for fields annotated with `@Autowired` or `@Value`.
  late final ConfigurableListablePodFactory _podFactory;

  /// The [ApplicationContext] used to resolve dependencies and configuration values.
  late final ApplicationContext _applicationContext;

  /// Logger instance for this class.
  final Log _logger = LogFactory.getLog(AutowiredAnnotationPodProcessor);

  /// Creates a new processor that uses the given [podFactory]
  /// to inject dependencies and values into Pods.
  ///
  /// Typically registered inside the Jetleaf application context.
  ///
  /// {@macro jetleaf_class_AutowiredAnnotationPodProcessor}
  AutowiredAnnotationPodProcessor();

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE;

  @override
  void setPodFactory(PodFactory podFactory) {
    if (podFactory is ConfigurableListablePodFactory) {
      _podFactory = podFactory;
    }
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  Future<List<ArgumentValue>?> determineCandidateArguments(String podName, Executable executable, List<Parameter> parameters) async {
    List<ArgumentValue> args = [];

    for (final param in parameters) {
      final paramClass = param.getReturnClass();
      final classContent = _getClassContent(paramClass);

      if (param.hasDirectAnnotation<Qualifier>()) {
        final qualifier = param.getDirectAnnotation<Qualifier>();

        final dep = await _podFactory.resolveDependency(
          DependencyDescriptor(
            source: paramClass,
            podName: podName,
            propertyName: param.getName(),
            type: paramClass,
            args: null,
            component: classContent.component ?? paramClass.componentType(),
            key: classContent.key ?? paramClass.keyType(),
            isEager: true,
            isRequired: param.isRequired(),
            lookup: qualifier?.value,
          ),
        );
        
        args.add(
          ArgumentValue(
            dep,
            qualifiedName: paramClass.getQualifiedName(),
            packageName: paramClass.getPackage()?.getName(),
            name: param.getName(),
          ),
        );
      }

      if (executable is Constructor) {
        //
      } else if (executable is Method) {
        //
      }
    }

    return args.isEmpty ? null : args;
  }

  @override
  Future<void> populateValues(Object pod, Class podClass, String name) async {
    // Process fields
    for (final field in podClass.getFields()) {
      bool hasAutowired = field.hasDirectAnnotation<Autowired>();
      bool hasValue = field.hasDirectAnnotation<Value>();
      bool hasEnv = field.hasDirectAnnotation<Env>();

      if (field.isWritable() && (hasAutowired || hasValue || hasEnv)) {
        final fieldClass = field.getReturnClass();

        if (fieldClass.isPrimitive() && hasAutowired) {
          continue;
        }

        // Skip already initialized fields (set by constructor or factory)
        try {
          final currentValue = field.getValue(pod);
          if (currentValue != null) {
            if (_logger.getIsTraceEnabled()) {}

            continue;
          }
        } catch (_) {}

        // Handle @Autowired annotation
        if (hasAutowired) {
          final dependency = await _processAutowiredAnnotation(field, pod, name, podClass);

          if (dependency != null && fieldClass.isInstance(dependency)) {
            field.setValue(pod, dependency);
          }

          continue;
        }

        // Handle @Env annotation
        if (hasEnv) {
          final env = await _processEnvAnnotation(field, pod, name, podClass);

          if (env != null && fieldClass.isInstance(env)) {
            field.setValue(pod, env);
            continue;
          }
        }

        // Handle @Value annotation
        if (hasValue) {
          final value = await _processValueAnnotation(field, pod, name, podClass);
          if (value != null && fieldClass.isInstance(value)) {
            field.setValue(pod, value);
            continue;
          }
        }
      } else {
        continue;
      }
    }

    // Handle @RequiredAll annotation
    if (podClass.hasDirectAnnotation<RequiredAll>()) {
      for (final field in podClass.getFields()) {
        if (field.hasDirectAnnotation<AutowiredIgnore>()) {
          continue;
        }

        final fieldClass = field.getReturnClass();

        if (!field.isWritable() || fieldClass.isPrimitive()) {
          continue;
        }

        final dependency = await _processAutowiredAnnotation(field, pod, name, podClass);
        if (dependency != null && fieldClass.isInstance(dependency)) {
          field.setValue(pod, dependency);
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // @Autowired Processing
  // ─────────────────────────────────────────────────────────────

  /// {@template process_autowired_annotation}
  /// Processes an [`@Autowired`] annotation declared on a [Field]
  /// or [Parameter] and resolves its dependency via the Jetleaf
  /// container.
  ///
  /// ### Behavior
  /// - If the element declares a [`@Qualifier`], resolution will be
  ///   attempted by the specified qualifier value.
  /// - If no qualifier is present, resolution proceeds by **type**.
  /// - The required-ness of the dependency is inferred from:
  ///   - Field nullability (`!source.isNullable()`)
  ///   - Parameter requirement (`(source as Parameter).isRequired()`)
  ///
  /// ### Returns
  /// A resolved dependency instance or `null` if none could be
  /// provided.
  ///
  /// ### Example
  /// ```dart
  /// @Autowired
  /// late DataSource dataSource;
  ///
  /// // Internally resolved as:
  /// final ds = await _processAutowiredAnnotation(field, pod, 'myPod', podClass);
  /// ```
  ///
  /// ### Throws
  /// - [PodException] if the required dependency cannot be resolved.
  /// {@endtemplate}
  Future<Object?> _processAutowiredAnnotation(Source source, Object pod, String name, Class podClass) async {
    final classContent = _getClassContent(source);
    final cls = source is Field ? source.getReturnClass() : (source as Parameter).getReturnClass();

    Qualifier? qualifier;
    if (source.hasDirectAnnotation<Qualifier>()) {
      qualifier = source.getDirectAnnotation<Qualifier>();
    }

    Object? dependency;

    if (qualifier != null) {
      dependency = await _podFactory.resolveDependency(
        DependencyDescriptor(
          source: source,
          podName: name,
          propertyName: qualifier.value,
          type: cls,
          args: null,
          component: classContent.component,
          key: classContent.key,
          isEager: true,
          isRequired: source is Field ? !source.isNullable() : (source as Parameter).isRequired(),
          lookup: qualifier.value,
        ),
      );
    } else {
      dependency = await _podFactory.resolveDependency(
        DependencyDescriptor(
          source: source,
          podName: name,
          propertyName: source.getName(),
          type: cls,
          args: null,
          component: classContent.component,
          key: classContent.key,
          isEager: true,
          isRequired: source is Field  ? !source.isNullable() : (source as Parameter).isRequired(),
        ),
      );
    }

    return dependency;
  }

  // ─────────────────────────────────────────────────────────────
  // Internal Class Content Extraction
  // ─────────────────────────────────────────────────────────────

  /// {@template get_class_content}
  /// Extracts type metadata for a given [Source], such as component and key
  /// classes specified by annotations like [`@TargetType`] or [`@KeyValueOf`].
  ///
  /// ### Returns
  /// An immutable [_ClassContent] record containing:
  /// - The component type (if [`@TargetType`] or [`@KeyValueOf.value`])
  /// - The key type (if [`@KeyValueOf.key`])
  ///
  /// ### Example
  /// ```dart
  /// final meta = _getClassContent(field);
  /// print(meta.component?.getName()); // e.g. "UserService"
  /// ```
  /// {@endtemplate}
  _ClassContent _getClassContent(Source source) {
    Class? component;
    if (source.hasDirectAnnotation<TargetType>()) {
      component = source.getDirectAnnotation<TargetType>()?.get();
    }

    if (source.hasDirectAnnotation<KeyValueOf>()) {
      component ??= source.getDirectAnnotation<KeyValueOf>()?.getValue();
    }

    Class? key;
    if (source.hasDirectAnnotation<KeyValueOf>()) {
      key = source.getDirectAnnotation<KeyValueOf>()?.getKey();
    }

    return _ClassContent(component, key);
  }

  // ─────────────────────────────────────────────────────────────
  // @Env Processing
  // ─────────────────────────────────────────────────────────────

  /// {@template process_env_annotation}
  /// Processes an [`@Env`] annotation on a [Field] or [Parameter],
  /// resolving environment variables or configuration properties.
  ///
  /// ### Behavior
  /// - Extracts the annotation value.
  /// - Converts it to the target field/parameter type using the
  ///   [ConversionService] from the pod factory.
  ///
  /// ### Returns
  /// The converted environment value, or `null` if the annotation
  /// is not present.
  ///
  /// ### Example
  /// ```dart
  /// @Env('APP_PORT')
  /// late int port;
  /// ```
  ///
  /// {@endtemplate}
  Future<Object?> _processEnvAnnotation(Source source, Object pod, String name, Class podClass) async {
    final value = source.getDirectAnnotation<Env>()?.value();
    final cls = source is Field ? source.getReturnClass() : (source as Parameter).getReturnClass();
    return _podFactory.getConversionService().convert(value, cls);
  }

  // ─────────────────────────────────────────────────────────────
  // @Value Processing
  // ─────────────────────────────────────────────────────────────

  /// {@template process_value_annotation}
  /// Handles resolution of [`@Value`] annotations for field or parameter
  /// injection, supporting literal values, environment placeholders,
  /// pod references, and expression evaluations.
  ///
  /// ### Supported Syntax
  /// - `#{...}` — Environment placeholder expressions
  /// - `@{...}` — Pod reference expressions
  /// - `&{...}` — Pod expression evaluations
  ///
  /// ### Behavior
  /// 1. Resolves placeholders via the environment.
  /// 2. Resolves pods via container lookups.
  /// 3. Evaluates expressions via the pod expression resolver.
  /// 4. Converts the final result to the target type via the
  ///    [ConversionService].
  ///
  /// ### Throws
  /// - [IllegalArgumentException] if a placeholder cannot be resolved.
  ///
  /// ### Example
  /// ```dart
  /// @Value('#{app.datasource.url}')
  /// late String dataSourceUrl;
  /// ```
  /// {@endtemplate}
  Future<Object?> _processValueAnnotation(Source source, Object pod, String name, Class podClass) async {
    Scope? scope;
    if (podClass.hasDirectAnnotation<Scope>()) {
      scope = podClass.getAnnotation<Scope>();
    }

    final definition = _podFactory.containsDefinition(name) ? _podFactory.getDefinition(name) : null;
    final scopeValue = scope?.value ?? definition?.scope.type;
    final ps = scopeValue != null ? _podFactory.getRegisteredScope(scopeValue) : null;
    final value = source.getDirectAnnotation<Value>()?.value;
    final cls = source is Field ? source.getReturnClass() : (source as Parameter).getReturnClass();

    Object? resolved;
    final env = _applicationContext.getEnvironment();

    if (value is String && value.startsWith('@{') && value.endsWith('}')) {
      // Handle pod values
      final podName = value.substring(2, value.length - 1);
      resolved = await _podFactory.resolveDependency(
        DependencyDescriptor(
          source: source,
          podName: name,
          propertyName: podName,
          type: cls,
          args: null,
          component: cls.componentType(),
          key: cls.keyType(),
          isEager: true,
          isRequired: source is Field ? !source.isNullable() : (source as Parameter).isRequired(),
          lookup: podName,
        ),
      );
    } else if (value is String && value.startsWith('&{') && value.endsWith('}')) {
      // Handle pod expressions
      final result = await _podFactory.getPodExpressionResolver()?.evaluate(value, PodExpressionContext(_podFactory, ps));

      if (result != null) {
        resolved = _podFactory.getConversionService().convert(result.getValue(), cls);
      }
    } else if (value is! String) {
      // Handle custom pod expressions
      final result = await _podFactory.getPodExpressionResolver()?.evaluate(value, PodExpressionContext(_podFactory, ps));

      if (result != null) {
        resolved = _podFactory.getConversionService().convert(result.getValue(), cls);
      }
    } else {
      // Handle environment values
      String result = env.resolvePlaceholders(value);

      if (result.equals(value)) {
        result = env.resolvePlaceholders(value.replaceAll("#{", "\${"));
      }

      if (result.equals(value)) {
        throw IllegalArgumentException('''
Failed to resolve environment placeholder: "$value".

JetLeaf attempted to resolve this value from:
• active profiles: ${env.getActiveProfiles()}
• suggestions: ${env.suggestions(value).join(", ")}

But no matching property or environment variable was found.

👉 To fix this:
- Ensure "$value" is defined in your configuration files (e.g., application.yaml, application.properties).
- Or export it as an environment variable before running your application.
- If this placeholder is optional, consider using a default: #{value:defaultValue}.
''');
      }

      resolved = _podFactory.getConversionService().convert(result, cls);
    }

    return resolved;
  }
}

/// {@template class_content}
/// Internal record representing extracted type metadata for a [Source].
///
/// Contains both component and key types derived from annotations like
/// [`@TargetType`] or [`@KeyValueOf`].
/// {@endtemplate}
final class _ClassContent {
  /// Component type (from `@TargetType` or `@KeyValueOf.value`)
  final Class? component;

  /// Key type (from `@KeyValueOf.key`)
  final Class? key;

  /// {@macro class_content}
  _ClassContent(this.component, this.key);
}