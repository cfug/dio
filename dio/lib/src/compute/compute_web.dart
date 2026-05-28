import 'dart:async';

import 'package:dio_web_adapter/dio_web_adapter.dart' as web_adapter;

import 'compute.dart' as c;

export 'package:dio_web_adapter/dio_web_adapter.dart' show compute;

Future<R> computeWithTimeout<Q, R>(
  c.ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
  Duration? timeout,
}) {
  final result = web_adapter.compute(
    callback,
    message,
    debugLabel: debugLabel,
  );
  if (timeout != null && timeout > Duration.zero) {
    return result.timeout(timeout);
  }
  return result;
}
