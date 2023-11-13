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

/// The signature of [IOHttpClientAdapter.onHttpClientCreate].
@Deprecated('Use CreateHttpClient instead. This will be removed in 6.0.0')
typedef OnHttpClientCreate = HttpClient? Function(HttpClient client);

/// The signature of [IOHttpClientAdapter.createHttpClient].
/// Can be used to provide a custom [HttpClient] for Dio.
typedef CreateHttpClient = HttpClient Function();

/// The signature of [IOHttpClientAdapter.validateCertificate].
typedef ValidateCertificate = bool Function(
  X509Certificate? certificate,
  String host,
  int port,
);

/// Creates an [IOHttpClientAdapter].
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
        "Can't establish connection after the adapter was closed.",
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

    HttpClientRequest? clientRequest;
    HttpClientResponse? clientResponse;
    EventSink<Uint8List>? responseSink;

    if (cancelFuture != null) {
      cancelFuture.whenComplete(() {
        clientRequest?.abort();
        clientResponse?.detachSocket().then((socket) => socket.destroy());
        responseSink?.addError(
          DioException.requestCancelled(requestOptions: options, reason: null),
        );
        responseSink = null;
      });
    }

    try {
      final connectionTimeout = options.connectTimeout;
      if (connectionTimeout != null) {
        clientRequest = await reqFuture.timeout(
          connectionTimeout,
          onTimeout: () {
            throw DioException.connectionTimeout(
              requestOptions: options,
              timeout: connectionTimeout,
            );
          },
        );
      } else {
        clientRequest = await reqFuture;
      }

      // Set Headers
      options.headers.forEach((k, v) {
        if (v != null) {
          clientRequest?.headers.set(k, v);
        }
      });
    } on SocketException catch (e) {
      if (e.message.contains('timed out')) {
        throw DioException.connectionTimeout(
          requestOptions: options,
          timeout: options.connectTimeout ??
              httpClient.connectionTimeout ??
              Duration.zero,
          error: e,
        );
      }
      throw DioException.connectionError(
        requestOptions: options,
        reason: e.message,
        error: e,
      );
    }

    clientRequest.followRedirects = options.followRedirects;
    clientRequest.maxRedirects = options.maxRedirects;
    clientRequest.persistentConnection = options.persistentConnection;

    if (requestStream != null) {
      // Transform the request data.
      Future<dynamic> future = clientRequest.addStream(requestStream);
      final sendTimeout = options.sendTimeout;
      if (sendTimeout != null) {
        future = future.timeout(
          sendTimeout,
          onTimeout: () {
            clientRequest?.abort();
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
    Future<HttpClientResponse> future = clientRequest.close();
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

    clientResponse = await future;

    if (validateCertificate != null) {
      final host = options.uri.host;
      final port = options.uri.port;
      final bool isCertApproved = validateCertificate!(
        clientResponse.certificate,
        host,
        port,
      );
      if (!isCertApproved) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badCertificate,
          error: clientResponse.certificate,
          message: 'The certificate of the response is not approved.',
        );
      }
    }

    final stream = clientResponse.transform<Uint8List>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          responseSink ??= sink;
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
            clientResponse?.detachSocket().then((socket) => socket.destroy());
          } else {
            sink.add(Uint8List.fromList(data));
          }
        },
        handleError: (error, stackTrace, sink) {
          responseSink = null;
        },
        handleDone: (sink) {
          responseSink = null;
        },
      ),
    );

    final headers = <String, List<String>>{};
    clientResponse.headers.forEach((key, values) {
      headers[key] = values;
    });

    final body = ResponseBody(
      stream,
      clientResponse.statusCode,
      headers: headers,
      isRedirect:
          clientResponse.isRedirect || clientResponse.redirects.isNotEmpty,
      redirects: clientResponse.redirects
          .map((e) => RedirectRecord(e.statusCode, e.method, e.location))
          .toList(),
      statusMessage: clientResponse.reasonPhrase,
    );
    clientRequest = null;
    clientResponse = null;
    return body;
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
    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
    return onHttpClientCreate?.call(client) ?? client;
  }
}
