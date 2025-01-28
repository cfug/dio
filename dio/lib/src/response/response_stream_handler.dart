import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../adapter.dart';
import '../dio_exception.dart';
import '../options.dart';

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
  ResponseBody response, {
  @visibleForTesting void Function()? onReceiveTimeoutWatchCancelled,
}) {
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
    onReceiveTimeoutWatchCancelled?.call();
    receiveTimer?.cancel();
    receiveTimer = null;
    receiveStopwatch
      ..stop()
      ..reset();
  }

  void watchReceiveTimeout() {
    if (receiveTimeout <= Duration.zero) {
      return;
    }
    // Not calling `stopWatchReceiveTimeout` to follow the semantic:
    // Watching the new receive timeout does not indicate the watch
    // has been cancelled.
    receiveTimer?.cancel();
    receiveStopwatch
      ..reset()
      ..start();
    receiveTimer = Timer(receiveTimeout, () {
      stopWatchReceiveTimeout();
      response.close();
      responseSubscription.cancel();
      responseSink.addErrorAndClose(
        DioException.receiveTimeout(
          timeout: receiveTimeout,
          requestOptions: options,
        ),
      );
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
      responseSink.addErrorAndClose(error, stackTrace);
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
    responseSink.addErrorAndClose(options.cancelToken!.cancelError!);
  });
  return responseSink.stream;
}

extension on StreamController<Uint8List> {
  void addErrorAndClose(Object error, [StackTrace? stackTrace]) {
    if (!isClosed) {
      addError(error, stackTrace);
      close();
    }
  }
}
