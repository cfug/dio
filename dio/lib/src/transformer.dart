import 'dart:async';
import 'package:http_parser/http_parser.dart';

import 'adapter.dart';
import 'options.dart';
import 'utils.dart';

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
        if (value == null) return key;
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
        if (value == null) return key;
        return '$key=$value';
      },
      listFormat: listFormat,
      isQuery: true,
    );
  }

  /// See https://mimesniff.spec.whatwg.org/#json-mime-type.
  static bool isJsonMimeType(String? contentType) {
    if (contentType == null) return false;
    final mediaType = MediaType.parse(contentType);
    return mediaType.mimeType == 'application/json' ||
        mediaType.mimeType == 'text/json' ||
        mediaType.subtype.endsWith('+json');
  }
}
