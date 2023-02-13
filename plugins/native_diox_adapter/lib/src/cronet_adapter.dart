import 'dart:typed_data';

import 'package:cronet_http/cronet_client.dart';
import 'package:diox/diox.dart';
import 'conversion_layer_adapter.dart';

/// A [HttpClientAdapter] for Dio which delegates HTTP requests
/// to the native platform by making use of
/// [cronet_http](https://pub.dev/packages/cronet_http).
class CronetAdapter implements HttpClientAdapter {
  CronetAdapter(CronetEngine? engine)
      : _conversionLayer = ConversionLayerAdapter(CronetClient(engine));

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
