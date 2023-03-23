import 'dart:typed_data';

import 'package:cupertino_http/cupertino_http.dart';
import 'package:dio/dio.dart';
import 'conversion_layer_adapter.dart';

/// A [HttpClientAdapter] for Dio which delegates HTTP requests
/// to the native platform by making use of
/// [cupertino_http](https://pub.dev/packages/cupertino_http).
class CupertinoAdapter implements HttpClientAdapter {
  CupertinoAdapter(
    URLSessionConfiguration configuration,
  ) : _conversionLayer = ConversionLayerAdapter(
          CupertinoClient.fromSessionConfiguration(configuration),
        );

  final ConversionLayerAdapter _conversionLayer;

  @override
  void close({bool force = false}) => _conversionLayer.close(force: force);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) =>
      _conversionLayer.fetch(options, requestStream, cancelFuture);
}
