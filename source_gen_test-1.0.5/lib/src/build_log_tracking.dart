import 'dart:async';
import 'dart:collection';

import 'package:build/build.dart';
import 'package:test/test.dart';

List<String>? _buildLog;
UnmodifiableListView<String>? _buildLogView;

/// Initializes tracking of `build` events from [log] for every test in the
/// current context.
///
/// Once called, any test that causes build events to be logged _should_
/// validate the contents of [buildLogItems] and _MUST_ call [clearBuildLog]
/// before the test completes.
void initializeBuildLogTracking() {
  if (_buildLog == null) {
    _buildLog = <String>[];
    assert(_buildLogView == null);
    _buildLogView = UnmodifiableListView(_buildLog!);
  } else {
    throw StateError(
      '`initializeBuildLogTracking` should only be called once.',
    );
  }
  // ignore: cancel_subscriptions
  StreamSubscription<void>? logSubscription;

  setUp(() {
    assert(_buildLog!.isEmpty);
    assert(logSubscription == null);
    logSubscription = log.onRecord.listen((r) => _buildLog!.add(r.message));
  });

  tearDown(() async {
    if (logSubscription != null) {
      await logSubscription!.cancel();
      logSubscription = null;
    }

    final remainingItems = _buildLog!.toList();
    _buildLog!.clear();
    if (remainingItems.isNotEmpty) {
      fail(
        '`buildLogItems` is not empty. Tests should validate the contents of '
        '`buildLogItems` and call `clearBuildLog` before `tearDown`.',
      );
    }
  });

  tearDownAll(() {
    assert(_buildLog != null);
    assert(_buildLogView != null);
    _buildLog = _buildLogView = null;
  });
}

List<String> get buildLogItems {
  if (_buildLog == null) {
    throw StateError('`initializeBuildLogTracking` has not been called.');
  }
  return _buildLogView!;
}

void clearBuildLog() {
  if (_buildLog == null) {
    throw StateError('`initializeBuildLogTracking` has not been called.');
  }
  _buildLog!.clear();
}
