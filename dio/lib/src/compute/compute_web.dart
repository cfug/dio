import 'dart:async';

import 'package:dio_web_adapter/dio_web_adapter.dart' as web_adapter;

import 'compute.dart' as c;

export 'package:dio_web_adapter/dio_web_adapter.dart' show compute;

Future<R> computeWithTimeout<Q, R>(
  c.ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
  Duration? timeout,
}) async {
  final result = web_adapter.compute(
    callback,
    message,
    debugLabel: debugLabel,
  );
  if (timeout == null || timeout <= Duration.zero) {
    return result;
  }

  final stopwatch = Stopwatch()..start();
  try {
    final value = await result.timeout(
      timeout,
      onTimeout: () => throw _timeoutException(timeout),
    );
    if (stopwatch.elapsed > timeout) {
      throw _timeoutException(timeout);
    }
    return value;
  } catch (error) {
    if (error is TimeoutException) {
      rethrow;
    }
    if (stopwatch.elapsed > timeout) {
      throw _timeoutException(timeout);
    }
    rethrow;
  }
}

TimeoutException _timeoutException(Duration timeout) {
  return TimeoutException('Computation timed out after $timeout.', timeout);
}
