import 'dart:async';
import 'dart:isolate';

import 'package:dio/src/compute/compute.dart';

const _kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// The dart:io implementation of [isolate.compute].
@pragma('vm:prefer-inline')
Future<R> compute<M, R>(ComputeCallback<M, R> callback, M message,
    {String? debugLabel}) async {
  debugLabel ??= _kReleaseMode ? 'compute' : callback.toString();

  return Isolate.run<R>(() {
    return callback(message);
  }, debugName: debugLabel);
}
