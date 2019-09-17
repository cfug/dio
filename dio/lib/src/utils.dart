import 'dart:async';

import 'dart:convert';

/// A regular expression that matches strings that are composed entirely of
/// ASCII-compatible characters.
final RegExp _ASCII_ONLY = RegExp(r"^[\x00-\x7F]+$");

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _ASCII_ONLY.hasMatch(string);

/// Pipes all data and errors from [stream] into [sink]. Completes [Future] once
/// [stream] is done. Unlike [store], [sink] remains open after [stream] is
/// done.
Future writeStreamToSink(Stream stream, EventSink sink) {
  var completer = Completer();
  stream.listen(sink.add,
      onError: sink.addError, onDone: () => completer.complete());
  return completer.future;
}

/// Returns the [Encoding] that corresponds to [charset]. Returns [fallback] if
/// [charset] is null or if no [Encoding] was found that corresponds to
/// [charset].
Encoding encodingForCharset(String charset, [Encoding fallback = latin1]) {
  if (charset == null) return fallback;
  var encoding = Encoding.getByName(charset);
  return encoding == null ? fallback : encoding;
}

//String encodeMap(data,String handler(String key, dynamic value)) {
//  StringBuffer urlData = StringBuffer("");
//  bool first = true;
//  void urlEncode(dynamic sub, String path) {
//    if (sub is List) {
//      for (int i = 0; i < sub.length; i++) {
//        urlEncode(sub[i],
//            "$path%5B${(sub[i] is Map || sub[i] is List) ? i : ''}%5D");
//      }
//    } else if (sub is Map) {
//      sub.forEach((k, v) {
//        if (path == "") {
//          urlEncode(v, "${Uri.encodeQueryComponent(k)}");
//        } else {
//          urlEncode(v, "$path%5B${Uri.encodeQueryComponent(k)}%5D");
//        }
//      });
//    } else {
//      var str=handler(path,sub);
//      bool isNotEmpty=str!=null&&str.trim().isNotEmpty;
//      if (!first&&isNotEmpty) {
//        urlData.write("&");
//      }
//      first = false;
//      if(isNotEmpty) {
//        urlData.write(str);
//      }
//    }
//  }
//
//  urlEncode(data, "");
//  return urlData.toString();
//}

String encodeMap(data, String handler(String key, dynamic value),
    {bool encode = true}) {
  StringBuffer urlData = StringBuffer("");
  bool first = true;
  String leftBracket = encode ? "%5B" : "[";
  String rightBracket = encode ? "%5B" : "]";
  var encodeComponent = encode ? Uri.encodeQueryComponent : (e) => e;
  void urlEncode(dynamic sub, String path) {
    if (sub is List) {
      for (int i = 0; i < sub.length; i++) {
        urlEncode(sub[i],
            "$path$leftBracket${(sub[i] is Map || sub[i] is List) ? i : ''}$rightBracket");
      }
    } else if (sub is Map) {
      sub.forEach((k, v) {
        if (path == "") {
          urlEncode(v, "${encodeComponent(k)}");
        } else {
          urlEncode(v, "$path$leftBracket${encodeComponent(k)}$rightBracket");
        }
      });
    } else {
      var str = handler(path, sub);
      bool isNotEmpty = str != null && str.trim().isNotEmpty;
      if (!first && isNotEmpty) {
        urlData.write("&");
      }
      first = false;
      if (isNotEmpty) {
        urlData.write(str);
      }
    }
  }

  urlEncode(data, "");
  return urlData.toString();
}
