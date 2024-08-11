import 'package:http_parser/http_parser.dart';

final _err = UnsupportedError(
  'MultipartFile is only supported where dart:io is available.',
);

Never multipartFileFromPath(
  String filePath, {
  String? filename,
  MediaType? contentType,
  final Map<String, List<String>>? headers,
}) =>
    throw _err;

Never multipartFileFromPathSync(
  String filePath, {
  String? filename,
  MediaType? contentType,
  final Map<String, List<String>>? headers,
}) =>
    throw _err;
