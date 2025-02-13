import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;

import 'options.dart';
import 'parameter.dart';

// See https://github.com/flutter/flutter/pull/112122.
const kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

// For the web platform, an inline `bool.fromEnvironment` translates to
// `core.bool.fromEnvironment` instead of correctly being replaced by the
// constant value found in the environment at build time.
//
// See https://github.com/flutter/flutter/issues/51186.
const kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// Pipes all data and errors from [stream] into [sink]. Completes [Future] once
/// [stream] is done. Unlike [store], [sink] remains open after [stream] is
/// done.
Future<void> writeStreamToSink<T>(Stream<T> stream, EventSink<T> sink) {
  final completer = Completer<void>();
  stream.listen(
    sink.add,
    onError: sink.addError,
    onDone: () => completer.complete(),
  );
  return completer.future;
}

/// Returns the [Encoding] that corresponds to [charset]. Returns [fallback] if
/// [charset] is null or if no [Encoding] was found that corresponds to
/// [charset].
Encoding encodingForCharset(String? charset, [Encoding fallback = latin1]) {
  if (charset == null) {
    return fallback;
  }
  final encoding = Encoding.getByName(charset);
  return encoding ?? fallback;
}

typedef DioEncodeHandler = String? Function(String key, Object? value);

String encodeMap(
  Object data,
  DioEncodeHandler handler, {
  bool encode = true,
  bool isQuery = false,
  ListFormat listFormat = ListFormat.multi,
}) {
  final urlData = StringBuffer('');
  bool first = true;
  // URL Query parameters are generally encoded but not their
  // index or nested names in square brackets.
  // When [encode] is false, for example for [FormData], nothing is encoded.
  final leftBracket = isQuery || !encode ? '[' : '%5B';
  final rightBracket = isQuery || !encode ? ']' : '%5D';

  final String Function(String) encodeComponent =
      encode ? Uri.encodeComponent : (e) => e;
  Object? maybeEncode(Object? value) {
    if (!isQuery || value == null || value is! String) {
      return value;
    }
    return encodeComponent(value);
  }

  void urlEncode(Object? sub, String path) {
    // Detect if the list format for this parameter derivatives from default.
    final format = sub is ListParam ? sub.format : listFormat;
    final separatorChar = _getSeparatorChar(format, isQuery);

    if (sub is ListParam) {
      // Need to unwrap all param objects here
      sub = sub.value;
    }

    if (sub is List) {
      if (format == ListFormat.multi || format == ListFormat.multiCompatible) {
        for (int i = 0; i < sub.length; i++) {
          final isCollection =
              sub[i] is Map || sub[i] is List || sub[i] is ListParam;
          if (format == ListFormat.multi) {
            urlEncode(
              maybeEncode(sub[i]),
              '$path${isCollection ? '$leftBracket$i$rightBracket' : ''}',
            );
          } else {
            // Forward compatibility
            urlEncode(
              maybeEncode(sub[i]),
              '$path$leftBracket${isCollection ? i : ''}$rightBracket',
            );
          }
        }
      } else {
        urlEncode(sub.map(maybeEncode).join(separatorChar), path);
      }
    } else if (sub is Map) {
      sub.forEach((k, v) {
        if (path == '') {
          urlEncode(maybeEncode(v), encodeComponent(k));
        } else {
          urlEncode(
            maybeEncode(v),
            '$path$leftBracket${encodeComponent(k)}$rightBracket',
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

String _getSeparatorChar(ListFormat collectionFormat, bool isQuery) {
  switch (collectionFormat) {
    case ListFormat.csv:
      return ',';
    case ListFormat.ssv:
      return isQuery ? '%20' : ' ';
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
  if (value != null && value.isNotEmpty) {
    map.addAll(value);
  }
  return map;
}

// TODO(Alex): Provide a configurable property on the Dio class once https://github.com/cfug/dio/discussions/1982 has made some progress.
void warningLog(Object message, StackTrace stackTrace) {
  if (!kReleaseMode) {
    dev.log(
      message.toString(),
      level: 900,
      name: '🔔 Dio',
      stackTrace: stackTrace,
    );
  }
}
