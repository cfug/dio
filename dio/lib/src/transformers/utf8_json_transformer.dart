import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/src/compute/compute_io.dart';

/// A [Transformer] that has a fast path for decoding utf8-encoded JSON.
/// If the response is utf8-encoded JSON and no custom decoder for a Request is specified, this transformer
/// is significantly faster than the default [SyncTransformer] or [BackgroundTransformer].
/// This improvement is achieved by using a fused [Utf8Decoder] and [JsonDecoder] to decode the response,
/// which is faster than decoding the utf8-encoded JSON in two separate steps, since
/// Dart uses a special fast decoder for this case.
/// See https://github.com/dart-lang/sdk/blob/5b2ea0c7a227d91c691d2ff8cbbeb5f7f86afdb9/sdk/lib/_internal/vm/lib/convert_patch.dart#L40
///
/// By default, this transformer will transform responses in the main isolate,
/// but a custom threshold can be set to switch to an isolate for large responses by passing
/// [contentLengthIsolateThreshold].
class Utf8JsonTransformer extends Transformer {
  Utf8JsonTransformer({this.contentLengthIsolateThreshold = -1});

  /// decode the response in the main isolate
  factory Utf8JsonTransformer.sync() =>
      Utf8JsonTransformer(contentLengthIsolateThreshold: -1);

  // whether to switch decoding to an isolate for large responses
  // set to -1 to disable, 0 to always use isolate
  final int contentLengthIsolateThreshold;

  static final _utf8JsonDecoder = const Utf8Decoder().fuse(const JsonDecoder());

  @override
  Future<String> transformRequest(RequestOptions options) async {
    return Transformer.defaultTransformRequest(options, jsonEncode);
  }

  @override
  Future<dynamic> transformResponse(
      RequestOptions options, ResponseBody responseBody) async {
    final responseType = options.responseType;
    // Do not handle the body for streams.
    if (responseType == ResponseType.stream) {
      return responseBody;
    }

    // Return the finalized bytes if the response type is bytes.
    if (responseType == ResponseType.bytes) {
      return _consolidateStream(responseBody.stream);
    }

    final isJsonContent = Transformer.isJsonMimeType(
      responseBody.headers[Headers.contentTypeHeader]?.first,
    );

    final customResponseDecoder = options.responseDecoder;

    // no custom decoder was specified for the response,
    // and the response is json -> use the fast path decoder
    if (isJsonContent && customResponseDecoder == null) {
      return _fastUtf8JsonDecode(responseBody);
    }
    final responseBytes = await _consolidateStream(responseBody.stream);


    // a custom response decoder overrides the default behavior
    final String? decodedResponse;


    if (customResponseDecoder != null) {
      final decodeResponse = customResponseDecoder(
        responseBytes,
        options,
        responseBody..stream = const Stream.empty(),
      );

      if (decodeResponse is Future) {
        decodedResponse = await decodeResponse;
      } else {
        decodedResponse = decodeResponse;
      }
    } else {
      decodedResponse = null;
    }

    if (isJsonContent && decodedResponse != null) {
      // slow path decoder, since there was a custom decoder specified
      return jsonDecode(decodedResponse);
    } else if (decodedResponse != null) {
      return decodedResponse;
    } else {
      // If the response is not JSON and no custom decoder was specified,
      // assume it is an utf8 string
      return utf8.decode(
        responseBytes,
        allowMalformed: true,
      );
    }
  }

  Future<Object?> _fastUtf8JsonDecode(ResponseBody responseBody) async {
    final shouldUseIsolate = !(contentLengthIsolateThreshold < 0) &&
        responseBody.contentLength >= contentLengthIsolateThreshold;
    if (shouldUseIsolate) {
      return compute(
        _decodeUtf8ToJson,
        await _consolidateStream(responseBody.stream),
      );
    } else {
      if(responseBody.contentLength <= 0) {
        // server did not provide a valid content length, so we first consolidate the stream
        // to get the full response body
        final responseBytes = await _consolidateStream(responseBody.stream);
        if(responseBytes.isEmpty) {
          return null;
        }
        return _utf8JsonDecoder.convert(responseBytes);
      }
      final decodedStream = _utf8JsonDecoder.bind(responseBody.stream);
      final decoded = await decodedStream.toList();
      if(decoded.isEmpty) {
        return null;
      }
      assert(decoded.length == 1);
      return decoded.first;
    }
  }

  static Future<Object?> _decodeUtf8ToJson(Uint8List data) async {
    if (data.isEmpty) {
      return null;
    }
    return _utf8JsonDecoder.convert(data);
  }
}

/// Consolidates a stream of [Uint8List] into a single [Uint8List]
Future<Uint8List> _consolidateStream(Stream<Uint8List> stream) async {
  final chunks = <Uint8List>[];
  int totalLength = 0;

  await for (final chunk in stream) {
    totalLength += chunk.length;
    chunks.add(chunk);
  }

  // Allocate a buffer with the total length
  final result = Uint8List(totalLength);

  // Copy each chunk into the buffer
  int offset = 0;
  for (final chunk in chunks) {
    result.setRange(offset, offset + chunk.length, chunk);
    offset += chunk.length;
  }

  return result;
}
