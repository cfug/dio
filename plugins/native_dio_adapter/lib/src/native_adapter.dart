import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:dio/dio.dart';

import 'cronet_adapter.dart';
import 'cronet_fallback_adapter.dart';
import 'cupertino_adapter.dart';

/// A [HttpClientAdapter] for Dio which delegates HTTP requests
/// to the native platform, where possible.
///
/// On iOS and macOS this uses [cupertino_http](https://pub.dev/packages/cupertino_http)
/// to make HTTP requests.
///
/// On Android this uses [cronet_http](https://pub.dev/packages/cronet_http) to
/// make HTTP requests.
class NativeAdapter implements HttpClientAdapter {
  /// Creates a [NativeAdapter].
  ///
  /// {@template native_dio_adapter.NativeAdapter.createFallbackAdapter}
  /// [createFallbackAdapter] is an **opt-in** fallback for Android devices on
  /// which every installed Cronet provider is disabled (for example, AOSP
  /// emulators or devices without Google Play services, see
  /// [issue #2444](https://github.com/cfug/dio/issues/2444)). It is invoked
  /// **only** when Cronet reports that all providers are disabled; every other
  /// error — including connection, TLS, timeout, redirect, cancellation, and
  /// response-stream errors — remains a Cronet error and is propagated
  /// unchanged.
  ///
  /// The factory returns any [HttpClientAdapter]. This lets callers choose an
  /// adapter that matches their TLS, proxy, cookie, transport, and
  /// observability requirements (for example, `IOHttpClientAdapter` from
  /// `package:dio` or a custom adapter). Note: switching adapters can change
  /// observable networking behavior — TLS configuration, proxy handling,
  /// cookies, supported protocols, connection pooling, etc. Callers opting in
  /// own that tradeoff.
  ///
  /// Detection happens synchronously before the first request is delegated.
  /// After that, the selection is sticky for the lifetime of this
  /// [NativeAdapter]; later requests do not probe Cronet again. Closing this
  /// [NativeAdapter] before any request is made does **not** initialize
  /// Cronet or create the fallback.
  ///
  /// Defaults to `null`. When omitted, [NativeAdapter] continues to use
  /// Cronet and propagates initialization errors exactly as it did before.
  /// This factory is only consulted on Android; it is ignored on other
  /// platforms.
  ///
  /// Example:
  ///
  /// ```dart
  /// NativeAdapter(
  ///   createFallbackAdapter: (error, stackTrace) => IOHttpClientAdapter(),
  /// )
  /// ```
  /// {@endtemplate}
  NativeAdapter({
    CronetEngine Function()? createCronetEngine,
    URLSessionConfiguration Function()? createCupertinoConfiguration,
    CreateFallbackAdapter? createFallbackAdapter,
    @Deprecated(
      'Use createCronetEngine instead. '
      'This will cause platform exception on iOS/macOS platforms. '
      'This will be removed in v2.0.0',
    )
    CronetEngine? androidCronetEngine,
    @Deprecated(
      'Use createCupertinoConfiguration instead. '
      'This will cause platform exception on the Android platform. '
      'This will be removed in v2.0.0',
    )
    URLSessionConfiguration? cupertinoConfiguration,
  }) {
    if (Platform.isAndroid) {
      if (createFallbackAdapter != null) {
        _adapter = CronetWithFallbackAdapter(
          createCronetEngine: createCronetEngine,
          androidCronetEngine: androidCronetEngine,
          createFallbackAdapter: createFallbackAdapter,
        );
      } else {
        _adapter = CronetAdapter(
          createCronetEngine?.call() ?? androidCronetEngine,
        );
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      _adapter = CupertinoAdapter(
        createCupertinoConfiguration?.call() ??
            cupertinoConfiguration ??
            URLSessionConfiguration.defaultSessionConfiguration(),
      );
    } else {
      _adapter = HttpClientAdapter();
    }
  }

  late final HttpClientAdapter _adapter;

  /// The underlying client adapter.
  HttpClientAdapter get adapter => _adapter;

  @override
  void close({bool force = false}) => _adapter.close(force: force);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) =>
      _adapter.fetch(options, requestStream, cancelFuture);
}
