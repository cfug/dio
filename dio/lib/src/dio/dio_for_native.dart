import 'dart:async';
import 'dart:io';

import '../adapter.dart';
import '../adapters/io_adapter.dart';
import '../cancel_token.dart';
import '../dio.dart';
import '../dio_exception.dart';
import '../dio_mixin.dart';
import '../headers.dart';
import '../options.dart';
import '../response.dart';

/// Create the [Dio] instance for native platforms.
Dio createDio([BaseOptions? baseOptions]) => DioForNative(baseOptions);

/// Implements features for [Dio] on native platforms.
class DioForNative with DioMixin implements Dio {
  /// Create Dio instance with default [BaseOptions].
  /// It is recommended that an application use only the same DIO singleton.
  DioForNative([BaseOptions? baseOptions]) {
    options = baseOptions ?? BaseOptions();
    httpClientAdapter = IOHttpClientAdapter();
  }

  /// {@macro dio.Dio.download}
  @override
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    options ??= DioMixin.checkOptions('GET', options);
    // Manually set the `responseType` to [ResponseType.stream]
    // to retrieve the response stream.
    // Do not modify previous options.
    options = options.copyWith(responseType: ResponseType.stream);
    final Response<ResponseBody> response;
    try {
      response = await request<ResponseBody>(
        urlPath,
        data: data,
        options: options,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        final response = e.response!;
        if (response.requestOptions.receiveDataWhenStatusError == true) {
          final ResponseType implyResponseType;
          final contentType = response.headers.value(Headers.contentTypeHeader);
          if (contentType != null && contentType.startsWith('text/')) {
            implyResponseType = ResponseType.plain;
          } else {
            implyResponseType = ResponseType.json;
          }
          final res = await transformer.transformResponse(
            response.requestOptions.copyWith(responseType: implyResponseType),
            response.data as ResponseBody,
          );
          response.data = res;
        } else {
          response.data = null;
        }
      }
      rethrow;
    }
    final File file;
    if (savePath is FutureOr<String> Function(Headers)) {
      // Add real Uri and redirect information to headers.
      response.headers
        ..add('redirects', response.redirects.length.toString())
        ..add('uri', response.realUri.toString());
      file = File(await savePath(response.headers));
    } else if (savePath is String) {
      file = File(savePath);
    } else {
      throw ArgumentError.value(
        savePath.runtimeType,
        'savePath',
        'The type must be `String` or `FutureOr<String> Function(Headers)`.',
      );
    }

    // If the file already exists, the method fails.
    file.createSync(recursive: true);

    // Shouldn't call file.writeAsBytesSync(list, flush: flush),
    // because it can write all bytes by once. Consider that the file is
    // a very big size (up to 1 Gigabytes), it will be expensive in memory.
    RandomAccessFile raf = file.openSync(
      mode: fileAccessMode == FileAccessMode.write
          ? FileMode.write
          : FileMode.append,
    );

    // Create a Completer to notify the success/error state.
    final completer = Completer<Response>();
    int received = 0;

    // Stream<Uint8List>
    final stream = response.data!.stream;
    bool compressed = false;
    int total = 0;
    final contentEncoding = response.headers.value(
      Headers.contentEncodingHeader,
    );
    if (contentEncoding != null) {
      compressed = ['gzip', 'deflate', 'compress'].contains(contentEncoding);
    }
    if (lengthHeader == Headers.contentLengthHeader && compressed) {
      total = -1;
    } else {
      total = int.parse(response.headers.value(lengthHeader) ?? '-1');
    }

    Future<void>? asyncWrite;
    bool closed = false;
    Future<void> closeAndDelete() async {
      if (!closed) {
        closed = true;
        await asyncWrite;
        await raf.close().catchError((_) => raf);
        if (deleteOnError && file.existsSync()) {
          await file.delete().catchError((_) => file);
        }
      }
    }

    late StreamSubscription subscription;
    subscription = stream.listen(
      (data) {
        subscription.pause();
        // Write file asynchronously
        asyncWrite = raf.writeFrom(data).then((result) {
          // Notify progress
          received += data.length;
          onReceiveProgress?.call(received, total);
          raf = result;
          if (cancelToken == null || !cancelToken.isCancelled) {
            subscription.resume();
          }
        }).catchError((Object e) async {
          try {
            await subscription.cancel().catchError((_) {});
            closed = true;
            await raf.close().catchError((_) => raf);
            if (deleteOnError && file.existsSync()) {
              await file.delete().catchError((_) => file);
            }
          } finally {
            completer.completeError(
              DioMixin.assureDioException(e, response.requestOptions),
            );
          }
        });
      },
      onDone: () async {
        try {
          await asyncWrite;
          closed = true;
          await raf.close().catchError((_) => raf);
          completer.complete(response);
        } catch (e) {
          completer.completeError(
            DioMixin.assureDioException(e, response.requestOptions),
          );
        }
      },
      onError: (e) async {
        try {
          await closeAndDelete();
        } finally {
          completer.completeError(
            DioMixin.assureDioException(e, response.requestOptions),
          );
        }
      },
      cancelOnError: true,
    );
    cancelToken?.whenCancel.then((_) async {
      await subscription.cancel();
      await closeAndDelete();
    });
    return DioMixin.listenCancelForAsyncTask(cancelToken, completer.future);
  }
}
