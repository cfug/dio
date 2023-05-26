import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';

import '../adapter.dart';
import '../dio_exception.dart';
import '../options.dart';
import '../redirect_record.dart';

@Deprecated('Use IOHttpClientAdapter instead. This will be removed in 6.0.0')
typedef DefaultHttpClientAdapter = IOHttpClientAdapter;

@Deprecated('Use CreateHttpClient instead. This will be removed in 6.0.0')
typedef OnHttpClientCreate = HttpClient? Function(HttpClient client);

/// Can be used to provide a custom [HttpClient] for Dio.
typedef CreateHttpClient = HttpClient Function();

typedef ValidateCertificate = bool Function(
  X509Certificate? certificate,
  String host,
  int port,
);

HttpClientAdapter createAdapter() => IOHttpClientAdapter();

/// The default [HttpClientAdapter] for native platforms.
class IOHttpClientAdapter implements HttpClientAdapter {
  IOHttpClientAdapter({
    @Deprecated('Use createHttpClient instead. This will be removed in 6.0.0')
    this.onHttpClientCreate,
    this.createHttpClient,
    this.validateCertificate,
  });

  /// [Dio] will create [HttpClient] when it is needed. If [onHttpClientCreate]
  /// has provided, [Dio] will call it when a [HttpClient] created.
  @Deprecated('Use createHttpClient instead. This will be removed in 6.0.0')
  OnHttpClientCreate? onHttpClientCreate;

  /// When this callback is set, [Dio] will call it every
  /// time it needs a [HttpClient].
  CreateHttpClient? createHttpClient;

  /// Allows the user to decide if the response certificate is good.
  /// If this function is missing, then the certificate is allowed.
  /// This method is called only if both the [SecurityContext] and
  /// [badCertificateCallback] accept the certificate chain. Those
  /// methods evaluate the root or intermediate certificate, while
  /// [validateCertificate] evaluates the leaf certificate.
  ValidateCertificate? validateCertificate;

  HttpClient? _cachedHttpClient;

  bool _closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_closed) {
      throw StateError(
        "Can't establish connection after the adapter was closed!",
      );
    }
    final operation = CancelableOperation.fromFuture(_fetch(
      options,
      requestStream,
      cancelFuture,
    ));
    if (cancelFuture != null) {
      cancelFuture.whenComplete(() => operation.cancel());
    }
    return operation.value;
  }

  Future<ResponseBody> _fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final httpClient = _configHttpClient(options.connectTimeout);
    final reqFuture = httpClient.openUrl(options.method, options.uri);

    late HttpClientRequest request;
    try {
      final connectionTimeout = options.connectTimeout;
      if (connectionTimeout != null) {
        request = await reqFuture.timeout(
          connectionTimeout,
          onTimeout: () {
            throw DioException.connectionTimeout(
              requestOptions: options,
              timeout: connectionTimeout,
            );
          },
        );
      } else {
        request = await reqFuture;
      }

      if (cancelFuture != null) {
        cancelFuture.whenComplete(() => request.abort());
      }

      // Set Headers
      options.headers.forEach((k, v) {
        if (v != null) request.headers.set(k, v);
      });
    } on SocketException catch (e) {
      if (!e.message.contains('timed out')) {
        rethrow;
      }
      throw DioException.connectionTimeout(
        requestOptions: options,
        timeout: options.connectTimeout ??
            httpClient.connectionTimeout ??
            Duration.zero,
        error: e,
      );
    }

    request.followRedirects = options.followRedirects;
    request.maxRedirects = options.maxRedirects;
    request.persistentConnection = options.persistentConnection;

    if (requestStream != null) {
      // Transform the request data.
      Future<dynamic> future = request.addStream(requestStream);
      final sendTimeout = options.sendTimeout;
      if (sendTimeout != null) {
        future = future.timeout(
          sendTimeout,
          onTimeout: () {
            request.abort();
            throw DioException.sendTimeout(
              timeout: sendTimeout,
              requestOptions: options,
            );
          },
        );
      }
      await future;
    }

    final stopwatch = Stopwatch()..start();
    Future<HttpClientResponse> future = request.close();
    final receiveTimeout = options.receiveTimeout;
    if (receiveTimeout != null) {
      future = future.timeout(
        receiveTimeout,
        onTimeout: () {
          throw DioException.receiveTimeout(
            timeout: receiveTimeout,
            requestOptions: options,
          );
        },
      );
    }

    final responseStream = await future;

    if (validateCertificate != null) {
      final host = options.uri.host;
      final port = options.uri.port;
      final bool isCertApproved = validateCertificate!(
        responseStream.certificate,
        host,
        port,
      );
      if (!isCertApproved) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badCertificate,
          error: responseStream.certificate,
          message: 'The certificate of the response is not approved.',
        );
      }
    }

    final stream = responseStream.transform<Uint8List>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          stopwatch.stop();
          final duration = stopwatch.elapsed;
          final receiveTimeout = options.receiveTimeout;
          if (receiveTimeout != null && duration > receiveTimeout) {
            sink.addError(
              DioException.receiveTimeout(
                timeout: receiveTimeout,
                requestOptions: options,
              ),
            );
            responseStream.detachSocket().then((socket) => socket.destroy());
          } else {
            sink.add(Uint8List.fromList(data));
          }
        },
      ),
    );

    final headers = <String, List<String>>{};
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

  HttpClient _configHttpClient(Duration? connectionTimeout) {
    return (_cachedHttpClient ??= _createHttpClient())
      ..connectionTimeout = connectionTimeout;
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    _cachedHttpClient?.close(force: force);
  }

  HttpClient _createHttpClient() {
    if (createHttpClient != null) {
      return createHttpClient!();
    }
    final client = HttpClient()..idleTimeout = Duration(seconds: 3);
    return onHttpClientCreate?.call(client) ?? client;
  }
}
