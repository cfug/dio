import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'options.dart';
import 'parameter.dart';

/// Pipes all data and errors from [stream] into [sink]. Completes [Future] once
/// [stream] is done. Unlike [store], [sink] remains open after [stream] is
/// done.
Future writeStreamToSink(Stream stream, EventSink sink) {
  final completer = Completer();
  stream.listen(sink.add,
      onError: sink.addError, onDone: () => completer.complete());
  return completer.future;
}

/// Returns the [Encoding] that corresponds to [charset]. Returns [fallback] if
/// [charset] is null or if no [Encoding] was found that corresponds to
/// [charset].
Encoding encodingForCharset(String? charset, [Encoding fallback = latin1]) {
  if (charset == null) return fallback;
  final encoding = Encoding.getByName(charset);
  return encoding ?? fallback;
}

typedef DioEncodeHandler = String? Function(String key, Object? value);

String encodeMap(
  data,
  DioEncodeHandler handler, {
  bool encode = true,
  ListFormat listFormat = ListFormat.multi,
}) {
  final urlData = StringBuffer('');
  bool first = true;
  final leftBracket = encode ? '%5B' : '[';
  final rightBracket = encode ? '%5D' : ']';
  final encodeComponent = encode ? Uri.encodeQueryComponent : (e) => e;
  void urlEncode(dynamic sub, String path) {
    // Detect if the list format for this parameter derivatives from default.
    final format = sub is ListParam ? sub.format : listFormat;
    final separatorChar = _getSeparatorChar(format);

    if (sub is ListParam) {
      // Need to unwrap all param objects here
      sub = sub.value;
    }

    if (sub is List) {
      if (format == ListFormat.multi || format == ListFormat.multiCompatible) {
        for (int i = 0; i < sub.length; i++) {
          final isCollection =
              sub[i] is Map || sub[i] is List || sub[i] is ListParam;
          if (listFormat == ListFormat.multi) {
            urlEncode(
              sub[i],
              '$path${isCollection ? '$leftBracket$i$rightBracket' : ''}',
            );
          } else {
            // Forward compatibility
            urlEncode(
              sub[i],
              '$path$leftBracket${isCollection ? i : ''}$rightBracket',
            );
          }
        }
      } else {
        urlEncode(sub.join(separatorChar), path);
      }
    } else if (sub is Map) {
      sub.forEach((k, v) {
        if (path == '') {
          urlEncode(v, '${encodeComponent(k as String)}');
        } else {
          urlEncode(
            v,
            '$path$leftBracket${encodeComponent(k as String)}$rightBracket',
          );
        }
      });
    } else {
      final str = handler(path, sub);
      final isNotEmpty = str != null && str.trim().isNotEmpty;
      if (!first && isNotEmpty) {
        urlData.write('&');
      }
      first = false;
      if (isNotEmpty) {
        urlData.write(str);
      }
    }
  }

  urlEncode(data, '');
  return urlData.toString();
}

String _getSeparatorChar(ListFormat collectionFormat) {
  switch (collectionFormat) {
    case ListFormat.csv:
      return ',';
    case ListFormat.ssv:
      return ' ';
    case ListFormat.tsv:
      return r'\t';
    case ListFormat.pipes:
      return '|';
    default:
      return '';
  }
}

Map<String, V> caseInsensitiveKeyMap<V>([Map<String, V>? value]) {
  final map = LinkedHashMap<String, V>(
    equals: (key1, key2) => key1.toLowerCase() == key2.toLowerCase(),
    hashCode: (key) => key.toLowerCase().hashCode,
  );
  if (value != null && value.isNotEmpty) map.addAll(value);
  return map;
}
