import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../adapter.dart';
import '../headers.dart';
import '../options.dart';
import '../transformer.dart';
import '../utils.dart';

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
    final Object data = options.data ?? '';
    if (data is! String && Transformer.isJsonMimeType(options.contentType)) {
      return jsonEncodeCallback(data);
    } else if (data is Map) {
      if (data is Map<String, dynamic>) {
        return Transformer.urlEncodeMap(data, options.listFormat);
      }
      debugLog(
        'The data is a type of `Map` (${data.runtimeType}), '
        'but the transformer can only encode `Map<String, dynamic>`.\n'
        'If you are writing maps using `{}`, '
        'consider writing `<String, dynamic>{}`.',
        StackTrace.current,
      );
      return data.toString();
    } else {
      return data.toString();
    }
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

    final showDownloadProgress = options.onReceiveProgress != null;
    final int totalLength;
    if (showDownloadProgress) {
      totalLength = int.parse(
        responseBody.headers[Headers.contentLengthHeader]?.first ?? '-1',
      );
    } else {
      totalLength = 0;
    }

    int received = 0;
    final stream = responseBody.stream.transform<Uint8List>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(data);
          if (showDownloadProgress) {
            received += data.length;
            options.onReceiveProgress?.call(received, totalLength);
          }
        },
      ),
    );

    final streamCompleter = Completer<void>();
    int finalLength = 0;
    // Keep references to the data chunks and concatenate them later.
    final chunks = <Uint8List>[];
    final subscription = stream.listen(
      (chunk) {
        finalLength += chunk.length;
        chunks.add(chunk);
      },
      onError: (Object error, StackTrace stackTrace) {
        streamCompleter.completeError(error, stackTrace);
      },
      onDone: () {
        streamCompleter.complete();
      },
      cancelOnError: true,
    );
    options.cancelToken?.whenCancel.then((_) {
      return subscription.cancel();
    });
    await streamCompleter.future;

    // Copy all chunks into the final bytes.
    final responseBytes = Uint8List(finalLength);
    int chunkOffset = 0;
    for (final chunk in chunks) {
      responseBytes.setAll(chunkOffset, chunk);
      chunkOffset += chunk.length;
    }

    // Return the finalized bytes if the response type is bytes.
    if (responseType == ResponseType.bytes) {
      return responseBytes;
    }

    final isJsonContent = Transformer.isJsonMimeType(
      responseBody.headers[Headers.contentTypeHeader]?.first,
    );
    final String? response;
    if (options.responseDecoder != null) {
      response = options.responseDecoder!(
        responseBytes,
        options,
        responseBody..stream = Stream.empty(),
      );
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
