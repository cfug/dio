import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../adapter.dart';
import '../headers.dart';
import '../options.dart';
import '../transformer.dart';

@Deprecated('Use BackgroundTransformer instead')
typedef DefaultTransformer = SyncTransformer;

/// The callback definition for decoding a JSON string.
typedef JsonDecodeCallback = FutureOr<dynamic> Function(String);

/// The callback definition for encoding a JSON object.
typedef JsonEncodeCallback = FutureOr<String> Function(Object);

/// If you want to custom the transformation of request/response data,
/// you can provide a [Transformer] by your self, and replace
/// the transformer by setting the [Dio.transformer].
class SyncTransformer extends Transformer {
  SyncTransformer({
    this.jsonDecodeCallback = jsonDecode,
    this.jsonEncodeCallback = jsonEncode,
  });

  JsonDecodeCallback jsonDecodeCallback;
  JsonEncodeCallback jsonEncodeCallback;

  @override
  Future<String> transformRequest(RequestOptions options) async {
    return Transformer.defaultTransformRequest(options, jsonEncodeCallback);
  }

  @override
  Future<dynamic> transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    final responseType = options.responseType;
    // Do not handled the body for streams.
    if (responseType == ResponseType.stream) {
      return responseBody;
    }

    final chunks = await responseBody.stream.toList();
    final responseBytes = Uint8List.fromList(chunks.expand((c) => c).toList());

    // Return the finalized bytes if the response type is bytes.
    if (responseType == ResponseType.bytes) {
      return responseBytes;
    }

    final isJsonContent = Transformer.isJsonMimeType(
      responseBody.headers[Headers.contentTypeHeader]?.first,
    );
    final String? response;
    if (options.responseDecoder != null) {
      final decodeResponse = options.responseDecoder!(
        responseBytes,
        options,
        responseBody..stream = const Stream.empty(),
      );

      if (decodeResponse is Future) {
        response = await decodeResponse;
      } else {
        response = decodeResponse;
      }
    } else if (!isJsonContent || responseBytes.isNotEmpty) {
      response = utf8.decode(responseBytes, allowMalformed: true);
    } else {
      response = null;
    }

    if (response != null &&
        response.isNotEmpty &&
        responseType == ResponseType.json &&
        isJsonContent) {
      return jsonDecodeCallback(response);
    }
    return response;
  }
}
