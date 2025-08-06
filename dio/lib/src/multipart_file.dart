import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart' show lookupMimeType;

import 'multipart_file/io_multipart_file.dart'
    if (dart.library.js_interop) 'multipart_file/browser_multipart_file.dart'
    if (dart.library.html) 'multipart_file/browser_multipart_file.dart';
import 'utils.dart';

/// The type (alias) for specifying the content-type of the `MultipartFile`.
typedef DioMediaType = MediaType;

/// An upload content that is a part of `MultipartRequest`.
/// This doesn't need to correspond to a physical file.
class MultipartFile {
  /// Creates a new [MultipartFile] from a chunked [Stream] of bytes. The length
  /// of the file in bytes must be known in advance. If it's not, read the data
  /// from the stream and use [MultipartFile.fromBytes] instead.
  ///
  /// [contentType] currently defaults to `application/octet-stream`,
  /// but it may be inferred from [filename] in the future.
  @Deprecated(
    'MultipartFile() is not cloneable when the stream is consumed, '
    'use MultipartFile.fromStream() instead.'
    'This will be removed in 6.0.0',
  )
  MultipartFile(
    Stream<List<int>> stream,
    this.length, {
    this.filename,
    DioMediaType? contentType,
    Map<String, List<String>>? headers,
  })  : _dataBuilder = (() => stream),
        headers = caseInsensitiveKeyMap(headers),
        contentType = contentType ??
            lookupMediaType(filename) ??
            DioMediaType('application', 'octet-stream');

  /// Creates a new [MultipartFile] from a creation method that creates
  /// chunked [Stream] of bytes. The length of the file in bytes must be known
  /// in advance. If it's not, read the data from the stream and use
  /// [MultipartFile.fromBytes] instead.
  ///
  /// [contentType] currently defaults to `application/octet-stream`,
  /// but it may be inferred from [filename] in the future.
  MultipartFile.fromStream(
    Stream<List<int>> Function() data,
    this.length, {
    this.filename,
    DioMediaType? contentType,
    Map<String, List<String>>? headers,
  })  : _dataBuilder = data,
        headers = caseInsensitiveKeyMap(headers),
        contentType = contentType ??
            lookupMediaType(filename) ??
            DioMediaType('application', 'octet-stream');

  /// Creates a new [MultipartFile] from a byte array.
  ///
  /// [contentType] currently defaults to `application/octet-stream`,
  /// but it may be inferred from [filename] in the future.
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
  ///
  /// [contentType] currently defaults to `text/plain; charset=utf-8`,
  /// but it may be inferred from [filename] in the future.
  factory MultipartFile.fromString(
    String value, {
    String? filename,
    DioMediaType? contentType,
    final Map<String, List<String>>? headers,
  }) {
    contentType ??= lookupMediaType(filename) ?? DioMediaType('text', 'plain');
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
  final Stream<List<int>> Function() _dataBuilder;

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
  }) {
    return multipartFileFromPath(
      filePath,
      filename: filename,
      contentType: contentType,
      headers: headers,
    );
  }

  static MultipartFile fromFileSync(
    String filePath, {
    String? filename,
    DioMediaType? contentType,
    final Map<String, List<String>>? headers,
  }) {
    return multipartFileFromPathSync(
      filePath,
      filename: filename,
      contentType: contentType,
      headers: headers,
    );
  }

  /// Lookup the media type from the given [filenameOrPath] based on its extension.
  static DioMediaType? lookupMediaType(String? filenameOrPath) {
    filenameOrPath = filenameOrPath?.trim();
    if (filenameOrPath == null || filenameOrPath.isEmpty) {
      return null;
    }

    final mimeType = lookupMimeType(filenameOrPath);
    if (mimeType == null) {
      return null;
    }

    return DioMediaType.parse(mimeType);
  }

  bool _isFinalized = false;

  Stream<Uint8List> finalize() {
    if (isFinalized) {
      throw StateError(
        'The MultipartFile has already been finalized. '
        'This typically means you are using '
        'the same MultipartFile in repeated requests.\n'
        'Use MultipartFile.clone() or create a new MultipartFile '
        'for further usages.',
      );
    }
    _isFinalized = true;
    return _dataBuilder().map(
      (e) => e is Uint8List ? e : Uint8List.fromList(e),
    );
  }

  /// Clone MultipartFile, returning a new instance of the same object.
  /// This is useful if your request failed and you wish to retry it,
  /// such as an unauthorized exception can be solved by refreshing the token.
  MultipartFile clone() {
    return MultipartFile.fromStream(
      _dataBuilder,
      length,
      filename: filename,
      contentType: contentType,
      headers: headers,
    );
  }
}
