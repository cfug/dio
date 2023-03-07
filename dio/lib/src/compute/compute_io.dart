// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This file corresponds to Flutter's
/// [`foundation/_isolates_io.dart`](https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/foundation/_isolates_io.dart).
///
/// Changes are only synced with the `stable` branch.
///
/// Last synced commit:
/// [3420b9c](https://github.com/flutter/flutter/commit/3420b9c50ea19489dd74b024705bb010c5763d0a)
///
/// The changes are currently manually synced. If you noticed that the Flutter's
/// original `compute` function (and any of the related files) have changed
/// on the `stable` branch and you would like to see those changes in the `compute` package
/// please open an [issue](https://github.com/dartsidedev/compute/issues),
/// and I'll try my best to "merge".
///
/// The file is intentionally not refactored so that it is easier to keep the
/// compute package up to date with Flutter's implementation.
import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'compute.dart' as c;

const _kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// The dart:io implementation of [c.compute].
Future<R> compute<Q, R>(
  c.ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
}) async {
  debugLabel ??= _kReleaseMode ? 'compute' : callback.toString();

  final Flow flow = Flow.begin();
  Timeline.startSync('$debugLabel: start', flow: flow);
  final RawReceivePort port = RawReceivePort();
  Timeline.finishSync();

  void timeEndAndCleanup() {
    Timeline.startSync('$debugLabel: end', flow: Flow.end(flow.id));
    port.close();
    Timeline.finishSync();
  }

  final Completer<dynamic> completer = Completer<dynamic>();
  port.handler = (dynamic msg) {
    timeEndAndCleanup();
    completer.complete(msg);
  };

  try {
    await Isolate.spawn<_IsolateConfiguration<Q, R>>(
      _spawn,
      _IsolateConfiguration<Q, R>(
        callback,
        message,
        port.sendPort,
        debugLabel,
        flow.id,
      ),
      errorsAreFatal: true,
      onExit: port.sendPort,
      onError: port.sendPort,
      debugName: debugLabel,
    );
  } on Object {
    timeEndAndCleanup();
    rethrow;
  }

  final dynamic response = await completer.future;
  if (response == null) {
    throw RemoteError('Isolate exited without result or error.', '');
  }

  assert(response is List<dynamic>);
  response as List<dynamic>;

  final int type = response.length;
  assert(1 <= type && type <= 3);

  switch (type) {
    // success; see _buildSuccessResponse
    case 1:
      return response[0] as R;

    // native error; see Isolate.addErrorListener
    case 2:
      await Future<Never>.error(
        RemoteError(
          response[0] as String,
          response[1] as String,
        ),
      );

    // caught error; see _buildErrorResponse
    case 3:
    default:
      assert(type == 3 && response[2] == null);

      await Future<Never>.error(
        response[0] as Object,
        response[1] as StackTrace,
      );
  }
}

class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
    this.callback,
    this.message,
    this.resultPort,
    this.debugLabel,
    this.flowId,
  );

  final c.ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;
  final int flowId;

  FutureOr<R> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => callback(message),
      flow: Flow.step(flowId),
    );
  }
}

/// The spawn point MUST guarantee only one result event is sent through the
/// [SendPort.send] be it directly or indirectly i.e. [Isolate.exit].
///
/// In case an [Error] or [Exception] are thrown AFTER the data
/// is sent, they will NOT be handled or reported by the main [Isolate] because
/// it stops listening after the first event is received.
///
/// Also use the helpers [_buildSuccessResponse] and [_buildErrorResponse] to
/// build the response
Future<void> _spawn<Q, R>(_IsolateConfiguration<Q, R> configuration) async {
  late final List<dynamic> computationResult;

  try {
    computationResult =
        _buildSuccessResponse(await configuration.applyAndTime());
  } catch (e, s) {
    computationResult = _buildErrorResponse(e, s);
  }

  Isolate.exit(configuration.resultPort, computationResult);
}

/// Wrap in [List] to ensure our expectations in the main [Isolate] are met.
///
/// We need to wrap a success result in a [List] because the user provided type
/// [R] could also be a [List]. Meaning, a check `result is R` could return true
/// for what was an error event.
List<R> _buildSuccessResponse<R>(R result) {
  return List<R>.filled(1, result);
}

/// Wrap in [List] to ensure our expectations in the main isolate are met.
///
/// We wrap a caught error in a 3 element [List]. Where the last element is
/// always null. We do this so we have a way to know if an error was one we
/// caught or one thrown by the library code.
List<dynamic> _buildErrorResponse(Object error, StackTrace stack) {
  return List<dynamic>.filled(3, null)
    ..[0] = error
    ..[1] = stack;
}
