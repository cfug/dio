import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../adapter.dart';
import '../dio_error.dart';
import '../options.dart';
import '../redirect_record.dart';

typedef OnHttpClientCreate = HttpClient? Function(HttpClient client);

HttpClientAdapter createAdapter() => DefaultHttpClientAdapter();

/// The default HttpClientAdapter for Dio.
class DefaultHttpClientAdapter implements HttpClientAdapter {
  /// [Dio] will create HttpClient when it is needed.
  /// If [onHttpClientCreate] is provided, [Dio] will call
  /// it when a HttpClient created.
  OnHttpClientCreate? onHttpClientCreate;

  HttpClient? _defaultHttpClient;

  bool _closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_closed) {
      throw Exception(
          "Can't establish connection after [HttpClientAdapter] closed!");
    }
    var _httpClient = _configHttpClient(cancelFuture, options.connectTimeout);
    var reqFuture = _httpClient.openUrl(options.method, options.uri);

    late HttpClientRequest request;
    try {
      final connectionTimeout = options.connectTimeout;
      if (connectionTimeout != null) {
        request = await reqFuture.timeout(
          connectionTimeout,
          onTimeout: () {
            throw DioError.connectionTimeout(
              requestOptions: options,
              timeout: options.connectTimeout!,
            );
          },
        );
      } else {
        request = await reqFuture;
      }

      //Set Headers
      options.headers.forEach((k, v) {
        if (v != null) request.headers.set(k, '$v');
      });
    } on SocketException catch (e, stackTrace) {
      if (!e.message.contains('timed out')) {
        rethrow;
      }
      throw DioError.connectionTimeout(
        requestOptions: options,
        timeout: options.connectTimeout ??
            _httpClient.connectionTimeout ??
            Duration(),
        error: e,
        stackTrace: stackTrace,
      );
    }

    request.followRedirects = options.followRedirects;
    request.maxRedirects = options.maxRedirects;

    if (requestStream != null) {
      // Transform the request data
      var future = request.addStream(requestStream);

      final sendTimeout = options.sendTimeout;
      if (sendTimeout != null) {
        future = future.timeout(
          sendTimeout,
          onTimeout: () {
            throw DioError.sendTimeout(
              timeout: options.sendTimeout!,
              requestOptions: options,
            );
          },
        );
      }

      await future;
    }

    final stopwatch = Stopwatch()..start();
    var future = request.close();
    final receiveTimeout = options.receiveTimeout;
    if (receiveTimeout != null) {
      future = future.timeout(
        receiveTimeout,
        onTimeout: () {
          throw DioError.receiveTimeout(
            timeout: options.receiveTimeout!,
            requestOptions: options,
          );
        },
      );
    }

    final responseStream = await future;

    var stream =
        responseStream.transform<Uint8List>(StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        stopwatch.stop();
        final duration = stopwatch.elapsed;
        final receiveTimeout = options.receiveTimeout;
        if (receiveTimeout != null && duration > receiveTimeout) {
          sink.addError(
            DioError.receiveTimeout(
              timeout: options.receiveTimeout!,
              requestOptions: options,
            ),
          );
          //todo: to verify
          responseStream.detachSocket().then((socket) => socket.close());
        } else {
          sink.add(Uint8List.fromList(data));
        }
      },
    ));

    var headers = <String, List<String>>{};
    responseStream.headers.forEach((key, values) {
      headers[key] = values;
    });
    return ResponseBody(
      stream,
      responseStream.statusCode,
      headers: headers,
      isRedirect:
          responseStream.isRedirect || responseStream.redirects.isNotEmpty,
      redirects: responseStream.redirects
          .map((e) => RedirectRecord(e.statusCode, e.method, e.location))
          .toList(),
      statusMessage: responseStream.reasonPhrase,
    );
  }

  HttpClient _configHttpClient(
    Future? cancelFuture,
    Duration? connectionTimeout,
  ) {
    if (cancelFuture != null) {
      var _httpClient = HttpClient();
      _httpClient.userAgent = null;
      if (onHttpClientCreate != null) {
        //user can return a HttpClient instance
        _httpClient = onHttpClientCreate!(_httpClient) ?? _httpClient;
      }
      _httpClient.idleTimeout = Duration(seconds: 0);
      cancelFuture.whenComplete(() {
        Future.delayed(Duration(seconds: 0)).then((e) {
          try {
            _httpClient.close(force: true);
          } catch (e) {
            //...
          }
        });
      });
      return _httpClient..connectionTimeout = connectionTimeout;
    }
    if (_defaultHttpClient == null) {
      _defaultHttpClient = HttpClient();
      _defaultHttpClient!.idleTimeout = Duration(seconds: 3);
      if (onHttpClientCreate != null) {
        //user can return a HttpClient instance
        _defaultHttpClient =
            onHttpClientCreate!(_defaultHttpClient!) ?? _defaultHttpClient;
      }
      _defaultHttpClient!.connectionTimeout = connectionTimeout;
    }
    return _defaultHttpClient!;
  }

  @override
  void close({bool force = false}) {
    _closed = _closed;
    _defaultHttpClient?.close(force: force);
  }
}
