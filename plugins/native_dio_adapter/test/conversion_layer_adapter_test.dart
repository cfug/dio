import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:native_dio_adapter/src/conversion_layer_adapter.dart';

import 'client_mock.dart';

void main() {
  test('close', () {
    final mock = CloseClientMock();
    final cla = ConversionLayerAdapter(mock);

    cla.close();

    expect(mock.closeWasCalled, true);
  });

  test('close with force', () {
    final mock = CloseClientMock();
    final cla = ConversionLayerAdapter(mock);

    cla.close(force: true);

    expect(mock.closeWasCalled, true);
  });

  test('headers', () async {
    final mock = ClientMock()
      ..response = StreamedResponse(const Stream.empty(), 200);
    final cla = ConversionLayerAdapter(mock);

    await cla.fetch(
      RequestOptions(path: '', headers: {'foo': 'bar'}),
      const Stream.empty(),
      null,
    );

    expect(mock.request?.headers, {'foo': 'bar'});
  });

  test('download stream', () async {
    final mock = ClientMock()
      ..response = StreamedResponse(
        Stream.fromIterable(<Uint8List>[
          Uint8List.fromList([10, 1]),
          Uint8List.fromList([1, 4]),
          Uint8List.fromList([5, 1]),
          Uint8List.fromList([1, 1]),
          Uint8List.fromList([2, 4]),
        ]),
        200,
      );
    final cla = ConversionLayerAdapter(mock);

    final resp = await cla.fetch(
      RequestOptions(path: ''),
      null,
      null,
    );

    expect(await resp.stream.length, 5);
  });

  test('request cancellation', () async {
    final mock = AbortClientMock();
    final cla = ConversionLayerAdapter(mock);
    final cancelToken = CancelToken();

    Future<void>.delayed(const Duration(seconds: 1)).then(
      (value) {
        cancelToken.cancel();
      },
    );

    await expectLater(
      () => cla.fetch(
        RequestOptions(path: ''),
        null,
        cancelToken.whenCancel,
      ),
      throwsA(isA<AbortedError>()),
    );
  });

  test('request cancellation with Dio', () async {
    final mock = AbortClientMock();
    final cla = ConversionLayerAdapter(mock);
    final dio = Dio();
    dio.httpClientAdapter = cla;

    final cancelToken = CancelToken();

    Future<void>.delayed(const Duration(seconds: 1)).then(
      (value) {
        cancelToken.cancel();
      },
    );

    await expectLater(
      () => dio.get<ResponseBody>('', cancelToken: cancelToken),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(mock.isRequestCanceled, true);
  });

  group('Resource release (memory leak prevention)', () {
    test('abortTrigger completes after response stream is consumed', () async {
      final mock = ClientMock()
        ..response = StreamedResponse(
          Stream.fromIterable(<Uint8List>[
            Uint8List.fromList([1, 2, 3]),
          ]),
          200,
        );
      final cla = ConversionLayerAdapter(mock);

      final resp = await cla.fetch(
        RequestOptions(path: ''),
        null,
        null,
      );

      // Track whether the abort trigger (used to release native resources)
      // fires after the response stream is consumed.
      var abortTriggerFired = false;
      final request = mock.request!;
      if (request is Abortable) {
        request.abortTrigger?.whenComplete(() => abortTriggerFired = true);
      }

      // The abort trigger should not fire before the stream is consumed.
      await Future<void>.delayed(Duration.zero);
      expect(abortTriggerFired, isFalse);

      // Consume the response stream.
      await resp.stream.toList();

      // Give the microtask queue a turn to propagate the future completion.
      await Future<void>.delayed(Duration.zero);

      // After stream consumption the abort trigger must have fired so that
      // native resources (e.g. CronetUrlRequest JNI object and upload body
      // bytes) can be garbage collected.
      expect(abortTriggerFired, isTrue);
    });

    test('abortTrigger completes after upload stream response is consumed',
        () async {
      final mock = ClientMock()
        ..response = StreamedResponse(const Stream.empty(), 200);
      final cla = ConversionLayerAdapter(mock);

      final uploadBody =
          Uint8List.fromList(List.generate(1024, (i) => i % 256));

      final resp = await cla.fetch(
        RequestOptions(path: '', method: 'PUT'),
        Stream.fromIterable([uploadBody]),
        null,
      );

      var abortTriggerFired = false;
      final request = mock.request!;
      if (request is Abortable) {
        request.abortTrigger?.whenComplete(() => abortTriggerFired = true);
      }

      // Consume the (empty) response stream.
      await resp.stream.toList();
      await Future<void>.delayed(Duration.zero);

      // Abort trigger must have fired so upload body bytes can be GC'd.
      expect(abortTriggerFired, isTrue);
    });

    test('abortTrigger completes when response stream has an error', () async {
      final mock = ClientMock()
        ..response = StreamedResponse(
          Stream.fromFuture(
            Future<Uint8List>.error(Exception('network error')),
          ).cast<Uint8List>(),
          200,
        );
      final cla = ConversionLayerAdapter(mock);

      final resp = await cla.fetch(
        RequestOptions(path: ''),
        null,
        null,
      );

      var abortTriggerFired = false;
      final request = mock.request!;
      if (request is Abortable) {
        request.abortTrigger?.whenComplete(() => abortTriggerFired = true);
      }

      // Consume the stream (which will error).
      await resp.stream.toList().onError((_, __) => []);
      await Future<void>.delayed(Duration.zero);

      // Abort trigger must fire even when the stream ends with an error.
      expect(abortTriggerFired, isTrue);
    });

    test('abortTrigger completes when client.send throws', () async {
      final mock = ErrorClientMock(exception: Exception('connection refused'));
      final cla = ConversionLayerAdapter(mock);

      var abortTriggerFired = false;

      try {
        await cla.fetch(
          RequestOptions(path: ''),
          null,
          null,
        );
        fail('Should have thrown');
      } catch (_) {
        // expected
      }

      final request = mock.lastRequest;
      if (request != null && request is Abortable) {
        request.abortTrigger?.whenComplete(() => abortTriggerFired = true);
      }

      await Future<void>.delayed(Duration.zero);

      expect(abortTriggerFired, isTrue);
    });
  });

  group('Timeout tests', () {
    test('sendTimeout throws DioException.sendTimeout', () async {
      final mock = ClientMock()
        ..response = StreamedResponse(const Stream.empty(), 200);
      final cla = ConversionLayerAdapter(mock);

      final delayedStream = Stream<Uint8List>.periodic(
        const Duration(milliseconds: 10),
        (count) => Uint8List.fromList([count]),
      );

      try {
        await cla.fetch(
          RequestOptions(
            path: '',
            sendTimeout: const Duration(milliseconds: 1),
          ),
          delayedStream,
          null,
        );
        fail('Should have thrown DioException');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.sendTimeout);
        expect(e.message, contains('1'));
      }
    });

    test('receiveTimeout throws DioException.receiveTimeout', () async {
      final mock = DelayedClientMock(
        duration: const Duration(milliseconds: 10),
      );
      final cla = ConversionLayerAdapter(mock);

      try {
        await cla.fetch(
          RequestOptions(
            path: '',
            receiveTimeout: const Duration(milliseconds: 1),
          ),
          null,
          null,
        );
        fail('Should have thrown DioException');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.receiveTimeout);
        expect(e.message, contains('1'));
      }
    });

    test('connectTimeout and receiveTimeout are combined', () async {
      final mock = DelayedClientMock(
        duration: const Duration(milliseconds: 10),
      );
      final cla = ConversionLayerAdapter(mock);

      try {
        await cla.fetch(
          RequestOptions(
            path: '',
            connectTimeout: const Duration(milliseconds: 1),
            receiveTimeout: const Duration(milliseconds: 1),
          ),
          null,
          null,
        );
        fail('Should have thrown DioException');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.receiveTimeout);
        expect(e.message, contains('2'));
      }
    });

    test('AbortableRequest is triggered on receiveTimeout', () async {
      final mock = AbortClientMock();
      final cla = ConversionLayerAdapter(mock);

      try {
        await cla.fetch(
          RequestOptions(
            path: '',
            receiveTimeout: const Duration(milliseconds: 1),
          ),
          null,
          null,
        );
        fail('Should have thrown DioException');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.receiveTimeout);
        // Give delay for the abortTrigger callback to execute
        await Future<void>.delayed(Duration.zero);
        expect(mock.isRequestCanceled, isTrue);
      }
    });
  });
}
