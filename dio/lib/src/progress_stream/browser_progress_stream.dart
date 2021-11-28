import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';

Stream<Uint8List> addProgress(
    Stream<List<int>> stream, int? length, RequestOptions options) {
  if (stream is Stream<Uint8List>) return stream;
  var streamTransformer = _transform<List<int>>(stream, length, options);
  return stream.transform<Uint8List>(streamTransformer);
}

StreamTransformer<S, Uint8List> _transform<S extends List<int>>(
    Stream<S> stream, int? length, RequestOptions options) {
  return StreamTransformer<S, Uint8List>.fromHandlers(
    handleData: (S data, sink) {
      final cancelToken = options.cancelToken;
      if (cancelToken != null && cancelToken.isCancelled) {
        cancelToken.requestOptions = options;
        sink
          ..addError(cancelToken.cancelError!)
          ..close();
      } else {
        if (data is Uint8List) {
          sink.add(data);
        } else {
          sink.add(Uint8List.fromList(data));
        }
      }
    },
  );
}
