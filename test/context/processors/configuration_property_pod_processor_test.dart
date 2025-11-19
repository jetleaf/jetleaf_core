import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/src/annotations/configuration.dart';
import 'package:jetleaf_core/src/context/processors/configuration_property_pod_processor.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/property.dart' as env;
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:test/test.dart';

import '../../_dependencies.dart';

@ConfigurationProperty(prefix: "server")
final class ServerProperties {
  final String user;
  final String host;
  final int port;

  ServerProperties(this.host, this.port, this.user);
}

@ConfigurationProperty(prefix: "server")
final class LateServerProperties {
  late String user;
  late String host;
  late int port;

  LateServerProperties();
}

final class NestedUser {
  final String name;
  final int age;
  NestedUser(this.name, this.age);
}

@ConfigurationProperty(prefix: "server")
final class NestedServerProperties {
  final String host;
  final int port;
  final NestedUser admin;

  NestedServerProperties(this.host, this.port, this.admin);
}

final class LateNestedUser {
  late String name;
  late int age;
  LateNestedUser();
}

@ConfigurationProperty(prefix: "server")
final class LateNestedServerProperties {
  late String host;
  late int port;
  late LateNestedUser admin;

  LateNestedServerProperties();
}

final class MainClass {}

class TestPodRegistrar implements PodRegistrar {
  bool registered = false;
  final Map<String, Class> _pods = {};

  @override
  void register(PodRegistry registry, Environment env) {
    registered = true;

    for (final entry in _pods.entries) {
      registry.registerPod(entry.value, name: entry.key);
    }
  }

  void add(String name, Class definition) {
    _pods[name] = definition;
  }
}

final class MockApplicationContext extends AnnotationConfigApplicationContext {
  MockApplicationContext() {
    setApplicationStartup(DefaultApplicationStartup());
    setMainApplicationClass(Class<MainClass>());
    setApplicationEventBus(SimpleApplicationEventBus(this));
    prepareSetup();
  }
}

void main() {
  late MockApplicationContext context;
  final registrar = TestPodRegistrar();

  setUpAll(() async {
    await setupRuntime();
    context = MockApplicationContext();

    return Future<void>.value();
  });

  // MockApplicationContext context = MockApplicationContext();

  group("Constructor-Aware Processing", () {
    test("should be able to build a class using environment", () async {
      final environment = context.getEnvironment() as GlobalEnvironment;
      environment.getPropertySources().addLast(env.MapPropertySource("test", {
        "server.user": "frank",
        "server.host": "localhost",
        "server.port": 8080
      }));

      context.setEnvironment(environment);

      final type = Class<ServerProperties>();
      registrar.add("serverProperties", type);
      context.register(registrar);

      final processor = ConfigurationPropertyPodProcessor();
      processor.setEnvironment(environment);
      processor.setPodFactory(context);
      context.addPodProcessor(processor);

      // Let's try to access ServerProperties
      final property = await context.get(type);
      expect(property.host, "localhost");
      expect(property.port, 8080);
      expect(property.user, "frank");
    });
  });

  group("Field-Aware Processing", () {
    test("should be able to build a class using late fields", () async {
      final environment = context.getEnvironment() as GlobalEnvironment;
      environment.getPropertySources().addLast(env.MapPropertySource("test", {
        "server.user": "frank",
        "server.host": "localhost",
        "server.port": 8080
      }));

      context.setEnvironment(environment);

      final type = Class<LateServerProperties>();
      registrar.add("lateServerProperties", type);
      context.register(registrar);

      final processor = ConfigurationPropertyPodProcessor();
      processor.setEnvironment(environment);
      processor.setPodFactory(context);
      context.addPodProcessor(processor);

      // Let's try to access LateServerProperties
      final property = await context.get(type);
      expect(property.host, "localhost");
      expect(property.port, 8080);
      expect(property.user, "frank");
    });
  });

  group("Nested Configuration Processing", () {
    test("should be able to build a nested class using environment (Final Fields)", () async {
      final environment = context.getEnvironment() as GlobalEnvironment;
      environment.getPropertySources().addLast(env.MapPropertySource("test", {
        "server.host": "localhost",
        "server.port": 8080,
        "server.admin.name": "admin",
        "server.admin.age": 30
      }));

      context.setEnvironment(environment);

      final type = Class<NestedServerProperties>();
      registrar.add("nestedServerProperties", type);
      context.register(registrar);

      final processor = ConfigurationPropertyPodProcessor();
      processor.setEnvironment(environment);
      processor.setPodFactory(context);
      context.addPodProcessor(processor);

      final property = await context.get(type);
      expect(property.host, "localhost");
      expect(property.port, 8080);
      expect(property.admin.name, "admin");
      expect(property.admin.age, 30);
    });

    test("should be able to build a nested class using environment (Late Fields)", () async {
      final environment = context.getEnvironment() as GlobalEnvironment;
      environment.getPropertySources().addLast(env.MapPropertySource("test", {
        "server.host": "localhost",
        "server.port": 8080,
        "server.admin.name": "admin",
        "server.admin.age": 30
      }));

      context.setEnvironment(environment);

      final type = Class<LateNestedServerProperties>();
      registrar.add("lateNestedServerProperties", type);
      context.register(registrar);

      final processor = ConfigurationPropertyPodProcessor();
      processor.setEnvironment(environment);
      processor.setPodFactory(context);
      context.addPodProcessor(processor);

      final property = await context.get(type);
      expect(property.host, "localhost");
      expect(property.port, 8080);
      expect(property.admin.name, "admin");
      expect(property.admin.age, 30);
    });
  });
}