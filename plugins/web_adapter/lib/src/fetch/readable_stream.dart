import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'readable_stream_default_reader.dart';
import 'readable_stream_source.dart';

/// The [ReadableStream] interface of the Streams API represents a readable
/// stream of byte data. The Fetch API offers a concrete instance of
/// a [ReadableStream] through the body property of a [Response] object.
extension type ReadableStream<T extends JSAny, AbortType extends JSAny>._(
    JSObject _) implements JSObject {
  /// Creates and returns a readable stream object from the given handlers.
  factory ReadableStream([
    ReadableStreamSource<T, AbortType>? underlyingSource,
    JSObject? queuingStrategy,
  ]) {
    if (underlyingSource != null) {
      if (queuingStrategy != null) {
        return ReadableStream._new$2(underlyingSource, queuingStrategy);
      } else {
        return ReadableStream._new$1(underlyingSource);
      }
    } else {
      return ReadableStream._new$0();
    }
  }

  /// Creates and returns a readable stream object.
  @JS('ReadableStream')
  external factory ReadableStream._new$0();

  /// Creates and returns a readable stream object from given handlers.
  @JS('ReadableStream')
  external factory ReadableStream._new$1(
    ReadableStreamSource<T, AbortType>? underlyingSource,
  );

  /// Creates and returns a readable stream object from given handlers and
  /// queuing strategy.
  @JS('ReadableStream')
  external factory ReadableStream._new$2(
    ReadableStreamSource<T, AbortType>? underlyingSource,
    JSObject? queuingStrategy,
  );

  static ReadableStream<JSUint8Array, AbortType>
      fromTypedDataStream<T extends TypedData, AbortType extends JSAny>(
    Stream<T> stream, [
    JSObject? queuingStrategy,
  ]) =>
          ReadableStream(
            ReadableStreamSource.fromStream(
              stream.transform(
                StreamTransformer<T, JSUint8Array>.fromHandlers(
                  handleData: (data, sink) =>
                      sink.add(data.buffer.asUint8List().toJS),
                ),
              ),
            ),
            queuingStrategy,
          );

  /// Returns a [bool] indicating whether or not the readable stream
  /// is locked to a reader.
  external final bool locked;

  @JS('cancel')
  // ignore: prefer_void_to_null
  external JSPromise<Null> _cancel([
    AbortType? reason,
  ]);

  // pipeThrough()
  // pipeTo()

  /// Creates a reader and locks the stream to it.
  /// While the stream is locked, no other reader can be acquired until this one
  /// is released.
  ///
  /// Implementation note: BYOP reader is unsupported, and therefore
  /// no optional arguments provided.
  external ReadableStreamDefaultReader<T, AbortType> getReader();

  @JS('tee')
  external JSArray<ReadableStream<T, AbortType>> _tee();

  /// Returns a [Future] that resolves when the stream is canceled.
  /// Calling this method signals a loss of interest in the stream by a consumer.
  /// The supplied [reason] argument will be given to the underlying source,
  /// which may or may not use it.
  Future<void> cancel([
    AbortType? reason,
  ]) =>
      _cancel(reason).toDart;

  /// The [tee] method tees this readable stream, returning a two-element
  /// array containing the two resulting branches as new [ReadableStream]
  /// instances. Each of those streams receives the same incoming data.
  List<ReadableStream<T, AbortType>> tee() => _tee().toDart;
}
