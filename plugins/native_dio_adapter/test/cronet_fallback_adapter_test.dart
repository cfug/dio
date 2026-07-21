import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jni/jni.dart' show JniException;
import 'package:native_dio_adapter/src/cronet_fallback_adapter.dart';

/// A minimal recording [HttpClientAdapter] used to observe what the fallback
/// wrapper delegates to it.
class _RecordingAdapter implements HttpClientAdapter {
  int fetchCallCount = 0;
  int closeCallCount = 0;
  bool lastCloseForce = false;

  RequestOptions? lastOptions;
  Stream<Uint8List>? lastRequestStream;
  Future<dynamic>? lastCancelFuture;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    fetchCallCount += 1;
    lastOptions = options;
    lastRequestStream = requestStream;
    lastCancelFuture = cancelFuture;
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {
    closeCallCount += 1;
    lastCloseForce = force;
  }
}

class _ThrowOnFetchAdapter implements HttpClientAdapter {
  _ThrowOnFetchAdapter({required this.error});

  final Object error;
  int closeCallCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    throw error;
  }

  @override
  void close({bool force = false}) {
    closeCallCount += 1;
  }
}

JniException _providerDisabledException() => JniException(
      // Real JniException.message includes the throwable string followed by
      // the Java stack trace; the classifier relies on `contains`.
      '$cronetProvidersDisabledMessage\n'
          '\tat org.chromium.net.CronetEngine\$Builder.build(CronetEngine.java:123)\n'
          '\tat org.chromium.net.CronetProvider.createBuilder(CronetProvider.java:45)',
      'stack from java',
    );

void main() {
  group('isCronetProviderUnavailable', () {
    test('matches the provider-disabled message including trailing stack', () {
      expect(
        isCronetProviderUnavailable(_providerDisabledException()),
        isTrue,
      );
    });

    test('does not match a different JniException message', () {
      final other = JniException(
        'java.lang.RuntimeException: Unable to find any Cronet provider.\n'
            '\tat org.chromium.net.CronetEngine.build(CronetEngine.java:200)',
        'stack from java',
      );
      expect(isCronetProviderUnavailable(other), isFalse);
    });

    test('does not match a non-JniException carrying the same text', () {
      final wrong = StateError(cronetProvidersDisabledMessage);
      expect(isCronetProviderUnavailable(wrong), isFalse);
    });

    test('does not match a JniException with the wrong exception class', () {
      // Different Java throwable type with a similar-looking message must
      // NOT match; the classifier requires the full RuntimeException prefix.
      final wrong = JniException(
        'java.lang.IllegalStateException: All available Cronet providers are '
            'disabled. A provider should be enabled before it can be used.',
        'stack',
      );
      expect(isCronetProviderUnavailable(wrong), isFalse);
    });
  });

  group('CronetWithFallbackAdapter', () {
    test(
        'classified error triggers the fallback factory exactly once and '
        'forwards the unchanged request, body, and cancel future', () async {
      final fallback = _RecordingAdapter();
      var factoryCallCount = 0;
      Object? seenError;
      StackTrace? seenStack;

      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () => throw _providerDisabledException(),
        createFallbackAdapter: (error, stack) {
          factoryCallCount += 1;
          seenError = error;
          seenStack = stack;
          return fallback;
        },
      );

      final requestStream = Stream<Uint8List>.fromIterable(
        <Uint8List>[
          Uint8List.fromList(<int>[1, 2, 3]),
        ],
      );
      final cancelCompleter = Completer<void>();

      final options = RequestOptions(
        path: 'https://example.com/first',
        method: 'POST',
      );

      final response = await wrapper.fetch(
        options,
        requestStream,
        cancelCompleter.future,
      );
      // Drain the response so the returned Future/stream doesn't dangle.
      await response.stream.drain<void>();

      expect(factoryCallCount, 1);
      expect(seenError, isA<JniException>());
      expect(seenStack, isNotNull);
      expect(fallback.fetchCallCount, 1);
      expect(identical(fallback.lastOptions, options), isTrue);
      expect(identical(fallback.lastRequestStream, requestStream), isTrue);
      expect(
        identical(fallback.lastCancelFuture, cancelCompleter.future),
        isTrue,
      );
      expect(identical(wrapper.selectedAdapter, fallback), isTrue);
    });

    test('non-matching JniException is rethrown and no fallback is created',
        () async {
      var fallbackCreated = 0;
      final nonMatching = JniException(
        'java.lang.IllegalArgumentException: bad config',
        'stack',
      );
      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () => throw nonMatching,
        createFallbackAdapter: (_, __) {
          fallbackCreated += 1;
          return _RecordingAdapter();
        },
      );

      await expectLater(
        () => wrapper.fetch(
          RequestOptions(path: 'https://example.com'),
          null,
          null,
        ),
        throwsA(isA<JniException>()),
      );
      expect(fallbackCreated, 0);
      expect(wrapper.selectedAdapter, isNull);
    });

    test('ArgumentError during cronet build is rethrown, not fallen back',
        () async {
      var fallbackCreated = 0;
      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () => throw ArgumentError('bad'),
        createFallbackAdapter: (_, __) {
          fallbackCreated += 1;
          return _RecordingAdapter();
        },
      );

      await expectLater(
        () => wrapper.fetch(
          RequestOptions(path: 'https://example.com'),
          null,
          null,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(fallbackCreated, 0);
      expect(wrapper.selectedAdapter, isNull);
    });

    test(
        'errors thrown by the successfully-built Cronet adapter do NOT '
        'trigger a fallback (post-init connection/TLS/timeout errors '
        'remain Cronet errors)', () async {
      final cronet = _ThrowOnFetchAdapter(
        error: StateError('post-init connection reset'),
      );
      var fallbackCreated = 0;
      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () => cronet,
        createFallbackAdapter: (_, __) {
          fallbackCreated += 1;
          return _RecordingAdapter();
        },
      );

      await expectLater(
        () => wrapper.fetch(
          RequestOptions(path: 'https://example.com'),
          null,
          null,
        ),
        throwsA(isA<StateError>()),
      );
      expect(fallbackCreated, 0);
      expect(identical(wrapper.selectedAdapter, cronet), isTrue);
    });

    test('selected fallback is reused across subsequent requests', () async {
      final fallback = _RecordingAdapter();
      var factoryCallCount = 0;
      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () => throw _providerDisabledException(),
        createFallbackAdapter: (_, __) {
          factoryCallCount += 1;
          return fallback;
        },
      );

      await (await wrapper.fetch(
        RequestOptions(path: 'https://example.com/one'),
        null,
        null,
      ))
          .stream
          .drain<void>();
      await (await wrapper.fetch(
        RequestOptions(path: 'https://example.com/two'),
        null,
        null,
      ))
          .stream
          .drain<void>();
      await (await wrapper.fetch(
        RequestOptions(path: 'https://example.com/three'),
        null,
        null,
      ))
          .stream
          .drain<void>();

      expect(factoryCallCount, 1);
      expect(fallback.fetchCallCount, 3);
    });

    test('selected Cronet adapter is reused across subsequent requests',
        () async {
      final cronet = _RecordingAdapter();
      var buildCount = 0;
      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () {
          buildCount += 1;
          return cronet;
        },
        createFallbackAdapter: (_, __) => throw StateError(
          'fallback must not be created when Cronet initialization succeeded',
        ),
      );

      await (await wrapper.fetch(
        RequestOptions(path: 'https://example.com/one'),
        null,
        null,
      ))
          .stream
          .drain<void>();
      await (await wrapper.fetch(
        RequestOptions(path: 'https://example.com/two'),
        null,
        null,
      ))
          .stream
          .drain<void>();

      expect(buildCount, 1);
      expect(cronet.fetchCallCount, 2);
      expect(identical(wrapper.selectedAdapter, cronet), isTrue);
    });

    test('close after selection closes the selected adapter exactly once',
        () async {
      final fallback = _RecordingAdapter();
      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () => throw _providerDisabledException(),
        createFallbackAdapter: (_, __) => fallback,
      );

      await (await wrapper.fetch(
        RequestOptions(path: 'https://example.com/one'),
        null,
        null,
      ))
          .stream
          .drain<void>();

      wrapper.close(force: true);
      wrapper.close();

      expect(fallback.closeCallCount, 1);
      expect(fallback.lastCloseForce, isTrue);
    });

    test(
        'close before any request does NOT invoke the build seam or create '
        'a fallback', () async {
      var buildInvoked = false;
      var fallbackCreated = false;
      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () {
          buildInvoked = true;
          return _RecordingAdapter();
        },
        createFallbackAdapter: (_, __) {
          fallbackCreated = true;
          return _RecordingAdapter();
        },
      );

      wrapper.close();

      expect(buildInvoked, isFalse);
      expect(fallbackCreated, isFalse);
      expect(wrapper.selectedAdapter, isNull);
    });
  });
}
