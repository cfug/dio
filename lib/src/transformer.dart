import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dio_error.dart';
import 'options.dart';
import 'adapter.dart';

/// [Transformer] allows changes to the request/response data before
/// it is sent/received to/from the server.
/// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'.
///
/// Dio has already implemented a [DefaultTransformer], and as the default
/// [Transformer]. If you want to custom the transformation of
/// request/response data, you can provide a [Transformer] by your self, and
/// replace the [DefaultTransformer] by setting the [dio.Transformer].

abstract class Transformer {

  /// `transformRequest` allows changes to the request data before it is
  /// sent to the server, but **after** the [RequestInterceptor].
  ///
  /// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'
  Future<String> transformRequest(RequestOptions options);

  /// `transformResponse` allows changes to the response data  before
  /// it is passed to [ResponseInterceptor].
  ///
  /// **Note**: As an agreement, you must return the [response]
  /// when the Options.responseType is [ResponseType.stream].
  Future transformResponse(RequestOptions options, ResponseBody response);

  /// Deep encode the [Map<String, dynamic>] to percent-encoding.
  /// It is mostly used with  the "application/x-www-form-urlencoded" content-type.
  static String urlEncodeMap(data) {
    StringBuffer urlData = new StringBuffer("");
    bool first = true;
    void urlEncode(dynamic sub, String path) {
      if (sub is List) {
        for (int i = 0; i < sub.length; i++) {
          urlEncode(sub[i], "$path%5B${(sub[i] is Map||sub[i] is List) ? i : ''}%5D");
        }
      } else if (sub is Map) {
        sub.forEach((k, v) {
          if (path == "") {
            urlEncode(v, "${Uri.encodeQueryComponent(k)}");
          } else {
            urlEncode(v, "$path%5B${Uri.encodeQueryComponent(k)}%5D");
          }
        });
      } else {
        if (!first) {
          urlData.write("&");
        }
        first = false;
        urlData.write("$path=${Uri.encodeQueryComponent(sub.toString())}");
      }
    }
    urlEncode(data, "");
    return urlData.toString();
  }
}

/// The default [Transformer] for [Dio]. If you want to custom the transformation of
/// request/response data, you can provide a [Transformer] by your self, and
/// replace the [DefaultTransformer] by setting the [dio.Transformer].

class DefaultTransformer extends Transformer {

  Future<String> transformRequest(RequestOptions options) async {
    var data = options.data ?? "";
    if (data is! String) {
      if (options.contentType.mimeType == ContentType.json.mimeType) {
        return json.encode(options.data);
      } else if (data is Map) {
        return Transformer.urlEncodeMap(data);
      }
    }
    return data.toString();
  }

  /// As an agreement, you must return the [response]
  /// when the Options.responseType is [ResponseType.stream].
  Future transformResponse(RequestOptions options, ResponseBody response) async {
    if (options.responseType == ResponseType.stream) {
      return response;
    }
    // Handle timeout
    Stream<List<int>> stream = response.stream;
    if (options.receiveTimeout > 0) {
      stream = stream.timeout(
          new Duration(milliseconds: options.receiveTimeout),
          onTimeout: (EventSink sink) {
            sink.addError(new DioError(
              message: "Receiving data timeout[${options
                  .receiveTimeout}ms]",
              type: DioErrorType.RECEIVE_TIMEOUT,
            ));
            sink.close();
          });
    }
    String responseBody = await stream.transform(Utf8Decoder(allowMalformed: true)).join();
    if (responseBody != null
        && responseBody.isNotEmpty
        && options.responseType == ResponseType.json
        && response.headers.contentType?.mimeType == ContentType.json.mimeType) {
      return json.decode(responseBody);
    }
    return responseBody;
  }
}
