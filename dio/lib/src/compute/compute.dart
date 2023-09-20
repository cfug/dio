import 'dart:async';

import 'compute_io.dart' if (dart.library.html) 'compute_web.dart' as _c;

typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

typedef ComputeImpl = Future<R> Function<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
});

const ComputeImpl compute = _c.compute;
