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
    cancelFuture?.whenComplete(() => operation.cancel());
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
      if (connectionTimeout != null && connectionTimeout > Duration.zero) {
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

      cancelFuture?.whenComplete(() => request.abort());

      // Set Headers
      options.headers.forEach((key, value) {
        if (value != null) {
          request.headers.set(
            key,
            value,
            preserveHeaderCase: options.preserveHeaderCase,
          );
        }
      });
    } on SocketException catch (e) {
      if (e.message.contains('timed out')) {
        final Duration effectiveTimeout;
        if (options.connectTimeout != null &&
            options.connectTimeout! > Duration.zero) {
          effectiveTimeout = options.connectTimeout!;
        } else if (httpClient.connectionTimeout != null &&
            httpClient.connectionTimeout! > Duration.zero) {
          effectiveTimeout = httpClient.connectionTimeout!;
        } else {
          effectiveTimeout = Duration.zero;
        }
        throw DioException.connectionTimeout(
          requestOptions: options,
          timeout: effectiveTimeout,
          error: e,
        );
      }
      throw DioException.connectionError(
        requestOptions: options,
        reason: e.message,
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
      if (sendTimeout != null && sendTimeout > Duration.zero) {
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

    Future<HttpClientResponse> future = request.close();
    final receiveTimeout = options.receiveTimeout ?? Duration.zero;
    if (receiveTimeout > Duration.zero) {
      future = future.timeout(
        receiveTimeout,
        onTimeout: () {
          request.abort();
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

    // Use a StreamController to explicitly handle receive timeouts.
    final responseSink = StreamController<Uint8List>();
    late StreamSubscription<List<int>> responseSubscription;

    final receiveStopwatch = Stopwatch();
    Timer? receiveTimer;

    void stopWatchReceiveTimeout() {
      receiveTimer?.cancel();
      receiveTimer = null;
      receiveStopwatch.stop();
    }

    void watchReceiveTimeout() {
      if (receiveTimeout <= Duration.zero) {
        return;
      }
      receiveStopwatch.reset();
      if (!receiveStopwatch.isRunning) {
        receiveStopwatch.start();
      }
      receiveTimer?.cancel();
      receiveTimer = Timer(receiveTimeout, () {
        responseSink.addError(
          DioException.receiveTimeout(
            timeout: receiveTimeout,
            requestOptions: options,
          ),
        );
        responseSink.close();
        responseSubscription.cancel();
        responseStream.detachSocket().then((socket) => socket.destroy());
        stopWatchReceiveTimeout();
      });
    }

    responseSubscription = responseStream.cast<Uint8List>().listen(
      (data) {
        watchReceiveTimeout();
        // Always true if the receive timeout was not set.
        if (receiveStopwatch.elapsed <= receiveTimeout) {
          responseSink.add(data);
        }
      },
      onError: (error, stackTrace) {
        stopWatchReceiveTimeout();
        responseSink.addError(error, stackTrace);
        responseSink.close();
      },
      onDone: () {
        stopWatchReceiveTimeout();
        responseSubscription.cancel();
        responseSink.close();
      },
      cancelOnError: true,
    );

    cancelFuture?.whenComplete(() {
      /// Close the stream upon a cancellation.
      responseSubscription.cancel();
      if (!responseSink.isClosed) {
        /// If the request was aborted via [Request.abort], then the
        /// [responseSubscription] may have emitted a done event already.
        responseSink.addError(options.cancelToken!.cancelError!);
        responseSink.close();
      }
    });

    final headers = <String, List<String>>{};
    responseStream.headers.forEach((key, values) {
      headers[key] = values;
    });
    return ResponseBody(
      responseSink.stream,
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
    _cachedHttpClient ??= _createHttpClient();
    connectionTimeout ??= Duration.zero;
    if (connectionTimeout > Duration.zero) {
      _cachedHttpClient!.connectionTimeout = connectionTimeout;
    } else {
      _cachedHttpClient!.connectionTimeout = null;
    }
    return _cachedHttpClient!;
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
