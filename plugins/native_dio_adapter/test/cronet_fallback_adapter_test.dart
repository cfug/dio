import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// Test stand-in for the JNI-thrown `JThrowable` that Cronet surfaces when
/// all providers are disabled.
///
/// `JThrowable` cannot be constructed in pure Dart — it wraps a real JNI
/// reference and its constructor is internal. The adapter tests therefore
/// inject [testIsProviderUnavailable], which recognises this type and
/// delegates message matching to [isCronetProviderUnavailableMessage] (the
/// same pure function the production classifier uses).
class _ProviderUnavailableException implements Exception {
  _ProviderUnavailableException(this.message);

  final String message;
}

/// Classifier injected into [CronetWithFallbackAdapter.forTesting] so tests
/// can simulate the provider-disabled failure without a live JNI environment.
bool testIsProviderUnavailable(Object error) =>
    error is _ProviderUnavailableException &&
    isCronetProviderUnavailableMessage(error.message);

_ProviderUnavailableException _providerDisabledException() =>
    _ProviderUnavailableException(
      // Real JThrowable.message includes the throwable string followed by
      // the Java stack trace; the classifier relies on `contains`.
      '$cronetProvidersDisabledMessage\n'
      '\tat org.chromium.net.CronetEngine\$Builder.build(CronetEngine.java:123)\n'
      '\tat org.chromium.net.CronetProvider.createBuilder(CronetProvider.java:45)',
    );

void main() {
  group('isCronetProviderUnavailableMessage', () {
    test('matches the provider-disabled message including trailing stack', () {
      expect(
        isCronetProviderUnavailableMessage(
          '$cronetProvidersDisabledMessage\n'
          '\tat org.chromium.net.CronetEngine\$Builder.build(CronetEngine.java:123)\n'
          '\tat org.chromium.net.CronetProvider.createBuilder(CronetProvider.java:45)',
        ),
        isTrue,
      );
    });

    test('does not match a different exception message', () {
      expect(
        isCronetProviderUnavailableMessage(
          'java.lang.RuntimeException: Unable to find any Cronet provider.\n'
          '\tat org.chromium.net.CronetEngine.build(CronetEngine.java:200)',
        ),
        isFalse,
      );
    });

    test('does not match a similar message with the wrong exception class', () {
      // Different Java throwable type with a similar-looking message must
      // NOT match; the classifier requires the full RuntimeException prefix.
      expect(
        isCronetProviderUnavailableMessage(
          'java.lang.IllegalStateException: All available Cronet providers are '
          'disabled. A provider should be enabled before it can be used.',
        ),
        isFalse,
      );
    });

    test('does not match an empty message', () {
      expect(isCronetProviderUnavailableMessage(''), isFalse);
    });
  });

  group('isCronetProviderUnavailable', () {
    test('returns false for a non-JThrowable carrying the same text', () {
      // A plain Dart error with the exact message must not be classified as
      // a Cronet-provider-disabled failure — the production classifier
      // requires a JThrowable, not just the message text.
      final wrong = StateError(cronetProvidersDisabledMessage);
      expect(isCronetProviderUnavailable(wrong), isFalse);
    });

    test('returns false for an ArgumentError', () {
      expect(isCronetProviderUnavailable(ArgumentError('bad')), isFalse);
    });

    test('returns false for a plain String', () {
      expect(
        isCronetProviderUnavailable(cronetProvidersDisabledMessage),
        isFalse,
      );
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
        isProviderUnavailable: testIsProviderUnavailable,
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
      expect(seenError, isA<_ProviderUnavailableException>());
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

    test(
        'non-matching provider exception is rethrown and no fallback is '
        'created', () async {
      var fallbackCreated = 0;
      final nonMatching = _ProviderUnavailableException(
        'java.lang.IllegalArgumentException: bad config',
      );
      final wrapper = CronetWithFallbackAdapter.forTesting(
        buildCronetAdapter: () => throw nonMatching,
        createFallbackAdapter: (_, __) {
          fallbackCreated += 1;
          return _RecordingAdapter();
        },
        isProviderUnavailable: testIsProviderUnavailable,
      );

      await expectLater(
        () => wrapper.fetch(
          RequestOptions(path: 'https://example.com'),
          null,
          null,
        ),
        throwsA(isA<_ProviderUnavailableException>()),
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
        isProviderUnavailable: testIsProviderUnavailable,
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
        isProviderUnavailable: testIsProviderUnavailable,
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
        isProviderUnavailable: testIsProviderUnavailable,
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
        isProviderUnavailable: testIsProviderUnavailable,
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
        isProviderUnavailable: testIsProviderUnavailable,
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
        isProviderUnavailable: testIsProviderUnavailable,
      );

      wrapper.close();

      expect(buildInvoked, isFalse);
      expect(fallbackCreated, isFalse);
      expect(wrapper.selectedAdapter, isNull);
    });
  });
}
