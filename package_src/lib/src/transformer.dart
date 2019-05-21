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
          urlEncode(sub[i],
              "$path%5B${(sub[i] is Map || sub[i] is List) ? i : ''}%5D");
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

typedef JsonDecodeCallback = dynamic Function(String);

class DefaultTransformer extends Transformer {
  DefaultTransformer({this.jsonDecodeCallback});

  JsonDecodeCallback jsonDecodeCallback;

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
  Future transformResponse(
      RequestOptions options, ResponseBody response) async {
    if (options.responseType == ResponseType.stream) {
      return response;
    }
    int length = 0;
    int received = 0;
    bool showDownloadProgress = options.onReceiveProgress != null;
    if (showDownloadProgress) {
      length = int.parse(
          response.headers.value(HttpHeaders.contentLengthHeader) ?? "-1");
    }
    Completer completer = new Completer();
    Stream<List<int>> stream = response.stream.transform<List<int>>(
        StreamTransformer.fromHandlers(handleData: (data, sink) {
      sink.add(data);
      if (showDownloadProgress) {
        received += data.length;
        options.onReceiveProgress(received, length);
      }
    }));
    List<int> buffer = new List<int>();
    StreamSubscription subscription;
    subscription = stream.listen(
      (element) => buffer.addAll(element),
      onError: (e) => completer.completeError(e),
      onDone: () => completer.complete(),
      cancelOnError: true,
    );
    // ignore: unawaited_futures
    options.cancelToken?.whenCancel?.then((_) {
      return subscription.cancel();
    });
    if (options.receiveTimeout > 0) {
      try {
        await completer.future
            .timeout(new Duration(milliseconds: options.receiveTimeout));
      } on TimeoutException {
        await subscription.cancel();
        throw DioError(
          request: options,
          message: "Receiving data timeout[${options.receiveTimeout}ms]",
          type: DioErrorType.RECEIVE_TIMEOUT,
        );
      }
    } else {
      await completer.future;
    }
    if (options.responseType == ResponseType.bytes) return buffer;
    String responseBody;
    if (options.responseDecoder != null) {
      responseBody = options.responseDecoder(buffer, options, response..stream=null);
    } else {
      responseBody = utf8.decode(buffer, allowMalformed: true);
    }
    if (responseBody != null &&
        responseBody.isNotEmpty &&
        options.responseType == ResponseType.json &&
        response.headers.contentType?.mimeType == ContentType.json.mimeType) {
      if (jsonDecodeCallback != null) {
        return jsonDecodeCallback(responseBody);
      } else {
        return json.decode(responseBody);
      }
    }
    return responseBody;
  }
}
