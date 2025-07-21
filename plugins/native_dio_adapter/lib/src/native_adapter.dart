import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:dio/dio.dart';

import 'cronet_adapter.dart';
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
  NativeAdapter({
    CronetEngine Function()? createCronetEngine,
    URLSessionConfiguration Function()? createCupertinoConfiguration,
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
      _adapter = CronetAdapter(
        createCronetEngine?.call() ?? androidCronetEngine,
      );
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
