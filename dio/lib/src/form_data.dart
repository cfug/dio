import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;

import 'multipart_file.dart';
import 'options.dart';
import 'utils.dart';

const _boundaryName = '--dio-boundary';
const _rn = '\r\n';
final _rnU8 = Uint8List.fromList([13, 10]);

const _secureRandomSeedBound = 4294967296;
final _random = math.Random();

String get _nextRandomId =>
    _random.nextInt(_secureRandomSeedBound).toString().padLeft(10, '0');

/// A class to create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
class FormData {
  FormData({
    this.boundaryName = _boundaryName,
    this.camelCaseContentDisposition = false,
  }) {
    _init();
  }

  /// Create [FormData] from a [Map].
  FormData.fromMap(
    Map<String, dynamic> map, [
    ListFormat listFormat = ListFormat.multi,
    this.camelCaseContentDisposition = false,
    this.boundaryName = _boundaryName,
  ]) {
    _init(fromMap: map, listFormat: listFormat);
  }

  /// Provides the boundary name which will be used to construct boundaries
  /// in the [FormData] with additional prefix and suffix.
  final String boundaryName;

  /// Whether the 'content-disposition' header can be 'Content-Disposition'.
  final bool camelCaseContentDisposition;

  void _init({
    Map<String, dynamic>? fromMap,
    ListFormat listFormat = ListFormat.multi,
  }) {
    // Get an unique boundary for the instance.
    _boundary = '$boundaryName-$_nextRandomId';
    if (fromMap != null) {
      // Use [encodeMap] to recursively add fields and files.
      // TODO(Alex): Write a proper/elegant implementation.
      encodeMap(
        fromMap,
        (key, value) {
          if (value is MultipartFile) {
            files.add(MapEntry(key, value));
          } else {
            fields.add(MapEntry(key, value?.toString() ?? ''));
          }
          return null;
        },
        listFormat: listFormat,
        encode: false,
      );
    }
  }

  /// The Content-Type field for multipart entities requires one parameter,
  /// "boundary", which is used to specify the encapsulation boundary.
  ///
  /// See also: https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
  String get boundary => _boundary;
  late String _boundary;

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

    void writeLine() => controller.add(_rnU8); // \r\n
    void writeUtf8(String s) =>
        controller.add(_effectiveU8Encoding(utf8.encode(s)));

    for (final entry in fields) {
      writeUtf8('--$boundary$_rn');
      writeUtf8(_headerForField(entry.key, entry.value));
      writeUtf8(entry.value);
      writeLine();
    }

    Future<void>(() async {
      for (final file in files) {
        writeUtf8('--$boundary$_rn');
        writeUtf8(_headerForFile(file));
        await writeStreamToSink<Uint8List>(file.value.finalize(), controller);
        writeLine();
      }
    }).then((_) {
      writeUtf8('--$boundary--$_rn');
    }).whenComplete(() {
      controller.close();
    });

    return controller.stream;
  }

  /// Transform the entire FormData contents as a list of bytes asynchronously.
  Future<Uint8List> readAsBytes() {
    return Future.sync(
      () => finalize().reduce((a, b) => Uint8List.fromList([...a, ...b])),
    );
  }

  // Convenience method to clone finalized FormData when retrying requests.
  FormData clone() {
    final clone = FormData();
    clone._boundary = _boundary;
    clone.fields.addAll(fields);
    for (final file in files) {
      clone.files.add(MapEntry(file.key, file.value.clone()));
    }
    return clone;
  }
}

Uint8List _effectiveU8Encoding(List<int> encoded) {
  return encoded is Uint8List ? encoded : Uint8List.fromList(encoded);
}
