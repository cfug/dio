import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../multipart_file.dart' show MultipartFile, DioMediaType;

Future<MultipartFile> multipartFileFromPath(
  String filePath, {
  String? filename,
  DioMediaType? contentType,
  final Map<String, List<String>>? headers,
}) async {
  filename ??= p.basename(filePath);
  final file = File(filePath);
  final length = await file.length();
  return MultipartFile.fromStream(
    () => _getStreamFromFilepath(file),
    length,
    filename: filename,
    contentType: contentType,
    headers: headers,
  );
}

MultipartFile multipartFileFromPathSync(
  String filePath, {
  String? filename,
  DioMediaType? contentType,
  final Map<String, List<String>>? headers,
}) {
  filename ??= p.basename(filePath);
  final file = File(filePath);
  final length = file.lengthSync();
  return MultipartFile.fromStream(
    () => _getStreamFromFilepath(file),
    length,
    filename: filename,
    contentType: contentType,
    headers: headers,
  );
}

Stream<List<int>> _getStreamFromFilepath(File file) {
  final stream = file.openRead();
  return stream;
}
