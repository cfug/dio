import 'dart:async';
import 'dart:js_interop';

import 'js_promise_or.dart';
import 'readable_stream_controller.dart';

/// Signature for `pull` or `start` method.
typedef ReadableStreamSourceControllerMethodFunction<T extends JSAny, R extends JSAny?> = FutureOr<R> Function(ReadableStreamController<T> controller);

/// General interface for controller based `pull` and `start` methods.
extension type ReadableStreamSourceControllerMethod<T extends JSAny, R extends JSAny?>._(JSFunction _) implements JSFunction {
  /// Wrap Dart function to [ReadableStreamSourceControllerMethod].
  factory ReadableStreamSourceControllerMethod(
    ReadableStreamSourceControllerMethodFunction<T, R> fn,
  ) =>
      (
          // ignore: avoid_types_on_closure_parameters, discarded_futures
          (ReadableStreamController<T> controller) => fn(controller).toJSPromiseOr).toJS as ReadableStreamSourceControllerMethod<T, R>;

  /// Execute this function.
  @JS('call')
  external JSPromise<R>? call(
    JSObject context,
    ReadableStreamController<T> controller,
  );

  /// Bind this function to given [context].
  @JS()
  external ReadableStreamSourceControllerMethod<T, R> bind(JSObject context);
}
