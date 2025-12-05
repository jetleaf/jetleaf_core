import 'package:jetleaf_lang/lang.dart';

/// {@template resource}
/// A generic abstraction for JetLeaf-compatible resource.
///
/// The [Resource] interface formalizes how key/value resource structures
/// behave throughout the JetLeaf framework. It provides a unified contract
/// that applies to a wide variety of resource backends—ranging from simple
/// in-memory maps to advanced distributed or persistent stores.
///
/// ### Purpose
/// JetLeaf components such as:
/// - caching layers,
/// - rate-limit engines,
/// - configuration pods,
/// - diagnostics utilities,
/// all rely on a consistent resource interface that behaves predictably
/// regardless of the underlying implementation.
///
/// The [Resource] interface guarantees that all JetLeaf resource backends:
/// - Support a basic **existence check** via [exists].
/// - Support **value retrieval** via [get].
/// - Are generic over both stored values and keys.
/// - Can be wrapped, extended, decorated, or introspected by JetLeaf systems.
///
/// This interface does *not* dictate mutation, eviction, locking, or
/// persistence behavior. Those capabilities are optionally introduced by more
/// specialized interfaces such as:
/// - `CacheResource`
/// - `RateLimitResource`
/// - or user-defined resource classes.
///
/// ---
/// ## Resource Characteristics
///
/// Implementations should aim to be:
///
/// ### 🔒 Consistent  
/// Access and lookups should be deterministic, even when concurrently used
/// across async or parallel contexts.
///
/// ### 🔁 Representable  
/// Implementations are often examined or surfaced in JetLeaf diagnostics,
/// meaning their internal structure or metadata should be representable
/// in a stable form.
///
/// ### 🧩 Interoperable  
/// The abstraction enables JetLeaf to plug in different resource backends
/// without requiring consumer-level changes.
///
/// ---
/// ## Typical Implementations
///
/// | Implementation | Description |
/// |----------------|-------------|
/// | `CacheResource` | Standard backing store for in-memory cache maps. |
/// | `RateLimitResource` | Stores counters/timestamps for rate limit buckets. |
/// | `PersistentCacheResource` | Disk, Redis, SQL, or other durable resource. |
///
/// These implementations commonly wrap a map-like structure but may use
/// more complex distributed or persistent backends.
///
/// ---
/// ## Example
///
/// ```dart
/// class InMemoryUserResource implements Resource<User, String> {
///   final Map<String, User> _users = {};
///
///   @override
///   bool exists(String key) => _users.containsKey(key);
///
///   @override
///   User? get(String key) => _users[key];
///
///   void addUser(User user) => _users[user.id] = user;
/// }
///
/// final resource = InMemoryUserResource();
/// resource.addUser(User('123', 'Alice'));
///
/// print(resource.exists('123')); // → true
/// print(resource.get('123')?.name); // → Alice
/// ```
///
/// ---
/// ## Design Notes
///
/// JetLeaf’s architecture separates:
/// - **resource behavior** (implemented here), and  
/// - **management logic** (implemented in managers such as `CacheManager`).  
///
/// This allows resource layers to remain lightweight, independent, and easy to
/// replace while keeping higher-level components declarative.
///
/// ---
/// ## Related Interfaces
///
/// - **CacheResource** – Defines additional mutation and eviction behaviors.
/// - **RateLimitResource** – Defines atomic update semantics for rate limiting.
/// - **StorableResource** (user-defined) – Useful for external integrations.
///
/// {@endtemplate}
@Generic(Resource)
abstract interface class Resource<Key, Value> {
  /// Determines whether an entry associated with the given [key] exists.
  ///
  /// This operation is commonly used by caching subsystems, rate-limit
  /// controllers, or configuration resolvers to avoid unnecessary retrievals.
  /// Implementations should ensure this check is efficient and free of
  /// side effects.
  ///
  /// ### Parameters
  /// - **key**: The identifier representing the stored entry.
  ///
  /// ### Returns
  /// - `true` if the key exists in the underlying store.
  /// - `false` if the key is not present.
  ///
  /// ### Example
  /// ```dart
  /// if (tokens.exists('session:abc')) {
  ///   print('Session token found.');
  /// }
  /// ```
  bool exists(Key key);

  /// Retrieves the value associated with the given [key], if any.
  ///
  /// This method provides read-only access to resource entries. Implementations
  /// may perform a simple lookup (e.g., for in-memory maps) or a more complex
  /// asynchronous/serialized retrieval depending on the backend.
  ///
  /// ### Parameters
  /// - **key**: The lookup key for the stored value.
  ///
  /// ### Returns
  /// - The stored [Value], or `null` if the key is absent.
  ///
  /// ### Example
  /// ```dart
  /// final value = cache.get('page:/home');
  /// if (value != null) {
  ///   render(value);
  /// }
  /// ```
  Value? get(Key key);
}