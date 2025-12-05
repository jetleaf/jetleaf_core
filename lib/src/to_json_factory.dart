/// {@template to_json_factory}
/// A lightweight serialization contract for objects that can be converted
/// into a JSON-compatible `Map<String, Object>`.
///
/// The [ToJsonFactory] interface defines the minimal API required for
/// JetLeaf components or user-defined types to expose their internal state
/// in a JSON-serializable structure. It is intentionally minimal and does not
/// impose any specific serialization framework.
///
/// ### Purpose
/// Many JetLeaf systems—including diagnostics, configuration export,
/// request/response encoding, and developer tooling—require objects to be
/// converted into a uniform JSON structure. Rather than depending on large
/// serialization frameworks, JetLeaf uses this lightweight interface to ensure:
///
/// - **Consistency** across built-in framework components  
/// - **Customizability** for user-defined objects  
/// - **Framework-agnostic** JSON conversion  
///
/// ### JSON Compatibility Requirements
/// The returned map must contain values that are JSON encodable:
///
/// - `String`  
/// - `num` (`int`, `double`)  
/// - `bool`  
/// - `null`  
/// - `List` or `Map` containing these types  
///
/// Nested objects should be recursively converted to JSON-compatible values.
///
/// ### Example
/// ```dart
/// class User implements ToJsonFactory {
///   final String id;
///   final String name;
///
///   User(this.id, this.name);
///
///   @override
///   Map<String, Object> toJson() => {
///     'id': id,
///     'name': name,
///   };
/// }
///
/// final user = User('123', 'Alice');
/// print(user.toJson()); 
/// // { "id": "123", "name": "Alice" }
/// ```
///
/// ### Design Notes
/// - Implementations should avoid including non-serializable values such as
///   functions, instances without `toJson()`, open handles, etc.
/// - For complex objects, the implementer is responsible for converting nested
///   values to JSON-compatible types.
/// - This interface intentionally does not include `fromJson`, as the
///   deserialization mechanism depends on context-specific model factories.
///
/// ### Related
/// - `JsonSerializable` (from json_serializable package) – Code-generated alternative  
/// - `Encodable` / `Codec` – Dart core encoding APIs  
///
/// {@endtemplate}
abstract interface class ToJsonFactory {
  /// Converts this object into a JSON-compatible map.
  ///
  /// The returned structure must be compatible with standard JSON encoders.
  /// It should not contain:
  /// - Arbitrary objects that cannot be serialized  
  /// - Cyclic references  
  /// - Non-primitive types unless explicitly supported  
  ///
  /// ### Returns
  /// A `Map<String, Object>` containing all serializable fields that represent
  /// this object's state.
  ///
  /// ### Example
  /// ```dart
  /// final json = myObject.toJson();
  /// print(jsonEncode(json));
  /// ```
  Map<String, Object> toJson();
}