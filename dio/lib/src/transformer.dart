import 'dart:async';
import 'package:http_parser/http_parser.dart';

import 'adapter.dart';
import 'options.dart';
import 'utils.dart';

export 'transformers/background_transformer.dart';
export 'transformers/fused_transformer.dart';
export 'transformers/sync_transformer.dart';

/// The callback definition for decoding a JSON string.
typedef JsonDecodeCallback = FutureOr<dynamic> Function(String);

/// The callback definition for encoding a JSON object.
typedef JsonEncodeCallback = FutureOr<String> Function(Object);

/// [Transformer] allows changes to the request/response data before
/// it is sent/received to/from the server.
///
/// Dio has already implemented a [BackgroundTransformer], and as the default
/// [Transformer]. If you want to custom the transformation of
/// request/response data, you can provide a [Transformer] by your self, and
/// replace the [BackgroundTransformer] by setting the [Dio.Transformer].
abstract class Transformer {
  /// [transformRequest] allows changes to the request data before it is
  /// sent to the server, but **after** the [RequestInterceptor].
  ///
  /// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'
  Future<String> transformRequest(RequestOptions options);

  /// [transformResponse] allows changes to the response data  before
  /// it is passed to [ResponseInterceptor].
  ///
  /// **Note**: As an agreement, you must return the [responseBody]
  /// when the Options.responseType is [ResponseType.stream].
  // TODO(AlexV525): Add generic type for the method in v6.0.0.
  Future transformResponse(RequestOptions options, ResponseBody responseBody);

  /// Recursively encode the [Map<String, dynamic>] to percent-encoding.
  /// Generally used with the "application/x-www-form-urlencoded" content-type.
  static String urlEncodeMap(
    Map<String, dynamic> map, [
    ListFormat listFormat = ListFormat.multi,
  ]) {
    return encodeMap(
      map,
      (key, value) {
        if (value == null) {
          return key;
        }
        return '$key=${Uri.encodeQueryComponent(value.toString())}';
      },
      listFormat: listFormat,
    );
  }

  /// Deep encode the [Map<String, dynamic>] to a query parameter string.
  static String urlEncodeQueryMap(
    Map<String, dynamic> map, [
    ListFormat listFormat = ListFormat.multi,
  ]) {
    return encodeMap(
      map,
      (key, value) {
        if (value == null) {
          return key;
        }
        return '$key=$value';
      },
      listFormat: listFormat,
      isQuery: true,
    );
  }

  /// See https://mimesniff.spec.whatwg.org/#json-mime-type.
  static bool isJsonMimeType(String? contentType) {
    if (contentType == null) {
      return false;
    }
    try {
      final mediaType = MediaType.parse(contentType);
      return mediaType.mimeType == 'application/json' ||
          mediaType.mimeType == 'text/json' ||
          mediaType.subtype.endsWith('+json');
    } catch (e, s) {
      warningLog(
        'Failed to parse the media type: $contentType, '
        'thus it is not a JSON MIME type.',
        s,
      );
      return false;
    }
  }

  static FutureOr<String> defaultTransformRequest(
    RequestOptions options,
    JsonEncodeCallback jsonEncodeCallback,
  ) {
    final Object data = options.data ?? '';
    if (data is! String && Transformer.isJsonMimeType(options.contentType)) {
      return jsonEncodeCallback(data);
    } else if (data is Map) {
      if (data is Map<String, dynamic>) {
        return Transformer.urlEncodeMap(data, options.listFormat);
      }
      warningLog(
        'The data is a type of `Map` (${data.runtimeType}), '
        'but the transformer can only encode `Map<String, dynamic>`.\n'
        'If you are writing maps using `{}`, '
        'consider writing `<String, dynamic>{}`.',
        StackTrace.current,
      );
      return data.toString();
    } else {
      return data.toString();
    }
  }
}
