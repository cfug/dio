import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../adapter.dart';
import '../dio_error.dart';
import '../options.dart';
import '../redirect_record.dart';

@Deprecated('Use IOHttpClientAdapter instead. This will be removed in 6.0.0')
typedef DefaultHttpClientAdapter = IOHttpClientAdapter;

typedef OnHttpClientCreate = HttpClient? Function(HttpClient client);
typedef ValidateCertificate = bool Function(
  X509Certificate? certificate,
  String host,
  int port,
);

HttpClientAdapter createAdapter() => IOHttpClientAdapter();

/// The default [HttpClientAdapter] for native platforms.
class IOHttpClientAdapter implements HttpClientAdapter {
  /// [Dio] will create HttpClient when it is needed.
  /// If [onHttpClientCreate] is provided, [Dio] will call
  /// it when a HttpClient created.
  OnHttpClientCreate? onHttpClientCreate;

  /// Allows the user to decide if the response certificate is good.
  /// If this function is missing, then the certificate is allowed.
  /// This method is called only if both the [SecurityContext] and
  /// [badCertificateCallback] accept the certificate chain. Those
  /// methods evaluate the root or intermediate certificate, while
  /// [validateCertificate] evaluates the leaf certificate.
  ValidateCertificate? validateCertificate;

  HttpClient? _defaultHttpClient;

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
    final httpClient = _configHttpClient(cancelFuture, options.connectTimeout);
    final reqFuture = httpClient.openUrl(options.method, options.uri);

    late HttpClientRequest request;
    try {
      final connectionTimeout = options.connectTimeout;
      if (connectionTimeout != null) {
        request = await reqFuture.timeout(
          connectionTimeout,
          onTimeout: () {
            throw DioError.connectionTimeout(
              requestOptions: options,
              timeout: connectionTimeout,
            );
          },
        );
      } else {
        request = await reqFuture;
      }

      // Set Headers
      options.headers.forEach((k, v) {
        if (v != null) request.headers.set(k, v);
      });
    } on SocketException catch (e, stackTrace) {
      if (!e.message.contains('timed out')) {
        rethrow;
      }
      throw DioError.connectionTimeout(
        requestOptions: options,
        timeout: options.connectTimeout ??
            httpClient.connectionTimeout ??
            Duration.zero,
        error: e,
        stackTrace: stackTrace,
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
            throw DioError.sendTimeout(
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
          throw DioError.receiveTimeout(
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
        throw DioError(
          requestOptions: options,
          type: DioErrorType.badCertificate,
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
              DioError.receiveTimeout(
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

  HttpClient _configHttpClient(
    Future<void>? cancelFuture,
    Duration? connectionTimeout,
  ) {
    HttpClient client = onHttpClientCreate?.call(HttpClient()) ?? HttpClient();
    if (cancelFuture != null) {
      client.userAgent = null;
      client.idleTimeout = Duration(seconds: 0);
      cancelFuture.whenComplete(() => client.close(force: true));
      return client..connectionTimeout = connectionTimeout;
    }
    if (_defaultHttpClient == null) {
      client.idleTimeout = Duration(seconds: 3);
      if (onHttpClientCreate?.call(client) != null) {
        client = onHttpClientCreate!(client)!;
      }
      client.connectionTimeout = connectionTimeout;
      _defaultHttpClient = client;
    }
    return _defaultHttpClient!..connectionTimeout = connectionTimeout;
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    _defaultHttpClient?.close(force: force);
  }
}
