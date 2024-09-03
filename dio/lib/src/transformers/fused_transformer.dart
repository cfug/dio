import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../adapter.dart';
import '../compute/compute.dart';
import '../headers.dart';
import '../options.dart';
import '../transformer.dart';
import 'util/consolidate_bytes.dart';
import 'util/transform_empty_to_null.dart';

/// A [Transformer] that has a fast path for decoding UTF8-encoded JSON.
/// If the response is utf8-encoded JSON and no custom decoder is specified in the [RequestOptions], this transformer
/// is significantly faster than the default [SyncTransformer] and the [BackgroundTransformer].
/// This improvement is achieved by using a fused [Utf8Decoder] and [JsonDecoder] to decode the response,
/// which is faster than decoding the utf8-encoded JSON in two separate steps, since
/// Dart uses a special fast decoder for this case.
/// See https://github.com/dart-lang/sdk/blob/5b2ea0c7a227d91c691d2ff8cbbeb5f7f86afdb9/sdk/lib/_internal/vm/lib/convert_patch.dart#L40
///
/// By default, this transformer will transform responses in the main isolate,
/// but a custom threshold can be set to switch to an isolate for large responses by passing
/// [contentLengthIsolateThreshold].
class FusedTransformer extends Transformer {
  FusedTransformer({
    this.contentLengthIsolateThreshold = -1,
  });

  /// Always decode the response in the same isolate
  factory FusedTransformer.sync() => FusedTransformer(
        contentLengthIsolateThreshold: -1,
      );

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
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    final responseType = options.responseType;
    // Do not handle the body for streams.
    if (responseType == ResponseType.stream) {
      return responseBody;
    }

    // Return the finalized bytes if the response type is bytes.
    if (responseType == ResponseType.bytes) {
      return consolidateBytes(responseBody.stream);
    }

    final isJsonContent = Transformer.isJsonMimeType(
          responseBody.headers[Headers.contentTypeHeader]?.first,
        ) &&
        responseType == ResponseType.json;

    final customResponseDecoder = options.responseDecoder;

    // No custom decoder was specified for the response,
    // and the response is json -> use the fast path decoder
    if (isJsonContent && customResponseDecoder == null) {
      return _fastUtf8JsonDecode(options, responseBody);
    }
    final responseBytes = await consolidateBytes(responseBody.stream);

    // A custom response decoder overrides the default behavior
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
    } else if (customResponseDecoder != null) {
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

  Future<Object?> _fastUtf8JsonDecode(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    final contentLengthHeader =
        responseBody.headers[Headers.contentLengthHeader];

    final hasContentLengthHeader =
        contentLengthHeader != null && contentLengthHeader.isNotEmpty;

    // The content length of the response, either from the content-length header
    // of the response or the length of the eagerly decoded response bytes
    final int contentLength;

    // The eagerly decoded response bytes
    // which is set if the content length is not specified and
    // null otherwise (we'll feed the stream directly to the decoder in that case)
    Uint8List? responseBytes;

    // If the content length is not specified, we need to consolidate the stream
    // and count the bytes to determine if we should use an isolate
    // otherwise we use the content length header
    if (!hasContentLengthHeader) {
      responseBytes = await consolidateBytes(responseBody.stream);
      contentLength = responseBytes.length;
    } else {
      contentLength = int.parse(contentLengthHeader.first);
    }

    // The decoding in done on an isolate if
    // - contentLengthIsolateThreshold is not -1
    // - the content length, calculated from either
    //   the content-length header if present or the eagerly decoded response bytes,
    //   is greater than or equal to contentLengthIsolateThreshold
    final shouldUseIsolate = !(contentLengthIsolateThreshold < 0) &&
        contentLength >= contentLengthIsolateThreshold;
    if (shouldUseIsolate) {
      // we can't send the stream to the isolate, so we need to decode the response bytes first
      return compute(
        _decodeUtf8ToJson,
        responseBytes ?? await consolidateBytes(responseBody.stream),
      );
    } else {
      if (responseBytes != null) {
        if (responseBytes.isEmpty) {
          return null;
        }
        return _utf8JsonDecoder.convert(responseBytes);
      } else {
        assert(responseBytes == null);
        // The content length is specified and we can feed the stream directly to the decoder,
        // without eagerly decoding the response bytes first.
        // If the response is empty, return null;
        // This is done by the DefaultNullIfEmptyStreamTransformer
        final streamWithNullFallback = responseBody.stream
            .transform(const DefaultNullIfEmptyStreamTransformer());
        final decodedStream = _utf8JsonDecoder.bind(streamWithNullFallback);
        final decoded = await decodedStream.toList();
        if (decoded.isEmpty) {
          return null;
        }
        assert(decoded.length == 1);
        return decoded.first;
      }
    }
  }

  static Future<Object?> _decodeUtf8ToJson(Uint8List data) async {
    if (data.isEmpty) {
      return null;
    }
    return _utf8JsonDecoder.convert(data);
  }
}
