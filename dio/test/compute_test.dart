import 'dart:async';

import 'package:dio/src/compute/compute.dart';
import 'package:test/test.dart';

Future<void> _neverCompletesInBrowser(Object? _) {
  return Completer<void>().future;
}

Future<void> _neverCompletesInVm(Object? _) {
  return Future<void>.delayed(const Duration(days: 1));
}

int _blocksFor(Duration duration) {
  final stopwatch = Stopwatch()..start();
  var value = 0;
  while (stopwatch.elapsed < duration) {
    value++;
  }
  return value;
}

int _twice(int value) {
  return value * 2;
}

void main() {
  group('compute', () {
    test('compute completes callback', () async {
      expect(await compute(_twice, 21), 42);
    });

    test('computeWithTimeout completes callback without timeout', () async {
      expect(await computeWithTimeout(_twice, 21), 42);
    });

    test(
      'computeWithTimeout times out in the browser',
      () async {
        final stopwatch = Stopwatch()..start();

        await expectLater(
          computeWithTimeout(
            _neverCompletesInBrowser,
            null,
            timeout: const Duration(milliseconds: 50),
          ),
          throwsA(isA<TimeoutException>()),
        );

        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      },
      testOn: 'browser',
    );

    test(
      'computeWithTimeout times out after a synchronous browser callback',
      () async {
        final stopwatch = Stopwatch()..start();

        await expectLater(
          computeWithTimeout(
            _blocksFor,
            const Duration(milliseconds: 50),
            timeout: const Duration(milliseconds: 1),
          ),
          throwsA(isA<TimeoutException>()),
        );

        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      },
      testOn: 'browser',
    );

    test(
      'computeWithTimeout times out in the VM',
      () async {
        final stopwatch = Stopwatch()..start();

        await expectLater(
          computeWithTimeout(
            _neverCompletesInVm,
            null,
            timeout: const Duration(milliseconds: 50),
          ),
          throwsA(isA<TimeoutException>()),
        );

        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      },
      testOn: 'vm',
    );
  });
}
