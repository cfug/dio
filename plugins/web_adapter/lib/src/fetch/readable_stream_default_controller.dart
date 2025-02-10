import 'dart:js_interop';
import 'readable_stream.dart';
import 'readable_stream_controller.dart';

/// The [ReadableStreamDefaultController] interface of the Streams API
/// represents a controller allowing control of a [ReadableStream]'s state
/// and internal queue.
///
/// Default controllers are for streams that are not byte streams.
extension type ReadableStreamDefaultController<T extends JSAny>._(JSObject _)
    implements JSObject, ReadableStreamController {}
