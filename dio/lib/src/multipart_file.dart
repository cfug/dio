import 'dart:async';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'utils.dart';

// ignore: uri_does_not_exist
import 'multipart_file_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'multipart_file_io.dart';

/// A file to be uploaded as part of a [MultipartRequest]. This doesn't need to
/// correspond to a physical file.
///
/// MultipartFile is based on stream, and a stream can be read only once,
/// so the same MultipartFile can't be read multiple times.
class MultipartFile {
  /// The size of the file in bytes. This must be known in advance, even if this
  /// file is created from a [ByteStream].
  final int length;

  /// The basename of the file. May be null.
  final String? filename;

  /// The additional headers the file has. May be null.
  final Map<String, List<String>>? headers;

  /// The content-type of the file. Defaults to `application/octet-stream`.
  final MediaType? contentType;

  /// The stream that will emit the file's contents.
  final Stream<List<int>> _stream;

  /// Whether [finalize] has been called.
  bool get isFinalized => _isFinalized;
  bool _isFinalized = false;

  /// Creates a new [MultipartFile] from a chunked [Stream] of bytes. The length
  /// of the file in bytes must be known in advance. If it's not, read the data
  /// from the stream and use [MultipartFile.fromBytes] instead.
  ///
  /// [contentType] currently defaults to `application/octet-stream`, but in the
  /// future may be inferred from [filename].
  MultipartFile(
    Stream<List<int>> stream,
    this.length, {
    this.filename,
    MediaType? contentType,
    Map<String, List<String>>? headers,
  })  : _stream = stream,
        headers = caseInsensitiveKeyMap(headers),
        contentType = contentType ?? MediaType('application', 'octet-stream');

  /// Creates a new [MultipartFile] from a byte array.
  ///
  /// [contentType] currently defaults to `application/octet-stream`, but in the
  /// future may be inferred from [filename].
  factory MultipartFile.fromBytes(
    List<int> value, {
    String? filename,
    MediaType? contentType,
    final Map<String, List<String>>? headers,
  }) {
    var stream = Stream.fromIterable([value]);
    return MultipartFile(
      stream,
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
    MediaType? contentType,
    final Map<String, List<String>>? headers,
  }) {
    contentType ??= MediaType('text', 'plain');
    var encoding = encodingForCharset(contentType.parameters['charset'], utf8);
    contentType = contentType.change(parameters: {'charset': encoding.name});

    return MultipartFile.fromBytes(
      encoding.encode(value),
      filename: filename,
      contentType: contentType,
      headers: headers,
    );
  }

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
    MediaType? contentType,
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
    MediaType? contentType,
    final Map<String, List<String>>? headers,
  }) =>
      multipartFileFromPathSync(
        filePath,
        filename: filename,
        contentType: contentType,
        headers: headers,
      );

  Stream<List<int>> finalize() {
    if (isFinalized) {
      throw StateError("Can't finalize a finalized MultipartFile.");
    }
    _isFinalized = true;
    return _stream;
  }
}
