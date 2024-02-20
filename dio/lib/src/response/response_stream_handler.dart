import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// An internal helper which handles functionality
/// common to all adapters. This function ensures that
/// all resources are closed when the request is finished
/// or cancelled.
///
/// - [options.receiveTimeout] between received chunks
/// - [options.onReceiveProgress] progress for received chunks
/// - [options.cancelToken] for cancellation while receiving
Stream<Uint8List> handleResponseStream(
  RequestOptions options,
  ResponseBody response,
) {
  final source = response.stream;
  final responseSink = StreamController<Uint8List>();
  late StreamSubscription<List<int>> responseSubscription;

  late int totalLength;
  int receivedLength = 0;
  if (options.onReceiveProgress != null) {
    totalLength = response.contentLength;
  }

  final receiveTimeout = options.receiveTimeout ?? Duration.zero;
  final receiveStopwatch = Stopwatch();
  Timer? receiveTimer;

  void stopWatchReceiveTimeout() {
    receiveTimer?.cancel();
    receiveTimer = null;
    receiveStopwatch.stop();
  }

  void watchReceiveTimeout() {
    if (receiveTimeout <= Duration.zero) {
      return;
    }
    receiveStopwatch.reset();
    if (!receiveStopwatch.isRunning) {
      receiveStopwatch.start();
    }
    receiveTimer?.cancel();
    receiveTimer = Timer(receiveTimeout, () {
      responseSink.addError(
        DioException.receiveTimeout(
          timeout: receiveTimeout,
          requestOptions: options,
        ),
      );
      response.close();
      responseSink.close();
      responseSubscription.cancel();
      stopWatchReceiveTimeout();
    });
  }

  responseSubscription = source.listen(
    (data) {
      watchReceiveTimeout();
      // Always true if the receive timeout was not set.
      if (receiveStopwatch.elapsed <= receiveTimeout) {
        responseSink.add(data);
        options.onReceiveProgress?.call(
          receivedLength += data.length,
          totalLength,
        );
      }
    },
    onError: (error, stackTrace) {
      stopWatchReceiveTimeout();
      responseSink.addError(error, stackTrace);
      responseSink.close();
    },
    onDone: () {
      stopWatchReceiveTimeout();
      responseSubscription.cancel();
      responseSink.close();
    },
    cancelOnError: true,
  );

  options.cancelToken?.whenCancel.whenComplete(() {
    stopWatchReceiveTimeout();
    // Close the response stream upon a cancellation.
    response.close();
    responseSubscription.cancel();
    if (!responseSink.isClosed) {
      responseSink.addError(options.cancelToken!.cancelError!);
      responseSink.close();
    }
  });
  return responseSink.stream;
}
