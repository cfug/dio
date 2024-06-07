import 'dart:async';
import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import 'multipart_file/io_multipart_file.dart'
    if (dart.library.js_interop) 'multipart_file/browser_multipart_file.dart'
    if (dart.library.html) 'multipart_file/browser_multipart_file.dart';
import 'utils.dart';

/// The type (alias) for specifying the content-type of the `MultipartFile`.
typedef DioMediaType = MediaType;

/// A file to be uploaded as part of a [MultipartRequest]. This doesn't need to
/// correspond to a physical file.
///
/// MultipartFile is based on stream, and a stream can be read only once,
/// so the same MultipartFile can't be read multiple times.
class MultipartFile {
  /// Creates a new [MultipartFile] from a chunked [Stream] of bytes. The length
  /// of the file in bytes must be known in advance. If it's not, read the data
  /// from the stream and use [MultipartFile.fromBytes] instead.
  ///
  /// [contentType] currently defaults to `application/octet-stream`, but in the
  /// future may be inferred from [filename].
  @Deprecated(
    'MultipartFile.clone() will not work when the stream is provided, use the MultipartFile.fromStream instead.'
    'This will be removed in 6.0.0',
  )
  MultipartFile(
    Stream<List<int>> stream,
    this.length, {
    this.filename,
    DioMediaType? contentType,
    Map<String, List<String>>? headers,
  })  : _data = (() => stream),
        headers = caseInsensitiveKeyMap(headers),
        contentType = contentType ?? MediaType('application', 'octet-stream');

  /// Creates a new [MultipartFile] from a chunked [Stream] of bytes. The length
  /// of the file in bytes must be known in advance. If it's not, read the data
  /// from the stream and use [MultipartFile.fromBytes] instead.
  ///
  /// [contentType] currently defaults to `application/octet-stream`, but in the
  /// future may be inferred from [filename].
  MultipartFile.fromStream(
    Stream<List<int>> Function() data,
    this.length, {
    this.filename,
    DioMediaType? contentType,
    Map<String, List<String>>? headers,
  })  : _data = data,
        headers = caseInsensitiveKeyMap(headers),
        contentType = contentType ?? MediaType('application', 'octet-stream');

  /// Creates a new [MultipartFile] from a byte array.
  ///
  /// [contentType] currently defaults to `application/octet-stream`, but in the
  /// future may be inferred from [filename].
  factory MultipartFile.fromBytes(
    List<int> value, {
    String? filename,
    DioMediaType? contentType,
    final Map<String, List<String>>? headers,
  }) {
    return MultipartFile.fromStream(
      () => Stream.fromIterable([value]),
      value.length,
      filename: filename,
      contentType: contentType,
      headers: headers,
    );
  }

  /// Creates a new [MultipartFile] from a string.
  ///
  /// The encoding to use when translating [value] into bytes is taken from
  /// [contentType] if it has a charset set. Otherwise, it defaults to UTF-8.
  /// [contentType] currently defaults to `text/plain; charset=utf-8`, but in
  /// the future may be inferred from [filename].
  factory MultipartFile.fromString(
    String value, {
    String? filename,
    DioMediaType? contentType,
    final Map<String, List<String>>? headers,
  }) {
    contentType ??= MediaType('text', 'plain');
    final encoding = encodingForCharset(
      contentType.parameters['charset'],
      utf8,
    );
    contentType = contentType.change(parameters: {'charset': encoding.name});

    return MultipartFile.fromBytes(
      encoding.encode(value),
      filename: filename,
      contentType: contentType,
      headers: headers,
    );
  }

  /// The size of the file in bytes. This must be known in advance, even if this
  /// file is created from a [ByteStream].
  final int length;

  /// The basename of the file. May be null.
  final String? filename;

  /// The additional headers the file has. May be null.
  final Map<String, List<String>>? headers;

  /// The content-type of the file. Defaults to `application/octet-stream`.
  final DioMediaType? contentType;

  /// The stream builder that will emit the file's contents for every call.
  final Stream<List<int>> Function() _data;

  /// Whether [finalize] has been called.
  bool get isFinalized => _isFinalized;

  /// Creates a new [MultipartFile] from a path to a file on disk.
  ///
  /// [filename] defaults to the basename of [filePath]. [contentType] currently
  /// defaults to `application/octet-stream`, but in the future may be inferred
  /// from [filename].
  ///
  /// Throws an [UnsupportedError] if `dart:io` isn't supported in this
  /// environment.
  static Future<MultipartFile> fromFile(
    String filePath, {
    String? filename,
    DioMediaType? contentType,
    final Map<String, List<String>>? headers,
  }) =>
      multipartFileFromPath(
        filePath,
        filename: filename,
        contentType: contentType,
        headers: headers,
      );

  static MultipartFile fromFileSync(
    String filePath, {
    String? filename,
    DioMediaType? contentType,
    final Map<String, List<String>>? headers,
  }) =>
      multipartFileFromPathSync(
        filePath,
        filename: filename,
        contentType: contentType,
        headers: headers,
      );

  bool _isFinalized = false;

  Stream<List<int>> finalize() {
    if (isFinalized) {
      throw StateError(
        'The MultipartFile has already been finalized. '
        'This typically means you are using '
        'the same MultipartFile in repeated requests.',
      );
    }
    _isFinalized = true;
    return _data.call();
  }

  /// Clone MultipartFile, returning a new instance of the same object.
  /// This is useful if your request failed and you wish to retry it,
  /// such as an unauthorized exception can be solved by refreshing the token.
  MultipartFile clone() {
    return MultipartFile.fromStream(
      _data,
      length,
      filename: filename,
      contentType: contentType,
      headers: headers,
    );
  }
}
