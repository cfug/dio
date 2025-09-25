import 'dart:developer';
import 'dart:typed_data' show Uint8List;

import 'package:cronet_http/cronet_http.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'conversion_layer_adapter.dart';

/// A [HttpClientAdapter] for Dio which delegates HTTP requests
/// to the native platform by making use of
/// [cronet_http](https://pub.dev/packages/cronet_http).
class CronetAdapter implements HttpClientAdapter {
  CronetAdapter(
    CronetEngine? engine, {
    bool closeEngine = true,
  })  : _engine = engine,
        _closeEngine = closeEngine;

  final CronetEngine? _engine;
  final bool _closeEngine;

  late final ConversionLayerAdapter _conversionLayer = () {
    Client client;

    try {
      client = CronetClient.fromCronetEngine(
        _engine ?? CronetEngine.build(),
        closeEngine: _closeEngine,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to create CronetClient, falling back to IOClient',
        error: error,
        stackTrace: stackTrace,
      );

      client = IOClient();
    }

    return ConversionLayerAdapter(client);
  }();

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
