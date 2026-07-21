import 'dart:typed_data' show Uint8List;

import 'package:cronet_http/cronet_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:jni/jni.dart' show JniException;

import 'cronet_adapter.dart';

/// Signature for building the fallback [HttpClientAdapter] used when the
/// default Cronet provider is unavailable on the current device.
///
/// See [NativeAdapter.new] and the package README for the intended contract.
typedef CreateFallbackAdapter = HttpClientAdapter Function(
  Object error,
  StackTrace stackTrace,
);

/// Exact `RuntimeException` message thrown by Chromium's Cronet API when
/// every registered `CronetProvider` on the device is disabled.
///
/// Chromium's provider-selection branch throws this exact `RuntimeException`:
/// https://chromium.googlesource.com/chromium/src/+/lkgr/components/cronet/android/api/src/org/chromium/net/CronetEngine.java
///
/// The referenced `CronetEngine.Builder.getPreferredCronetProvider` branch
/// throws this message when providers exist but all are disabled. It is
/// distinct from the separate "Unable to find any Cronet provider" error,
/// which reports that no provider was discovered at all.
const cronetProvidersDisabledMessage =
    'java.lang.RuntimeException: All available Cronet providers are disabled. '
    'A provider should be enabled before it can be used.';

/// Classifies the failure that indicates all installed Cronet providers on
/// the device are disabled.
///
/// `contains` is intentional: [JniException.message] also includes the Java
/// stack trace appended to the message. Do not broaden the predicate to all
/// [JniException]s or all engine-initialization failures.
bool isCronetProviderUnavailable(Object error) =>
    error is JniException &&
    error.message.contains(cronetProvidersDisabledMessage);

/// Builds the Cronet-backed [HttpClientAdapter] to use when Cronet is
/// available. May throw when the underlying Cronet provider is disabled or
/// otherwise unavailable.
typedef BuildCronetAdapter = HttpClientAdapter Function();

/// Android-only lazy adapter selection that either uses a [CronetAdapter] or,
/// if the default Cronet provider is known to be unavailable on the device,
/// a caller-supplied fallback [HttpClientAdapter].
///
/// The choice is sticky for the lifetime of this instance: once made, later
/// requests do not probe Cronet again. This wrapper is created only when
/// [NativeAdapter] is opted-in via `createFallbackAdapter`.
class CronetWithFallbackAdapter implements HttpClientAdapter {
  /// Production constructor used by [NativeAdapter].
  ///
  /// The "build the Cronet path" step is invoked lazily on the first
  /// [fetch] call: it synchronously creates a [CronetEngine] so that the
  /// provider-disabled failure surfaces here, before the request is
  /// delegated to any adapter. When [createCronetEngine] or
  /// [androidCronetEngine] is supplied, the caller-provided engine is used;
  /// otherwise [CronetEngine.build] is invoked.
  CronetWithFallbackAdapter({
    required CronetEngine Function()? createCronetEngine,
    required CronetEngine? androidCronetEngine,
    required CreateFallbackAdapter createFallbackAdapter,
  })  : _buildCronetAdapter = (() {
          final engine = createCronetEngine?.call() ??
              androidCronetEngine ??
              CronetEngine.build();
          return CronetAdapter(engine);
        }),
        _createFallbackAdapter = createFallbackAdapter;

  /// Test-only constructor: lets a test inject a controllable "build cronet
  /// adapter" seam without linking real native Cronet code. Not part of the
  /// public API.
  @visibleForTesting
  CronetWithFallbackAdapter.forTesting({
    required BuildCronetAdapter buildCronetAdapter,
    required CreateFallbackAdapter createFallbackAdapter,
  })  : _buildCronetAdapter = buildCronetAdapter,
        _createFallbackAdapter = createFallbackAdapter;

  final BuildCronetAdapter _buildCronetAdapter;
  final CreateFallbackAdapter _createFallbackAdapter;

  HttpClientAdapter? _selected;
  bool _closed = false;

  /// The adapter chosen for this instance, or `null` if selection has not
  /// happened yet. Visible for tests.
  @visibleForTesting
  HttpClientAdapter? get selectedAdapter => _selected;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) {
    final adapter = _selectAdapter();
    return adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    if (_closed) {
      return;
    }
    _closed = true;
    // If no request was ever made, do NOT initialize Cronet just to close it.
    _selected?.close(force: force);
  }

  HttpClientAdapter _selectAdapter() {
    final existing = _selected;
    if (existing != null) {
      return existing;
    }
    try {
      return _selected = _buildCronetAdapter();
    } catch (error, stackTrace) {
      if (isCronetProviderUnavailable(error)) {
        return _selected = _createFallbackAdapter(error, stackTrace);
      }
      rethrow;
    }
  }
}
