import 'dart:async';
import 'dart:js_interop';


extension type JSPromiseOr<T extends JSAny?>._(JSAny _) implements JSAny {
  static JSPromiseOr<T>? fromDart<T extends JSAny?>(FutureOr<T> futureOr) =>
    switch (futureOr) {
      final Future<T> future => future.toJS,
      // Always succeeds, because of JS type erasure.
      final T value => value,
    } as JSPromiseOr<T>?;
  
  FutureOr<T> get toDart => switch (this) {
    final JSPromise<T> promise => promise.toDart as FutureOr<T>,
    // Always succeeds, because of JS type erasure.
    final T value => value,
    _ => throw StateError('Invalid state op JSPromiseOr: unexpected type: $runtimeType'),
  };
}

extension FutureOrToJSPromiseOr<T extends JSAny?> on FutureOr<T> {
  JSPromiseOr<T>? get toJSPromiseOr =>
    switch (this) {
      final Future<T> future => future.toJS as JSPromiseOr<T>,
      // Always succeeds, because of JS type erasure.
      final T value => value as JSPromiseOr<T>?,
    };
}
