import 'dart:async';
import 'dart:js_interop';

import 'js_promise_or.dart';
import 'readable_stream_controller.dart';

/// Signature for `close` method.
typedef ReadableStreamSourceCancelMethodFunction<T extends JSAny, R extends JSAny?, AbortType extends JSAny> = FutureOr<R> Function(AbortType? reason, ReadableStreamController<T> controller);

/// Interface for controller `cancel` method.
extension type ReadableStreamSourceCancelMethod<T extends JSAny, R extends JSAny?, AbortType extends JSAny>._(JSFunction _) implements JSFunction {
  /// Wrap Dart function to [ReadableStreamSourceCancelMethod].
  factory ReadableStreamSourceCancelMethod(
    ReadableStreamSourceCancelMethodFunction<T, R, AbortType> fn,
  ) =>
      (
          // ignore: avoid_types_on_closure_parameters
          (AbortType? reason, ReadableStreamController<T> controller) =>
              // ignore: discarded_futures
              fn(reason, controller).toJSPromiseOr).toJS as ReadableStreamSourceCancelMethod<T, R, AbortType>;

  /// Execute this function.
  @JS('call')
  external JSPromise<R>? call(
    JSObject context,
    AbortType reason,
    ReadableStreamController<T> controller,
  );

  /// Bind this function to given [context].
  @JS()
  external ReadableStreamSourceCancelMethod<T, R, AbortType> bind(JSObject context);
}
