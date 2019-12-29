import 'dart:async';
import 'package:http_parser/http_parser.dart';
import 'multipart_file.dart';

final _err = UnsupportedError(
    'MultipartFile is only supported where dart:io is available.');

Future<MultipartFile> multipartFileFromPath(String filePath,
        {String filename, MediaType contentType}) =>
    throw _err;

MultipartFile multipartFileFromPathSync(String filePath,
        {String filename, MediaType contentType}) =>
    throw _err;
