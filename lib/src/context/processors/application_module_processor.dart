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
import '../application_context.dart';
import '../application_module.dart';
import '../helpers.dart';

/// {@template jetleaf_class_ApplicationModuleProcessor}
/// A **post-processor** in Jetleaf responsible for discovering and
/// initializing [ApplicationModule]s within the application context.
///
/// This processor ensures that all modules are detected, instantiated,
/// and invoked to register their components with the running
/// [ApplicationContext]. It supports multiple construction patterns
/// for modules, including:
///
/// - **No-argument constructor**: Modules that can be created without
///   additional context or environment.
/// - **Parameterized constructor**: Modules that depend on
///   [Environment] or [ApplicationContext].
/// - **Pod-registered modules**: Modules defined and registered as pods
///   in the [PodFactory].
///
/// ### Responsibilities
/// - Discover subclasses of [ApplicationModule] via reflection.
/// - Instantiate modules using available constructors.
/// - Resolve dependencies ([Environment], [ApplicationContext]) if required.
/// - Load and configure module instances declared as pods.
/// - Execute [ApplicationModule.configure] for each discovered module.
///
/// ### Example
/// ```dart
/// final processor = ApplicationModuleProcessor();
/// processor.setApplicationContext(myAppContext);
/// await processor.postProcessFactory(myPodFactory);
///
/// // At this point, all modules are discovered, instantiated,
/// // and have configured themselves into the context.
/// ```
/// {@endtemplate}
final class ApplicationModuleProcessor implements PodFactoryPostProcessor, ApplicationContextAware, PriorityOrdered {
  /// {@template amp_application_context}
  /// Reference to the active [ApplicationContext].
  ///
  /// This context is provided via [setApplicationContext] and is used
  /// to supply module constructors with dependencies and to pass into
  /// [ApplicationModule.configure].
  /// {@endtemplate}
  late ApplicationContext _applicationContext;

  /// ${@macro jetleaf_class_ApplicationModuleProcessor}
  ApplicationModuleProcessor();

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE + 1;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    final classes = Class<ApplicationModule>(null, PackageNames.CORE).getSubClasses();
    final sources = <ApplicationModule>{};
    final sourceClasses = <Class>{};

    // Discover ApplicationModule instances registered as pods
    final names = await podFactory.getPodNames(Class<ApplicationModule>(null, PackageNames.CORE));
    for (final name in names) {
      final pod = await podFactory.getPod(name);
      final cls = await podFactory.getPodClass(name);

      sourceClasses.add(cls);
      sources.add(pod);
    }

    // Instantiate discovered ApplicationModule classes
    for (final cls in classes) {
      if (sourceClasses.any((s) => s.getQualifiedName().equals(cls.getQualifiedName()))) {
        continue;
      }

      final defc = cls.getNoArgConstructor();
      if (defc != null) {
        final source = defc.newInstance();

        if (!sources.any((s) => s == source)) {
          sources.add(source);
        }
      } else {
        final construct = cls.getBestConstructor([
          Class<Environment>(null, PackageNames.ENV),
          Class<ApplicationContext>(null, PackageNames.CORE),
        ]);

        final env = _applicationContext.getEnvironment();

        if (construct != null) {
          final source = construct.newInstance(
            construct.getParameters().toMap(
              (p) => p.getName(),
              (p) => p.getClass().isAssignableTo(Class<Environment>(null, PackageNames.ENV))
                ? env
                : _applicationContext,
            ),
            [env, _applicationContext],
          );

          if (!sources.any((s) => s == source)) {
            sources.add(source);
          }
        }
      }
    }

    // Configure all collected modules
    for (final source in sources) {
      source.configure(_applicationContext);
    }
  }
}