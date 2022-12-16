import 'dart:async';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../multipart_file.dart';

Future<MultipartFile> multipartFileFromPath(
  String filePath, {
  String? filename,
  MediaType? contentType,
  final Map<String, List<String>>? headers,
}) async {
  filename ??= p.basename(filePath);
  final file = File(filePath);
  final length = await file.length();
  final stream = file.openRead();
  return MultipartFile(
    stream,
    length,
    filename: filename,
    contentType: contentType,
    headers: headers,
  );
}

MultipartFile multipartFileFromPathSync(
  String filePath, {
  String? filename,
  MediaType? contentType,
  final Map<String, List<String>>? headers,
}) {
  filename ??= p.basename(filePath);
  final file = File(filePath);
  final length = file.lengthSync();
  final stream = file.openRead();
  return MultipartFile(
    stream,
    length,
    filename: filename,
    contentType: contentType,
    headers: headers,
  );
}
