import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/src/UploadFileInfo.dart';

/**
 * A class to create readable "multipart/form-data" streams.
 * It can be used to submit forms and file uploads to http server.
 */
class FormData extends MapMixin<String, dynamic> {
  var _map = new Map<String, dynamic>();
  static const String _BOUNDARY_PRE_TAG = "----dioBoundary&Happycoding-";

  /// The boundary of FormData, it consists of a constant prefix and a random
  /// postfix to assure the the boundary unpredictable and unique, each FormData
  /// instance will be different. And you can custom it by yourself.
  String boundary;

  FormData() {
    _init();
  }

  /**
   * Create FormData instance with a Map.
   */
  FormData.from(Map other){
    _init();
    addAll(other);
  }

  _init(){
    // Assure the boundary unpredictable and unique
    Random random = new Random();
    boundary = _BOUNDARY_PRE_TAG + random.nextInt(4294967296).toString();
  }

  @override
  operator [](Object key) {
    return _map[key];
  }

  @override
  void operator []=(key, value) {
    _map[key] = value;
  }

  @override
  void clear() {
    _map.clear();
  }

  @override
  Iterable<String> get keys => _map.keys;

  @override
  remove(Object key) {
    return _map.remove(key);
  }

  void add(String key, value) {
    _map[key] = value;
  }

  void _writeln(StringBuffer sb){
    sb.write("\r\n");
  }

  /// Generate the payload for request body.
  List<int> bytes() {
    List<int> bytes = new List();
    var fileMap = new Map<String, UploadFileInfo>();
    StringBuffer data = new StringBuffer();
    _map.forEach((key, value) {
      if (value is UploadFileInfo) {
        // If file, add it to `fileMap`, we handle it later.
        fileMap[key] = value;
        return;
      }
      data.write(boundary);
      _writeln(data);
      data.write('Content-Disposition: form-data; name="${key}"');
      _writeln(data);
      _writeln(data);
      data.write(value);
      _writeln(data);
    });
    // Transform string to bytes.
    bytes.addAll(UTF8.encode(data.toString()));
    // Handle the files.
    fileMap.forEach((key, UploadFileInfo fileInfo) {
      data = new StringBuffer();
      data.write(boundary);
      _writeln(data);
      data.write(
          'Content-Disposition: form-data; name="$key"; filename="${fileInfo
              .fileName}"');
      _writeln(data);
      data.write("Content-Type: " +
          (fileInfo.contentType ?? ContentType.TEXT).mimeType);
      _writeln(data);
      _writeln(data);
      bytes.addAll(UTF8.encode(data.toString()));
      bytes.addAll(fileInfo.file.readAsBytesSync());
    });
    if (_map.length > 0 || fileMap.length > 0) {
      data.clear();
      if(fileMap.length>0) {
        _writeln(data);
      }
      data.write(boundary+"--");
      _writeln(data);
      //_writeln(data);
      bytes.addAll(UTF8.encode(data.toString()));
    }
    return bytes;
  }

}