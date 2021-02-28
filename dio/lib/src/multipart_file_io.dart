import 'dart:async';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'multipart_file.dart';

Future<MultipartFile> multipartFileFromPath(
  String filePath, {
  String? filename,
  MediaType? contentType,
}) async {
  filename ??= p.basename(filePath);
  var file = File(filePath);
  var length = await file.length();
  var stream = file.openRead();
  return MultipartFile(
    stream,
    length,
    filename: filename,
    contentType: contentType,
  );
}

MultipartFile multipartFileFromPathSync(
  String filePath, {
  String? filename,
  MediaType? contentType,
}) {
  filename ??= p.basename(filePath);
  var file = File(filePath);
  var length = file.lengthSync();
  var stream = file.openRead();
  return MultipartFile(
    stream,
    length,
    filename: filename,
    contentType: contentType,
  );
}
