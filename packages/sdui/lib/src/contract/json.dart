/// Reads untyped JSON safely.
///
/// On web a section declares its props with a zod schema. Dart has no direct
/// equivalent, so each section writes a small `parse` with these readers: every
/// one either returns a typed value or throws [InvalidJson] with the path of
/// the field that failed (`items.2.priceLabel: expected a non-empty string`).
library;

import 'action.dart';

class InvalidJson implements Exception {
  const InvalidJson(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => '${path.isEmpty ? '(root)' : path}: $message';
}

class JsonObject {
  const JsonObject(this._map, [this._path = '']);

  static const empty = JsonObject({});

  /// Throws if [value] is not a JSON object.
  factory JsonObject.from(Object? value, [String path = '']) {
    if (value is Map) return JsonObject(value.cast<String, Object?>(), path);
    throw InvalidJson(path, 'expected an object');
  }

  final Map<String, Object?> _map;
  final String _path;

  Map<String, Object?> toMap() => _map;

  /// The value as it arrived, for fields validated later by someone else.
  Object? raw(String key) => _map[key];

  /// Required, non-empty.
  String string(String key) {
    final value = _map[key];
    if (value is String && value.isNotEmpty) return value;
    throw InvalidJson(_at(key), 'expected a non-empty string');
  }

  String? stringOrNull(String key) {
    final value = _map[key];
    if (value == null || value is String) return value as String?;
    throw InvalidJson(_at(key), 'expected a string');
  }

  /// Required, absolute http(s) URL.
  String url(String key) => _url(key, string(key));

  String? urlOrNull(String key) {
    final value = stringOrNull(key);
    return value == null ? null : _url(key, value);
  }

  bool boolean(String key, {required bool fallback}) {
    final value = _map[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    throw InvalidJson(_at(key), 'expected a boolean');
  }

  JsonObject object(String key) => JsonObject.from(_map[key], _at(key));

  JsonObject? objectOrNull(String key) => _map[key] == null ? null : object(key);

  /// A list of objects, each one parsed with [parse]. Absent means empty.
  List<T> list<T>(String key, T Function(JsonObject item) parse, {int min = 0}) {
    final value = _map[key] ?? const <Object?>[];
    if (value is! List || value.length < min) {
      throw InvalidJson(_at(key), min > 0 ? 'expected a list with at least $min item(s)' : 'expected a list');
    }
    return [for (var i = 0; i < value.length; i++) parse(JsonObject.from(value[i], '${_at(key)}.$i'))];
  }

  /// Enum that DEGRADES instead of failing.
  ///
  /// The backend will add values (a new theme, a new variant) long before every
  /// installed app knows them. An unknown value falls back to [fallback]
  /// instead of invalidating the section or the whole screen.
  String semanticEnum(String key, List<String> values, String fallback) {
    final value = _map[key];
    return value is String && values.contains(value) ? value : fallback;
  }

  /// `{ "onPress": [ ...actions ] }`. The actions stay untyped: each one is
  /// validated when it is dispatched, so a bad action never hides its section.
  Triggers? triggersOrNull(String key) {
    final value = _map[key];
    if (value == null) return null;
    if (value is Map && value.values.every((list) => list is List)) {
      return {for (final entry in value.entries) entry.key as String: List<Object?>.of(entry.value as List)};
    }
    throw InvalidJson(_at(key), 'expected triggers ({ name: [actions] })');
  }

  String _at(String key) => _path.isEmpty ? key : '$_path.$key';

  String _url(String key, String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasAuthority && (uri.scheme == 'http' || uri.scheme == 'https')) return value;
    throw InvalidJson(_at(key), 'expected an http(s) URL');
  }
}
