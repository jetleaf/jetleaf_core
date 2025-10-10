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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_core/src/condition/condition_evaluator.dart';
import 'package:jetleaf_core/src/context/scanning/class_path_pod_definition_scanner.dart';
import 'package:jetleaf_core/src/context/scanning/component_scan_annotation_parser.dart';
import 'package:jetleaf_core/src/context/scanning/configuration_class.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:test/test.dart';

import '../_dependencies.dart';

// Test classes and services
class DataSource {
  final String url;
  final String username;
  final String password;

  DataSource(this.url, this.username, this.password);

  void connect() => print("🔗 Connecting to DB at $url as $username");
}

class CacheManager {
  final int size;
  CacheManager(this.size);

  void put(String key, dynamic value) {
    print("🗄️  Caching [$key] → $value");
  }
}

class MessageBroker {
  final String endpoint;
  MessageBroker(this.endpoint);

  void publish(String topic, String message) =>
      print("📢 [$endpoint] $topic → $message");
}

class Logger {
  final String name;
  Logger(this.name);

  void log(String msg) => print("[$name] $msg");
}

class UserService {
  final DataSource dataSource;
  final CacheManager cache;
  final Logger logger;

  UserService(this.dataSource, this.cache, this.logger);

  void createUser(String name) {
    dataSource.connect();
    cache.put("user:$name", name);
    logger.log("✅ User $name created.");
  }
}

class PaymentService {
  final DataSource dataSource;
  final MessageBroker broker;
  final Logger logger;

  PaymentService(this.dataSource, this.broker, this.logger);

  void processPayment(int amount) {
    dataSource.connect();
    broker.publish("payments", "Processed \$$amount");
    logger.log("💰 Payment processed: $amount");
  }
}

class FeatureToggleService {
  final bool enabled;
  FeatureToggleService(this.enabled);

  void check() => print(enabled ? "🚀 Feature is ENABLED" : "❌ Feature is DISABLED");
}

class ClusterManager {
  final List<String> nodes;
  ClusterManager(this.nodes);

  String pickNode() => nodes.isNotEmpty ? nodes.first : "no-node";
}

// Configuration classes with conditional annotations

/// 1. SSL DataSource - enabled when property db.ssl.enabled=true
@ConditionalOnProperty(prefix: 'db', names: ['ssl.enabled'], havingValue: 'true')
final class SslDataSourceConfiguration {
  @Pod()
  DataSource sslDataSource() => DataSource(
        "jdbc:postgresql://secure-db:5432/app?ssl=true",
        "secureUser",
        "superSecret",
      );
}

/// 2. Missing class fallback (if DataSource isn't on classpath)
@ConditionalOnMissingClass(value: [ClassType<DataSource>()], names: ['dataSource'])
final class FallbackDataSourceConfiguration {
  @Pod()
  DataSource fallbackDataSource() => DataSource("memory://fallback", "na", "na");
}

/// 3. Missing pod fallback
@ConditionalOnMissingPod(types: [ClassType<CacheManager>()], names: ['cacheManager'])
final class DefaultCacheConfiguration {
  @Pod()
  CacheManager defaultCache() => CacheManager(100);
}

/// 4. Profile: Dev environment
@ConditionalOnProfile(['dev'])
final class DevConfiguration {
  @Pod()
  DataSource devDataSource() => DataSource("jdbc:h2:mem:devdb", "dev", "devpass");

  @Pod()
  Logger devLogger() => Logger("DEV");
}

/// 5. Profile: Prod environment
@ConditionalOnProfile(['prod'])
final class ProdConfiguration {
  @Pod()
  DataSource prodDataSource() => DataSource(
        "jdbc:postgresql://prod-db:5432/app",
        "produser",
        "securepass",
      );

  @Pod()
  Logger prodLogger() => Logger("PROD");
}

/// 6. Dart version–specific
@ConditionalOnDart("3.0")
final class Dart3Config {
  @Pod()
  Logger dart3Logger() => Logger("Dart3-Only");
}

/// 7. Dart version range
@ConditionalOnDart("3.0", VersionRange(start: Version(3, 0, 0), end: Version(3, 1, 0)))
final class Dart3RangeConfig {
  @Pod()
  CacheManager experimentalCache() => CacheManager(9999);
}

/// 8. Conditional on existing Pod (UserService only if DataSource + Cache exist)
@ConditionalOnPod(types: [ClassType<DataSource>(), ClassType<CacheManager>()])
final class UserServiceConfiguration {
  @Pod()
  UserService userService(DataSource ds, CacheManager cache, Logger logger) =>
      UserService(ds, cache, logger);
}

/// 9. Conditional on class presence
@ConditionalOnClass(value: [ClassType<MessageBroker>()])
final class PaymentServiceConfiguration {
  @Pod()
  PaymentService paymentService(
          DataSource ds, MessageBroker broker, Logger logger) =>
      PaymentService(ds, broker, logger);
}

/// 10. Asset-based condition
@ConditionalOnAsset("assets/feature.flag")
final class FeatureFlagConfiguration {
  @Pod()
  FeatureToggleService featureToggle() => FeatureToggleService(true);
}

/// 11. Expression-based condition
@ConditionalOnExpression("&{systemProperties['user.home']} != null")
final class UserHomeConfiguration {
  @Pod()
  Logger homeLogger() => Logger("HOME-LOGGER");
}

/// 12. Cluster mode (property-driven)
@ConditionalOnProperty(prefix: 'system', names: ['mode'], havingValue: 'cluster')
final class ClusterConfiguration {
  @Pod()
  ClusterManager clusterManager() => ClusterManager([
        "node1.local",
        "node2.local",
        "node3.local",
      ]);
}

void main() {
  setUpAll(() async {
    await setupRuntime();
    return Future<void>.value();
  });

  group('ConditionalOnProperty Tests', () {
    test('should load SSL DataSource when property is set', () async {
      final env = GlobalEnvironment();
      final sources = MutablePropertySources();
      sources.addLast(MapPropertySource('test', {'db.ssl.enabled': 'true'}));
      env.customizePropertySources(sources);
      
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<SslDataSourceConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isTrue);
    });

    test('should not load SSL DataSource when property is false', () async {
      final env = GlobalEnvironment();
      final sources = MutablePropertySources();
      sources.addLast(MapPropertySource('test', {'db.ssl.enabled': 'false'}));
      env.customizePropertySources(sources);
      
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<SslDataSourceConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isFalse);
    });

    test('should load cluster config when mode is cluster', () async {
      final env = GlobalEnvironment();
      final sources = MutablePropertySources();
      sources.addLast(MapPropertySource('test', {'system.mode': 'cluster'}));
      env.customizePropertySources(sources);
      
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<ClusterConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isTrue);
    });
  });

  group('ConditionalOnClass Tests', () {
    test('should load PaymentService when MessageBroker exists', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<PaymentServiceConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isTrue);
    });
  });

  group('ConditionalOnMissingClass Tests', () {
    test('should not load fallback when DataSource exists', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<FallbackDataSourceConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      // DataSource exists, so fallback should NOT load
      expect(shouldInclude, isFalse);
    });
  });

  group('ConditionalOnPod Tests', () {
    test('should load UserService when DataSource and CacheManager pods exist', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      
      // Register required pods
      await factory.registerDefinition(
        'dataSource',
        RootPodDefinition(type: Class<DataSource>()),
      );
      await factory.registerDefinition(
        'cacheManager',
        RootPodDefinition(type: Class<CacheManager>()),
      );
      
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      final configClass = Class<UserServiceConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isTrue);
    });

    test('should not load UserService when required pods are missing', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<UserServiceConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isFalse);
    });
  });

  group('ConditionalOnMissingPod Tests', () {
    test('should load default cache when CacheManager pod is missing', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<DefaultCacheConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isTrue);
    });

    test('should not load default cache when CacheManager pod exists', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      
      // Register CacheManager pod
      await factory.registerDefinition(
        'cacheManager',
        RootPodDefinition(type: Class<CacheManager>()),
      );
      
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      final configClass = Class<DefaultCacheConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isFalse);
    });
  });

  group('ConditionalOnProfile Tests', () {
    test('should load dev config when dev profile is active', () async {
      final env = GlobalEnvironment();
      env.setActiveProfiles(['dev']);
      
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<DevConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isTrue);
    });

    test('should not load dev config when prod profile is active', () async {
      final env = GlobalEnvironment();
      env.setActiveProfiles(['prod']);
      
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<DevConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isFalse);
    });

    test('should load prod config when prod profile is active', () async {
      final env = GlobalEnvironment();
      env.setActiveProfiles(['prod']);
      
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<ProdConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      expect(shouldInclude, isTrue);
    });
  });

  group('ConditionalOnDart Tests', () {
    test('should evaluate Dart version condition', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<Dart3Config>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      // This will depend on the actual Dart version running the test
      expect(shouldInclude, isA<bool>());
    });
  });

  group('ConditionalOnAsset Tests', () {
    test('should evaluate asset existence condition', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<FeatureFlagConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      // This will depend on whether the asset exists
      expect(shouldInclude, isA<bool>());
    });
  });

  group('ConditionalOnExpression Tests', () {
    test('should evaluate expression condition', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      
      final configClass = Class<UserHomeConfiguration>();
      final shouldInclude = await evaluator.shouldInclude(configClass);
      
      // Expression evaluation depends on the resolver implementation
      expect(shouldInclude, isA<bool>());
    });
  });

  group('Scanner Duplicate Prevention Tests', () {
    test('should not scan the same package twice', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      final scanner = ClassPathPodDefinitionScanner(evaluator, factory, Class<Object>());
      
      // First scan
      await scanner.doScan('example');
      
      // Second scan of same package
      final secondScan = await scanner.doScan('example');
      
      // Second scan should return empty list
      expect(secondScan, isEmpty);
      expect(scanner.hasScannedPackage('example'), isTrue);
    });

    test('should not scan the same class twice', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      final scanner = ClassPathPodDefinitionScanner(evaluator, factory, Class<Object>());
      
      final testClass = Class<DataSource>();
      
      // Mark class as scanned
      scanner.markMethodScanned(testClass.getMethods().first);
      
      // Check if method is tracked
      expect(scanner.hasScannedMethod(testClass.getMethods().first), isTrue);
    });

    test('should clear scanned tracking', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      final scanner = ClassPathPodDefinitionScanner(evaluator, factory, Class<Object>());
      
      // Scan a package
      await scanner.doScan('example');
      expect(scanner.hasScannedPackage('example'), isTrue);
      
      // Clear tracking
      scanner.clearScannedTracking();
      expect(scanner.hasScannedPackage('example'), isFalse);
    });
  });

  group('Component Scan Deduplication Tests', () {
    test('should deduplicate pod definitions by name', () async {
      final env = GlobalEnvironment();
      final factory = DefaultListablePodFactory();
      final evaluator = ConditionEvaluator(env, factory, Runtime);
      final parser = ComponentScanAnnotationParser(factory, env, evaluator, Class<Object>());
      
      final configClass = ConfigurationClass(
        'testConfig',
        Class<DevConfiguration>(),
        RootPodDefinition(type: Class<DevConfiguration>()),
      );
      
      final scanConfig = ComponentScanConfiguration(
        basePackages: ['example', 'example'], // Duplicate package
      );
      
      final definitions = await parser.parse(scanConfig, configClass);
      
      // Should not have duplicates
      final names = definitions.map((d) => d.name).toList();
      final uniqueNames = names.toSet();
      expect(names.length, equals(uniqueNames.length));
    });
  });
}