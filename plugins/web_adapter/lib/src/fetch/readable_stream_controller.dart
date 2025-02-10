import 'dart:js_interop';
import 'readable_stream.dart';

/// Common interface for [ReadableStream] controllers.
extension type ReadableStreamController<T extends JSAny>._(JSObject _)
    implements JSObject {
  /// Returns the desired size required to fill the stream's internal queue.
  @JS()
  external final int desiredSize;

  /// Closes the associated stream.
  @JS()
  external void close();

  /// Enqueues a given [chunk] in the associated stream.
  @JS()
  external void enqueue(T chunk);

  /// Causes any future interactions with the associated stream to error.
  @JS()
  external void error(JSAny error);
}
