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
  Future<ResponseBody> sendRequest(
    RequestOptions options,
    Stream<List<int>> requestStream,
    CancelWrapper cancelWrapper,
    Future cancelFuture,
  );
}

class ResponseBody {
  ResponseBody(this.stream, this.statusCode, this.headers,
      {VoidCallback onClose})
      : _onClose = onClose;

  Stream<List<int>> stream;
  HttpHeaders headers;
  int statusCode;
  VoidCallback _onClose;

  ResponseBody.fromString(String text, this.statusCode, this.headers,
      {VoidCallback onClose})
      : _onClose = onClose,
        stream =
            Stream.fromIterable(utf8.encode(text).map((e) => [e]).toList());

  ResponseBody.fromBytes(List<int> bytes, this.statusCode, this.headers,
      {VoidCallback onClose})
      : _onClose = onClose,
        stream = Stream.fromIterable(bytes.map((e) => [e]).toList());

  void close() {
    if (_onClose != null) _onClose();
  }
}

/// The default HttpClientAdapter for Dio is [DefaultHttpClientAdapter].
class DefaultHttpClientAdapter extends HttpClientAdapter {
  HttpClient _httpClient;

  Future<ResponseBody> sendRequest(
    RequestOptions options,
    Stream<List<int>> requestStream,
    CancelWrapper cancelWrapper,
    Future cancelFuture,
  ) async {
    if (_httpClient == null) {
      _httpClient = _configHttpClient(new HttpClient(), true);
    }
    var httpClient = _httpClient;
    if (cancelFuture != null) {
      httpClient = _configHttpClient(new HttpClient());
      //if request was cancelled , close httpClient
      cancelFuture.then((e) => httpClient.close(force: true));
    }
    Future requestFuture;
    if (options.connectTimeout > 0) {
      requestFuture = httpClient
          .openUrl(options.method, options.uri)
          .timeout(new Duration(milliseconds: options.connectTimeout));
    } else {
      requestFuture = httpClient.openUrl(options.method, options.uri);
    }

    HttpClientRequest request;
    try {
      request = await cancelWrapper(requestFuture);
      //Set Headers
      options.headers.forEach((k, v) => request.headers.set(k, v));
    } on TimeoutException {
      throw new DioError(
        request: options,
        message: "Connecting timeout[${options.connectTimeout}ms]",
        type: DioErrorType.CONNECT_TIMEOUT,
      );
    }
    request.followRedirects = options.followRedirects;

    try {
      if (options.method != "GET" && requestStream != null) {
        // Transform the request data, set headers inner.
        await request.addStream(requestStream);
      }
    } catch (e) {
      //If user cancel the request in transformer, close the connect by hand.
      request.addError(e);
    }
    HttpClientResponse responseStream = await cancelWrapper(request.close());
    return new ResponseBody(
      responseStream,
      responseStream.statusCode,
      responseStream.headers,
      onClose:
          cancelFuture != null ? () => httpClient.close(force: true) : null,
    );
  }

  HttpClient _configHttpClient(HttpClient httpClient,
      [bool isDefault = false]) {
    httpClient.idleTimeout = new Duration(seconds: isDefault ? 3 : 0);
    if (onHttpClientCreate != null) {
      //user can return a new HttpClient instance
      httpClient = onHttpClientCreate(httpClient) ?? httpClient;
    }
    return httpClient;
  }

  /// [Dio] will create new HttpClient when it is needed.
  /// If [onHttpClientCreate] is provided, [Dio] will call
  /// it when a new HttpClient created.
  OnHttpClientCreate onHttpClientCreate;
}
