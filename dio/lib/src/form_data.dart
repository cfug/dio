import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'multipart_file.dart';
import 'options.dart';
import 'utils.dart';

/// A class to create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
class FormData {
  FormData({this.camelCaseContentDisposition = false}) {
    _init();
  }

  /// Create FormData instance with a Map.
  FormData.fromMap(
    Map<String, dynamic> map, [
    ListFormat collectionFormat = ListFormat.multi,
    this.camelCaseContentDisposition = false,
  ]) {
    _init();
    encodeMap(
      map,
      (key, value) {
        if (value is MultipartFile) {
          files.add(MapEntry(key, value));
        } else {
          fields.add(MapEntry(key, value?.toString() ?? ''));
        }
        return null;
      },
      listFormat: collectionFormat,
      encode: false,
    );
  }

  void _init() {
    // Assure the boundary unpredictable and unique
    final random = math.Random();
    _boundary = _boundaryPrefix +
        random.nextInt(4294967296).toString().padLeft(10, '0');
  }

  static const String _boundaryPrefix = '--dio-boundary-';
  static const int _boundaryLength = _boundaryPrefix.length + 10;

  late String _boundary;

  /// The boundary of FormData, it consists of a constant prefix and a random
  /// postfix to assure the the boundary unpredictable and unique, each FormData
  /// instance will be different.
  String get boundary => _boundary;

  final _newlineRegExp = RegExp(r'\r\n|\r|\n');

  /// The form fields to send for this request.
  final fields = <MapEntry<String, String>>[];

  /// The [files].
  final files = <MapEntry<String, MultipartFile>>[];

  /// Whether [finalize] has been called.
  bool get isFinalized => _isFinalized;
  bool _isFinalized = false;
  final bool camelCaseContentDisposition;

  /// Returns the header string for a field.
  String _headerForField(String name, String value) {
    return '${camelCaseContentDisposition ? 'Content-Disposition' : 'content-disposition'}'
        ': form-data; name="${_browserEncode(name)}"'
        '\r\n\r\n';
  }

  /// Returns the header string for a file. The return value is guaranteed to
  /// contain only ASCII characters.
  String _headerForFile(MapEntry<String, MultipartFile> entry) {
    final file = entry.value;
    String header =
        '${camelCaseContentDisposition ? 'Content-Disposition' : 'content-disposition'}'
        ': form-data; name="${_browserEncode(entry.key)}"';
    if (file.filename != null) {
      header = '$header; filename="${_browserEncode(file.filename)}"';
    }
    header = '$header\r\n'
        'content-type: ${file.contentType}';
    if (file.headers != null) {
      // append additional headers
      file.headers!.forEach((key, values) {
        for (final value in values) {
          header = '$header\r\n'
              '$key: $value';
        }
      });
    }
    return '$header\r\n\r\n';
  }

  /// Encode [value] in the same way browsers do.
  String? _browserEncode(String? value) {
    // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
    // field names and file names, but in practice user agents seem not to
    // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
    // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
    // characters). We follow their behavior.
    if (value == null) {
      return null;
    }
    return value.replaceAll(_newlineRegExp, '%0D%0A').replaceAll('"', '%22');
  }

  /// The total length of the request body, in bytes. This is calculated from
  /// [fields] and [files] and cannot be set manually.
  int get length {
    int length = 0;
    for (final entry in fields) {
      length += '--'.length +
          _boundaryLength +
          '\r\n'.length +
          utf8.encode(_headerForField(entry.key, entry.value)).length +
          utf8.encode(entry.value).length +
          '\r\n'.length;
    }

    for (final file in files) {
      length += '--'.length +
          _boundaryLength +
          '\r\n'.length +
          utf8.encode(_headerForFile(file)).length +
          file.value.length +
          '\r\n'.length;
    }

    return length + '--'.length + _boundaryLength + '--\r\n'.length;
  }

  Stream<List<int>> finalize() {
    if (isFinalized) {
      throw StateError(
        'The FormData has already been finalized. '
        'This typically means you are using '
        'the same FormData in repeated requests.',
      );
    }
    _isFinalized = true;
    final controller = StreamController<List<int>>(sync: false);
    void writeAscii(String string) {
      controller.add(utf8.encode(string));
    }

    void writeUtf8(String string) => controller.add(utf8.encode(string));
    void writeLine() => controller.add([13, 10]); // \r\n

    for (final entry in fields) {
      writeAscii('--$boundary\r\n');
      writeAscii(_headerForField(entry.key, entry.value));
      writeUtf8(entry.value);
      writeLine();
    }

    Future.forEach<MapEntry<String, MultipartFile>>(files, (file) {
      writeAscii('--$boundary\r\n');
      writeAscii(_headerForFile(file));
      return writeStreamToSink(
        file.value.finalize(),
        controller,
      ).then((_) => writeLine());
    }).then((_) {
      writeAscii('--$boundary--\r\n');
      controller.close();
    });
    return controller.stream;
  }

  /// Transform the entire FormData contents as a list of bytes asynchronously.
  Future<List<int>> readAsBytes() {
    return Future(() => finalize().reduce((a, b) => [...a, ...b]));
  }

  // Convenience method to clone finalized FormData when retrying requests.
  FormData clone() {
    final clone = FormData();
    clone.fields.addAll(fields);
    for (final file in files) {
      clone.files.add(MapEntry(file.key, file.value.clone()));
    }
    return clone;
  }
}
