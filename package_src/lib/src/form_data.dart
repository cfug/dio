import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'upload_file_info.dart';

/// A class to create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
class FormData extends MapMixin<String, dynamic> {
  var _map = new Map<String, dynamic>();
  static const String _BOUNDARY_PRE_TAG = "----dio-boundary-";

  /// The boundary of FormData, it consists of a constant prefix and a random
  /// postfix to assure the the boundary unpredictable and unique, each FormData
  /// instance will be different. And you can custom it by yourself.
  String boundary;

  FormData() {
    _init();
  }

  /// Create FormData instance with a Map.
  FormData.from(Map<String, dynamic> other) {
    _init();
    addAll(other);
  }

  _init() {
    // Assure the boundary unpredictable and unique
    Random random = new Random();
    boundary = _BOUNDARY_PRE_TAG +
        random.nextInt(4294967296).toString().padLeft(10, '0');
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

  void _writeln(StringBuffer sb) {
    sb.write("\r\n");
  }

  static int _textFieldLen;
  static int _fileFieldLen;

  int get _textFieldLength {
    if (_textFieldLen == null) {
      _textFieldLen = _textField(StringBuffer(), "", "").length;
    }
    return _textFieldLen;
  }

  int get _fileFieldLength {
    if (_fileFieldLen == null) {
      _fileFieldLen = _chunkHeader(
        StringBuffer(),
        "",
        UploadFileInfo(null, "", contentType: ContentType.text),
      ).length -
          utf8.encode(ContentType.text.mimeType).length;
    }
    return _fileFieldLen;
  }

//  void writeMapLength(buf, key, value, len) {
//
//    value.keys.toList().forEach((mapKey) {
//      var nestedKey = '${key}[${mapKey}]';
//      len += _textFieldLength;
//      buf.write("$nestedKey${value[mapKey]}");
//      if (value[mapKey] is Map) {
//        writeMapLength(buf, nestedKey, value[mapKey], len);
//      }else if (value[mapKey] is UploadFileInfo){
//        var e = value[mapKey];
//        len += _fileFieldLength;
//        _fileInfo(nestedKey, value[mapKey]);
//        len += e.bytes?.length ?? e.file.lengthSync();
//        len += utf8.encode('\r\n').length;
//      }
//      print(buf);
//    });
//  }

  /// Get the length of the formData (as bytes)
  int get length {
    var len = 0;
    int lineSplitLen = utf8.encode('\r\n').length;
    var fileMap = new Map<String, dynamic>();
    StringBuffer buf = StringBuffer();

    _fileInfo(key, UploadFileInfo info) {
      buf.write("$key${info.fileName}");
      buf.write((info.contentType ?? ContentType.text).mimeType);
    }

    writeMapLength(buf, key, value, len) {
      value.keys.toList().forEach((mapKey) {
        var nestedKey = '${key}[${mapKey}]';
        if (value[mapKey] is Map) {
          writeMapLength(buf, nestedKey, value[mapKey], len);
        } else if (value[mapKey] is UploadFileInfo) {
          var e = value[mapKey];
          len += _fileFieldLength;
          _fileInfo(nestedKey, value[mapKey]);
          len += e.bytes?.length ?? e.file.lengthSync();
          len += utf8.encode('\r\n').length;
        } else {
          len += _textFieldLength;
          buf.write("$nestedKey${value[mapKey]}");
        }
      });
    }

    _map.forEach((key, value) {
      if (value is UploadFileInfo || value is List) {
        fileMap[key] = value;
        return;
      } else if (value is Map) {
        value.keys.toList().forEach((mapKey) {
          var nestedKey = '${key}[${mapKey}]';
          if (value[mapKey] is Map) {
            writeMapLength(buf, nestedKey, value[mapKey], len);
          } else if (value[mapKey] is UploadFileInfo) {
            len += _fileFieldLength;
            _fileInfo(nestedKey, value[mapKey]);
            len += value[mapKey].bytes?.length ?? value[mapKey].file.lengthSync();
            len += lineSplitLen;
          } else {
            len += _textFieldLength;
            buf.write(
                "$nestedKey${value[mapKey] == null ? '' : value[mapKey]}");
          }
        });
      } else {
        len += _textFieldLength;
        buf.write("$key$value");
      }
    });

    fileMap.forEach((key, fileInfo) {
      if (fileInfo is UploadFileInfo) {
        len += _fileFieldLength;
        _fileInfo(key, fileInfo);
        len += fileInfo.bytes?.length ?? fileInfo.file.lengthSync();
        len += lineSplitLen;
      } else {
        (fileInfo as List).forEach((e) {
          if (e is UploadFileInfo) {
            len += _fileFieldLength;
            _fileInfo(key, e);
            len += e.bytes?.length ?? e.file.lengthSync();
            len += lineSplitLen;
          } else if (e is Map) {
            e.keys.toList().forEach((mapKey) {
              var nestedKey = '${key}[][${mapKey}]';
              if (e[mapKey] is Map) {
                writeMapLength(buf, nestedKey, e[mapKey], len);
              } else if (e[mapKey] is UploadFileInfo) {
                len += _fileFieldLength;
                _fileInfo(nestedKey, e[mapKey]);
                len += e[mapKey].bytes?.length ?? e[mapKey].file.lengthSync();
                len += lineSplitLen;
              } else {
                len += _textFieldLength;
                buf.write("$nestedKey${e[mapKey] == null ? '' : e[mapKey]}");
              }
            });
          } else {
            len += _textFieldLength;
            buf.write("$key$e");
          }
        });
      }
    });
    if (_map.isNotEmpty || fileMap.isNotEmpty) {
      buf.write(boundary + "--");
      _writeln(buf);
    }
    len += utf8.encode(buf.toString()).length;
    return len;
  }

  ///Transform the entire FormData contents as a list of bytes asynchronously.
  Future<List<int>> asBytesAsync() {
    return stream.reduce((a, b) => []..addAll(a)..addAll(b));
  }

  ///Transform the entire FormData contents as a list of bytes synchronously.
  List<int> asBytes() {
    List<int> bytes = new List();
    var fileMap = new Map<String, dynamic>();
    StringBuffer data = new StringBuffer();
    _map.forEach((key, value) {
      if (value is UploadFileInfo || value is List) {
        // If file, add it to `fileMap`, we handle it later.
        fileMap[key] = value;
        return;
      } else if (value is Map) {
        handleMapField(bytes, key, value);
      } else {
        bytes.addAll(_textField(data, key, value));
      }
    });
    fileMap.forEach((key, fileInfo) {
      if (fileInfo is UploadFileInfo) {
        bytes.addAll(_chunkHeader(data, key, fileInfo));
        bytes.addAll(fileInfo.bytes ?? fileInfo.file.readAsBytesSync());
        bytes.addAll(utf8.encode('\r\n'));
      } else {
        (fileInfo as List).forEach((e) {
          if (e is UploadFileInfo) {
            bytes.addAll(_chunkHeader(data, key, e));
            bytes.addAll(e.bytes ?? e.file.readAsBytesSync());
            bytes.addAll(utf8.encode('\r\n'));
          } else {
            bytes.addAll(_textField(data, key, e));
          }
        });
      }
    });

    if (_map.isNotEmpty || fileMap.isNotEmpty) {
      data.clear();
      data.write(boundary + "--");
      _writeln(data);
      bytes.addAll(utf8.encode(data.toString()));
    }
    return bytes;
  }

  @Deprecated('Use `asBytes` instead. Will be removed in 2.1.0')
  List<int> bytes() {
    return asBytes();
  }

  handleMapField(List<int> bytes, String key, dynamic value) {
    StringBuffer buffer = new StringBuffer();
    if (value is Map) {
      value.keys.toList().forEach((mapKey) {
        var nestedKey = '${key}[${mapKey}]';
        if (value[mapKey] is Map) {
          handleMapField(bytes, nestedKey, value[mapKey]);
        } else if (value[mapKey] is UploadFileInfo) {
          var fileInfo = value[mapKey];
          bytes.addAll(_chunkHeader(buffer, nestedKey, fileInfo));
          bytes.addAll(fileInfo.bytes ?? fileInfo.file.readAsBytesSync());
          bytes.addAll(utf8.encode('\r\n'));
        } else {
          bytes.addAll(_textField(
              buffer, nestedKey, value[mapKey] == null ? '' : value[mapKey]));
        }
      });
    } else if (value is UploadFileInfo) {
      bytes.addAll(_chunkHeader(buffer, key, value));
      bytes.addAll(value.bytes ?? value.file.readAsBytesSync());
      bytes.addAll(utf8.encode('\r\n'));
    } else {
      bytes.addAll(_textField(buffer, key, value));
    }
  }

  List<int> _textField(StringBuffer buffer, String key, value) {
    buffer.clear();
    buffer.write(boundary);
    _writeln(buffer);
    buffer.write('Content-Disposition: form-data; name="${key}"');
    _writeln(buffer);
    _writeln(buffer);
    buffer.write(value);
    _writeln(buffer);
    String str = buffer.toString();
    buffer.clear();
    return utf8.encode(str);
  }

  List<int> _chunkHeader(
      StringBuffer buffer,
      String key,
      UploadFileInfo fileInfo,
      ) {
    buffer.clear();
    buffer.write(boundary);
    _writeln(buffer);
    buffer.write(
        'Content-Disposition: form-data; name="$key"; filename="${fileInfo.fileName}"');
    _writeln(buffer);
    buffer.write(
        "Content-Type: " + (fileInfo.contentType ?? ContentType.text).mimeType);
    _writeln(buffer);
    _writeln(buffer);
    String str = buffer.toString();
    buffer.clear();
    return utf8.encode(str);
  }

  Stream<List<int>> get stream async* {
    var fileMap = new Map<String, dynamic>();
    StringBuffer buffer = new StringBuffer();

    Stream<List<int>> addFile(String key, UploadFileInfo value) async* {
      yield _chunkHeader(buffer, key, value);
      if (value.bytes != null) {
        for (var i = 0, p; i < value.bytes.length; i += 1024) {
          p = i + 1024;
          if (p > value.bytes.length) p = value.bytes.length;
          yield value.bytes.sublist(i, p);
        }
      } else {
        await for (var chunk in value.file.openRead()) {
          yield chunk;
        }
      }
      yield utf8.encode('\r\n');
    }

    for (var entry in _map.entries) {
      if (entry.value is UploadFileInfo || entry.value is List) {
        // If file, add it to `fileMap`, we handle it later.
        fileMap[entry.key] = entry.value;
        continue;
      } else if (entry.value is Map) {
        var bytes = List<int>();
        handleMapField(bytes, entry.key, entry.value);
        yield bytes;
      } else {
        yield _textField(buffer, entry.key, entry.value);
      }
    }

    for (var entry in fileMap.entries) {
      if (entry.value is UploadFileInfo) {
        await for (var chunk in addFile(entry.key, entry.value)) {
          yield chunk;
        }
      } else {
        for (var info in entry.value) {
          if (info is UploadFileInfo) {
            await for (var chunk in addFile(entry.key, info)) {
              yield chunk;
            }
          } else {
            var listBytes = List<int>();
            handleMapField(listBytes, '${entry.key}[]', info);
            yield listBytes;
          }
        }
      }
    }

    if (_map.isNotEmpty || fileMap.isNotEmpty) {
      buffer.clear();
      buffer.write(boundary + "--");
      _writeln(buffer);
      yield utf8.encode(buffer.toString());
    }
  }

  @override
  String toString() {
    return utf8.decode(asBytes(), allowMalformed: true);
  }
}
