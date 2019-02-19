import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'options.dart';
import 'dio_error.dart';

typedef CancelWrapper = Future Function(Future);
typedef OnHttpClientCreate = dynamic Function(HttpClient client);
typedef VoidCallback = dynamic Function();

/// HttpAdapter is a bridge between Dio and HttpClient.
///
/// Dio: Implements standard and friendly API for developer.
///
/// HttpClient: It is the real object that makes Http
/// requests.
///
/// We can use any HttpClient not just "dart:io:HttpClient" to
/// make the Http request. All we need is providing a [HttpClientAdapter].
///
/// The default HttpClientAdapter for Dio is [DefaultHttpClientAdapter].
///
/// ```dart
/// dio.httpClientAdapter = new DefaultHttpClientAdapter();
/// ```
abstract class HttpClientAdapter {
  /// We should implement this method to make real http requests.
  ///
  /// [options]: The request options
  ///
  /// [requestStream] The request stream, It will not be null
  /// only when http method is one of "POST","PUT","PATCH"
  /// and the request body is not empty.
  ///
  /// We should give priority to using requestStream(not options.data) as request data.
  /// because supporting stream ensures the `onSendProgress` works.
  ///
  /// [cancelFuture]: When  cancelled the request, [cancelFuture] will be resolved!
  /// you can listen cancel event by it, for example:
  ///
  /// ```dart
  ///  cancelFuture?.then((_)=>print("request cancelled!"))
  /// ```
  /// [cancelFuture]: will be null when the request is not set [CancelToken].
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>> requestStream,
    Future cancelFuture,
  );
}

class ResponseBody {
  ResponseBody(
    this.stream,
    this.statusCode,
    this.headers,
  );

  /// The response stream
  Stream<List<int>> stream;

  /// the response headers
  HttpHeaders headers;

  /// Http status code
  int statusCode;

  ResponseBody.fromString(String text, this.statusCode, this.headers)
      : stream =
            Stream.fromIterable(utf8.encode(text).map((e) => [e]).toList());

  ResponseBody.fromBytes(List<int> bytes, this.statusCode, this.headers)
      : stream = Stream.fromIterable(bytes.map((e) => [e]).toList());
}

/// The default HttpClientAdapter for Dio is [DefaultHttpClientAdapter].
class DefaultHttpClientAdapter extends HttpClientAdapter {
  HttpClient _httpClient;

  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>> requestStream,
    Future cancelFuture,
  ) async {
    _configHttpClient();
    Future requestFuture;
    if (options.connectTimeout > 0) {
      requestFuture = _httpClient
          .openUrl(options.method, options.uri)
          .timeout(new Duration(milliseconds: options.connectTimeout));
    } else {
      requestFuture = _httpClient.openUrl(options.method, options.uri);
    }

    HttpClientRequest request;
    try {
      request = await requestFuture;
      //Set Headers
      options.headers.forEach((k, v) => request.headers.set(k, v));
    } on TimeoutException {
      throw DioError(
        request: options,
        message: "Connecting timeout[${options.connectTimeout}ms]",
        type: DioErrorType.CONNECT_TIMEOUT,
      );
    }
    request.followRedirects = options.followRedirects;

    if (options.method != "GET" && requestStream != null) {
      // Transform the request data
      await request.addStream(requestStream);
    }

    HttpClientResponse responseStream = await request.close();
    return new ResponseBody(
      responseStream,
      responseStream.statusCode,
      responseStream.headers,
    );
  }


  void _configHttpClient() {
    if (_httpClient == null) _httpClient = new HttpClient();
    _httpClient.idleTimeout = new Duration(seconds: 3);
    if (onHttpClientCreate != null) {
      //user can return a new HttpClient instance
      _httpClient = onHttpClientCreate(_httpClient) ?? _httpClient;
    }
  }

  /// [Dio] will create new HttpClient when it is needed.
  /// If [onHttpClientCreate] is provided, [Dio] will call
  /// it when a new HttpClient created.
  OnHttpClientCreate onHttpClientCreate;
}
