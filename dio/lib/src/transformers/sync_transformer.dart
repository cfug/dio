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

/// The default [Transformer] for [Dio].
///
/// If you want to custom the transformation of request/response data,
/// you can provide a [Transformer] by your self, and replace
/// the [DefaultTransformer] by setting the [dio.transformer].
class SyncTransformer extends Transformer {
  SyncTransformer({
    this.jsonDecodeCallback = jsonDecode,
    this.jsonEncodeCallback = jsonEncode,
  });

  JsonDecodeCallback jsonDecodeCallback;
  JsonEncodeCallback jsonEncodeCallback;

  @override
  Future<String> transformRequest(RequestOptions options) async {
    final dynamic data = options.data ?? '';
    if (data is! String && Transformer.isJsonMimeType(options.contentType)) {
      return jsonEncodeCallback(data);
    } else if (data is Map<String, dynamic>) {
      return Transformer.urlEncodeMap(data, options.listFormat);
    } else {
      return data.toString();
    }
  }

  /// As an agreement, we return the [response] when the
  /// Options.responseType is [ResponseType.stream].
  @override
  Future<dynamic> transformResponse(
    RequestOptions options,
    ResponseBody response,
  ) async {
    if (options.responseType == ResponseType.stream) {
      return response;
    }
    int length = 0;
    int received = 0;
    final showDownloadProgress = options.onReceiveProgress != null;
    if (showDownloadProgress) {
      length = int.parse(
        response.headers[Headers.contentLengthHeader]?.first ?? '-1',
      );
    }
    final completer = Completer();
    final stream = response.stream.transform<Uint8List>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(data);
          if (showDownloadProgress) {
            received += data.length;
            options.onReceiveProgress?.call(received, length);
          }
        },
      ),
    );
    // Keep references to the data chunks and concatenate them later.
    final chunks = <Uint8List>[];
    int finalSize = 0;
    final StreamSubscription subscription = stream.listen(
      (chunk) {
        finalSize += chunk.length;
        chunks.add(chunk);
      },
      onError: (Object error, StackTrace stackTrace) {
        completer.completeError(error, stackTrace);
      },
      onDone: () => completer.complete(),
      cancelOnError: true,
    );
    options.cancelToken?.whenCancel.then((_) {
      return subscription.cancel();
    });
    await completer.future;
    // Copy all chunks into a final Uint8List.
    final responseBytes = Uint8List(finalSize);
    int chunkOffset = 0;
    for (final chunk in chunks) {
      responseBytes.setAll(chunkOffset, chunk);
      chunkOffset += chunk.length;
    }

    if (options.responseType == ResponseType.bytes) {
      return responseBytes;
    }

    final String? responseBody;
    if (options.responseDecoder != null) {
      responseBody = options.responseDecoder!(
        responseBytes,
        options,
        response..stream = Stream.empty(),
      );
    } else if (responseBytes.isNotEmpty) {
      responseBody = utf8.decode(responseBytes, allowMalformed: true);
    } else {
      responseBody = null;
    }
    if (responseBody != null &&
        responseBody.isNotEmpty &&
        options.responseType == ResponseType.json &&
        Transformer.isJsonMimeType(
          response.headers[Headers.contentTypeHeader]?.first,
        )) {
      return jsonDecodeCallback(responseBody);
    }
    return responseBody;
  }
}
