import 'package:http_parser/http_parser.dart';

import 'utils.dart';

/// The signature that iterates header fields.
typedef HeaderForEachCallback = void Function(String name, List<String> values);

/// The headers class for requests and responses.
class Headers {
  Headers() : _map = caseInsensitiveKeyMap<List<String>>();

  /// Create the [Headers] from a [Map] instance.
  Headers.fromMap(Map<String, List<String>> map)
      : _map = caseInsensitiveKeyMap<List<String>>(
          map.map((k, v) => MapEntry(k.trim().toLowerCase(), v)),
        );

  static const acceptHeader = 'accept';
  static const contentEncodingHeader = 'content-encoding';
  static const contentLengthHeader = 'content-length';
  static const contentTypeHeader = 'content-type';
  static const wwwAuthenticateHeader = 'www-authenticate';

  static const jsonContentType = 'application/json';
  static const formUrlEncodedContentType = 'application/x-www-form-urlencoded';
  static const textPlainContentType = 'text/plain';
  static const multipartFormDataContentType = 'multipart/form-data';

  static final jsonMimeType = MediaType.parse(jsonContentType);

  final Map<String, List<String>> _map;

  Map<String, List<String>> get map => _map;

  /// Returns the list of values for the header named [name]. If there
  /// is no header with the provided name, [:null:] will be returned.
  List<String>? operator [](String name) {
    return _map[name.trim().toLowerCase()];
  }

  /// Convenience method for the value for a single valued header. If
  /// there is no header with the provided name, [:null:] will be
  /// returned. If the header has more than one value an exception is
  /// thrown.
  String? value(String name) {
    final arr = this[name];
    if (arr == null) return null;
    if (arr.length == 1) return arr.first;
    throw Exception(
      '"$name" header has more than one value, please use Headers[name]',
    );
  }

  /// Adds a header value. The header named [name] will have the value
  /// [value] added to its list of values.
  void add(String name, String value) {
    final arr = this[name];
    if (arr == null) return set(name, value);
    arr.add(value);
  }

  /// Sets a header. The header named [name] will have all its values
  /// cleared before the value [value] is added as its value.
  void set(String name, dynamic value) {
    if (value == null) return;
    name = name.trim().toLowerCase();
    if (value is List) {
      _map[name] = value.map<String>((e) => e.toString()).toList();
    } else {
      _map[name] = ['$value'.trim()];
    }
  }

  /// Removes a specific value for a header name.
  void remove(String name, String value) {
    final arr = this[name];
    if (arr == null) return;
    arr.removeWhere((v) => v == value);
  }

  /// Removes all values for the specified header name.
  void removeAll(String name) {
    _map.remove(name);
  }

  /// Clearing all fields in the headers.
  void clear() {
    _map.clear();
  }

  /// Whether the headers has no fields.
  bool get isEmpty => _map.isEmpty;

  /// Enumerates the headers, applying the function [f] to each
  /// header. The header name passed in [:name:] will be all lower
  /// case.
  void forEach(HeaderForEachCallback f) {
    for (final key in _map.keys) {
      f(key, this[key]!);
    }
  }

  @override
  String toString() {
    final stringBuffer = StringBuffer();
    _map.forEach((key, value) {
      for (final e in value) {
        stringBuffer.writeln('$key: $e');
      }
    });
    return stringBuffer.toString();
  }
}
