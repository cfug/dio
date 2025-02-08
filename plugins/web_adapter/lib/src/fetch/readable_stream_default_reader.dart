import 'dart:js_interop';

import 'readable_stream.dart';
import 'readable_stream_default_reader_chunk.dart';

/// The [ReadableStreamDefaultReader] interface of the Streams API represents
/// a default reader that can be used to read stream data supplied from
/// a network (such as a fetch request).
///
/// A [ReadableStreamDefaultReader] can be used to read from a [ReadableStream]
/// that has an underlying source of any type.
extension type ReadableStreamDefaultReader<T extends JSAny,
    AbortType extends JSAny>._(JSObject _) implements JSObject {
  /// Creates and returns a [ReadableStreamDefaultReader] object instance.
  @JS()
  external factory ReadableStreamDefaultReader(
    ReadableStream<T, AbortType> stream,
  );

  /// Returns a `Promise` that fulfills when the stream closes,
  /// or rejects if the stream throws an error or the reader's lock is released.
  /// This property enables you to write code that responds to an end to
  /// the streaming process.
  @JS('closed')
  external final JSPromise<JSAny> _closed;

  @JS('cancel')
  external JSPromise<JSAny?> _cancel([
    AbortType? reason,
  ]);

  @JS('read')
  external JSPromise<ReadableStreamDefaultReaderChunk<T>> _read();

  /// Releases the reader's lock on the stream.
  @JS()
  external void releaseLock();

  /// Returns a [Future] that resolves when the stream is canceled.
  /// Calling this method signals a loss of interest in the stream by a consumer.
  /// The supplied [reason] argument will be given to the underlying source,
  /// which may or may not use it.
  Future<void> cancel([
    AbortType? reason,
  ]) =>
      _cancel(reason).toDart;

  /// Returns a [Future] providing access to the next chunk in the stream's
  /// internal queue.
  Future<ReadableStreamDefaultReaderChunk<T>> read() => _read().toDart;

  /// Returns a [Future] that fulfills when the stream closes,
  /// or rejects if the stream throws an error or the reader's lock is released.
  /// This property enables you to write code that responds to an end to
  /// the streaming process.
  Future<void> get readerClosed => _closed.toDart;

  /// Reads stream via [read] and returns chunks as soon as they are available.
  Stream<T> readAsStream() async* {
    try {
      ReadableStreamDefaultReaderChunk<T> chunk;
      do {
        chunk = await read();
        if (chunk.value case final value?) {
          yield value;
        }
      } while (!chunk.done);
      return;
    } finally {
      // Cancel stream after full read or early break.
      // If used with fetch response, this will cancel further response body
      // download on subscription cancellation and save bandwidth.
      await cancel();
    }
  }
}
