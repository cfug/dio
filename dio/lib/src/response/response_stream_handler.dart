import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// An internal helper function to handle things around
/// streamed responses.
Stream<Uint8List> handleResponseStream(
  RequestOptions options,
  ResponseBody response,
) {
  final source = response.stream;

  // Use a StreamController to explicitly handle receive timeouts.
  final responseSink = StreamController<Uint8List>();
  late StreamSubscription<List<int>> responseSubscription;

  late int totalLength;
  if (options.onReceiveProgress != null) {
    totalLength = response.contentLength;
  }

  int dataLength = 0;
  responseSubscription = source.listen(
    (data) {
      responseSink.add(data);
      options.onReceiveProgress?.call(
        dataLength += data.length,
        totalLength,
      );
    },
    onError: (error, stackTrace) {
      responseSink.addError(error, stackTrace);
      responseSink.close();
    },
    onDone: () {
      responseSubscription.cancel();
      responseSink.close();
    },
    cancelOnError: true,
  );

  options.cancelToken?.whenCancel.whenComplete(() {
    /// Close the response stream upon a cancellation.
    responseSubscription.cancel();
    if (!responseSink.isClosed) {
      responseSink.addError(options.cancelToken!.cancelError!);
      responseSink.close();
    }
  });
  return responseSink.stream;
}
