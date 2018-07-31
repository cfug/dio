import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/src/Options.dart';

/// [TransFormer] allows changes to the request/response data before
/// it is sent/received to/from the server.
/// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'.
///
/// Dio has already implemented a [DefaultTransformer], and as the default
/// [TransFormer]. If you want to custom the transformation of
/// request/response data, you can provide a [TransFormer] by your self, and
/// replace the [DefaultTransformer] by setting the [dio.transformer].

abstract class TransFormer {
  /// `transformRequest` allows changes to the request data before it is
  /// sent to the server, but **after** the [RequestInterceptor].
  ///
  /// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'
  Future transformRequest(Options options);

  /// `transformResponse` allows changes to the response data  before
  /// it is passed to [ResponseInterceptor].
  ///
  /// **Note**: As an agreement, you must return the [response]
  /// when the Options.responseType is [ResponseType.STREAM].
  Future transformResponse(Options options, HttpClientResponse response);

  /// Deep encode the [Map<String, dynamic>] to percent-encoding.
  /// It is mostly used with  the "application/x-www-form-urlencoded" content-type.
  static String urlEncodeMap(data) {
    StringBuffer urlData = new StringBuffer("");
    bool first = true;
    void urlEncode(dynamic sub, String path) {
      if (sub is List) {
        for (int i = 0; i < sub.length; i++) {
          urlEncode(sub[i], "$path%5B%5D");
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

/// The default [TransFormer] for [Dio]. If you want to custom the transformation of
/// request/response data, you can provide a [TransFormer] by your self, and
/// replace the [DefaultTransformer] by setting the [dio.transformer].

class DefaultTransformer extends TransFormer {
  Future transformRequest(Options options) async {
    var data = options.data ?? "";
    if (data is! String) {
      if (options.contentType.mimeType == ContentType.json.mimeType) {
        return json.encode(options.data);
      } else if (data is Map) {
        return TransFormer.urlEncodeMap(data);
      }
    }
    return data.toString();
  }

  /// As an agreement, you must return the [response]
  /// when the Options.responseType is [ResponseType.STREAM].
  Future transformResponse(Options options, HttpClientResponse response) async {
    if (options.responseType == ResponseType.STREAM) {
      return response;
    }
    // Handle timeout
    Stream<List<int>> stream = response;
    if (options.receiveTimeout > 0) {
      stream = stream
          .timeout(new Duration(milliseconds: options.receiveTimeout),
              onTimeout: (EventSink sink) {
        sink.addError(new DioError(
          message: "Receiving data timeout[${options.receiveTimeout}ms]",
          type: DioErrorType.RECEIVE_TIMEOUT,
        ));
        sink.close();
      });
    }
    String responseBody = await stream.transform(utf8.decoder).join();
    if (options.responseType == ResponseType.JSON &&
        response.headers.contentType?.mimeType == ContentType.json.mimeType) {
      return json.decode(responseBody);
    }
    return responseBody;
  }
}
