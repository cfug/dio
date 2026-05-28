import 'dart:async';

import 'package:dio/src/compute/compute.dart';
import 'package:test/test.dart';

FutureOr<String> _echo(String message) => message;

Future<void> _neverCompletes(Object? _) {
  return Future<void>.delayed(const Duration(days: 1));
}

void main() {
  group(
    'compute',
    () {
      test('returns the callback result', () async {
        expect(await compute(_echo, 'ok'), 'ok');
      });

      test('times out when the callback never completes', () async {
        final stopwatch = Stopwatch()..start();

        await expectLater(
          compute(
            _neverCompletes,
            null,
            timeout: const Duration(milliseconds: 50),
          ),
          throwsA(isA<TimeoutException>()),
        );

        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      });
    },
    testOn: 'vm',
  );
}
