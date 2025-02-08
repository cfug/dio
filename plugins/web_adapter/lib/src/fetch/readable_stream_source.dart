import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'readable_stream_default_controller.dart';
import 'readable_stream_default_reader.dart';
import 'readable_stream_source_cancel_method.dart';
import 'readable_stream_source_controller_method.dart';

/// An object containing methods and properties that define how the constructed
/// stream instance will behave.
///
/// Note: Use [Uint8List] if you want compatibility with [Response] or [Request].
extension type ReadableStreamSource<T extends JSAny, AbortType extends JSAny>._(
    JSObject _) implements JSObject {
  factory ReadableStreamSource({
    ReadableStreamSourceControllerMethodFunction<T, JSAny?>? start,
    ReadableStreamSourceControllerMethodFunction<T, JSAny?>? pull,
    ReadableStreamSourceCancelMethodFunction<T, JSAny?, AbortType>? cancel,
    String? type,
    int? autoAllocateChunkSize,
  }) {
    final object = JSObject() as ReadableStreamSource<T, AbortType>;
    if (start != null) {
      object.start = ReadableStreamSourceControllerMethod(start);
    }
    if (pull != null) {
      object.pull = ReadableStreamSourceControllerMethod(pull);
    }
    if (cancel != null) {
      object.cancel =
          ReadableStreamSourceCancelMethod<T, JSAny?, AbortType>(cancel);
    }
    if (type != null) {
      object.type = type;
    }
    if (autoAllocateChunkSize != null) {
      object.autoAllocateChunkSize = autoAllocateChunkSize;
    }
    return object;
  }

  /// Create [ReadableStreamSource] from Dart [Stream].
  factory ReadableStreamSource.fromStream(Stream<T> stream) {
    late final StreamSubscription<T> subscription;
    return ReadableStreamSource(
      start: (controller) {
        subscription = stream.listen(
          (event) {
            controller.enqueue(event);
            if (controller.desiredSize <= 0) {
              subscription.pause();
            }
          },
          // ignore: avoid_types_on_closure_parameters
          onError: (Object error) {
            final object = switch (error) {
              String() => error.toJS,
              Exception() || Error() => error.toString().toJS,
              // Always succeeds, because of JS type erasure.
              JSObject() => error,
              _ => error.toJSBox,
            };
            controller.error(object);
          },
          onDone: () {
            controller.close();
          },
        );

        return null;
      },
      pull: (controller) {
        subscription.resume();

        return null;
      },
      cancel: (reason, controller) async {
        await subscription.cancel();

        return null;
      },
    );
  }

  /// This is a method, called immediately when the object is constructed.
  /// The contents of this method are defined by the developer,
  /// and should aim to get access to the stream source, and do anything else
  /// required to set up the stream functionality.
  ///
  /// If this process is to be done asynchronously, it can return a promise
  /// to signal success or failure.
  ///
  /// The controller parameter passed to this method is a
  /// [ReadableStreamDefaultController] or a `ReadableByteStreamController`,
  /// depending on the value of the type property.
  ///
  /// This can be used by the developer to control the stream during set up.
  @JS('start')
  external ReadableStreamSourceControllerMethod<T, JSAny?>? start;

  /// This method, also defined by the developer, will be called repeatedly
  /// when the stream's internal queue of chunks is not full, up until
  /// it reaches its high water mark.
  ///
  /// If `pull()` returns a promise, then it won't be called again until that
  /// promise fulfills; if the promise rejects, the stream will become errored.
  ///
  /// The controller parameter passed to this method is a
  /// [ReadableStreamDefaultController] or a `ReadableByteStreamController`,
  /// depending on the value of the type property.
  ///
  /// This can be used by the developer to control the stream as more chunks
  /// are fetched.
  @JS('pull')
  external ReadableStreamSourceControllerMethod<T, JSAny?>? pull;

  /// This method, also defined by the developer, will be called if the app
  /// signals that the stream is to be cancelled (e.g. if [cancel] is called).
  ///
  /// The contents should do whatever is necessary to release access
  /// to the stream source. If this process is asynchronous, it can return
  /// a promise to signal success or failure.
  ///
  /// The reason parameter contains a string describing why the stream
  /// was cancelled.
  @JS('cancel')
  external ReadableStreamSourceCancelMethod<T, JSAny?, AbortType>? cancel;

  /// This property controls what type of readable stream is being dealt with.
  /// If it is included with a value set to "bytes", the passed controller
  /// object will be a `ReadableByteStreamController` capable of handling a BYOB
  /// (bring your own buffer)/byte stream. If it is not included,
  /// the passed controller will be a [ReadableStreamDefaultController].
  @JS()
  external String? type;

  /// For byte streams, the developer can set the [autoAllocateChunkSize] with
  /// a positive integer value to turn on the stream's auto-allocation feature.
  /// With this is set, the stream implementation will automatically allocate
  /// a view buffer of the specified size in
  /// `ReadableByteStreamController.byobRequest` when required.
  ///
  /// This must be set to enable zero-copy transfers to be used with
  /// a default [ReadableStreamDefaultReader]. If not set, a default reader
  /// will still stream data, but `ReadableByteStreamController.byobRequest`
  /// will always be `null` and transfers to the consumer must be via
  /// the stream's internal queues.
  @JS()
  external int? autoAllocateChunkSize;
}
