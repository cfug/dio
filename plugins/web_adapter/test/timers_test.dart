@TestOn('browser')
import 'dart:async';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('no timeout timer stays active once the request has completed',
      () async {
    const connectTimeout = Duration(minutes: 3);
    const receiveTimeout = Duration(minutes: 5);
    final timers = <Timer>[];
    final dio = DioForBrowser(
      BaseOptions(
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );

    // Record the timers armed by the adapter for this request.
    final response = await runZoned(
      () => dio.get<String>('data:text/plain,${'x' * 200000}'),
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, callback) {
          final timer = parent.createTimer(zone, duration, callback);
          if (duration >= connectTimeout) {
            timers.add(timer);
          }
          return timer;
        },
      ),
    );
    // `loadend` is dispatched right after `load`.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(response.data, hasLength(200000));
    expect(timers, isNotEmpty, reason: 'the adapter armed its timeout timers');
    // An armed timer keeps the XHR and its response reachable until it fires.
    expect(timers.where((timer) => timer.isActive), isEmpty);
  });
}
