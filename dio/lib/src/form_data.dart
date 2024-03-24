import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'multipart_file.dart';
import 'options.dart';
import 'utils.dart';

const _rn = '\r\n';
final _rnU8 = Uint8List.fromList([13, 10]);

/// A class to create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
class FormData {
  FormData({
    this.camelCaseContentDisposition = false,
  }) {
    _init();
  }

  /// Create [FormData] from a [Map].
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

  /// Whether the 'content-disposition' header can be 'Content-Disposition'.
  final bool camelCaseContentDisposition;

  void _init() {
    // Assure the boundary unpredictable and unique.
    final random = math.Random();
    _boundary = _boundaryPrefix +
        random.nextInt(4294967296).toString().padLeft(10, '0');
  }

  static const String _boundaryPrefix = '--dio-boundary-';

  /// The boundary of FormData, it consists of a constant prefix and a random
  /// postfix to assure the the boundary unpredictable and unique, each FormData
  /// instance will be different.
  String get boundary => _boundary;
  late final String _boundary;

  /// The form fields to send for this request.
  final fields = <MapEntry<String, String>>[];

  /// The [files].
  final files = <MapEntry<String, MultipartFile>>[];

  /// Whether [finalize] has been called.
  bool get isFinalized => _isFinalized;
  bool _isFinalized = false;

  String get _contentDispositionKey => camelCaseContentDisposition
      ? 'Content-Disposition'
      : 'content-disposition';

  /// Returns the header string for a field.
  String _headerForField(String name, String value) {
    return '$_contentDispositionKey'
        ': form-data; name="${_browserEncode(name)}"'
        '$_rn$_rn';
  }

  /// Returns the header string for a file. The return value is guaranteed to
  /// contain only ASCII characters.
  String _headerForFile(MapEntry<String, MultipartFile> entry) {
    final file = entry.value;
    String header = '$_contentDispositionKey'
        ': form-data; name="${_browserEncode(entry.key)}"';
    if (file.filename != null) {
      header = '$header; filename="${_browserEncode(file.filename)}"';
    }
    header = '$header$_rn'
        'content-type: ${file.contentType}';
    if (file.headers != null) {
      // append additional headers
      file.headers!.forEach((key, values) {
        for (final value in values) {
          header = '$header$_rn'
              '$key: $value';
        }
      });
    }
    return '$header$_rn$_rn';
  }

  /// Encode [value] that follows
  /// [RFC 2388](http://tools.ietf.org/html/rfc2388).
  ///
  /// The standard mandates some complex encodings for field and file names,
  /// but in practice user agents seem not to follow this at all.
  /// Instead, they URL-encode `\r`, `\n`, and `\r\n` as `\r\n`;
  /// URL-encode `"`; and do nothing else
  /// (even for `%` or non-ASCII characters).
  /// Here we follow their behavior.
  String? _browserEncode(String? value) {
    return value
        ?.replaceAll(RegExp(r'\r\n|\r|\n'), '%0D%0A')
        .replaceAll('"', '%22');
  }

  /// The total length of the request body, in bytes. This is calculated from
  /// [fields] and [files] and cannot be set manually.
  int get length {
    int length = 0;
    for (final entry in fields) {
      length += '--'.length +
          _boundary.length +
          _rn.length +
          utf8.encode(_headerForField(entry.key, entry.value)).length +
          utf8.encode(entry.value).length +
          _rn.length;
    }

    for (final file in files) {
      length += '--'.length +
          _boundary.length +
          _rn.length +
          utf8.encode(_headerForFile(file)).length +
          file.value.length +
          _rn.length;
    }

    return length + '--'.length + _boundary.length + '--$_rn'.length;
  }

  /// Commits all fields and files into a stream for the final sending.
  Stream<Uint8List> finalize() {
    if (isFinalized) {
      throw StateError(
        'The FormData has already been finalized. '
        'This typically means you are using '
        'the same FormData in repeated requests.',
      );
    }
    _isFinalized = true;

    final controller = StreamController<Uint8List>(sync: false);
    void writeAscii(String s) => controller.add(utf8.encode(s));
    void writeUtf8(String string) => controller.add(utf8.encode(string));
    void writeLine() => controller.add(_rnU8); // \r\n

    for (final entry in fields) {
      writeAscii('--$boundary$_rn');
      writeAscii(_headerForField(entry.key, entry.value));
      writeUtf8(entry.value);
      writeLine();
    }

    Future.wait(files.map((file) async {
      writeAscii('--$boundary$_rn');
      writeAscii(_headerForFile(file));
      await writeStreamToSink(file.value.finalize(), controller);
      writeLine();
    })).then((_) {
      writeAscii('--$boundary--$_rn');
    }).whenComplete(() {
      controller.close();
    });

    return controller.stream;
  }

  /// Transform the entire FormData contents as a list of bytes asynchronously.
  Future<Uint8List> readAsBytes() {
    return finalize().reduce((a, b) => Uint8List.fromList([...a, ...b]));
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
