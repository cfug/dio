# Native Dio Adapter

[![pub package](https://img.shields.io/pub/v/native_dio_adapter.svg)](https://pub.dev/packages/native_dio_adapter)
[![likes](https://img.shields.io/pub/likes/native_dio_adapter)](https://pub.dev/packages/native_dio_adapter/score)
[![popularity](https://img.shields.io/pub/popularity/native_dio_adapter)](https://pub.dev/packages/native_dio_adapter/score)
[![pub points](https://img.shields.io/pub/points/native_dio_adapter)](https://pub.dev/packages/native_dio_adapter/score)

> Note: This uses the native http implementation on macOS, iOS and Android.
> Other platforms still use the Dart http stack.

If you encounter bugs, consider fixing it by opening a PR or at least contribute a failing test case.

A client for [Dio](https://pub.dev/packages/dio) which makes use of
[`cupertino_http`](https://pub.dev/packages/cupertino_http) and
[`cronet_http`](https://pub.dev/packages/cronet_http)
to delegate HTTP requests to the native platform instead of the `dart:io` platforms.

Inspired by the [Dart 2.18 release blog](https://medium.com/dartlang/dart-2-18-f4b3101f146c).

## Motivation

Using the native platform implementation, rather than the socket-based
[`dart:io` HttpClient](https://api.dart.dev/stable/dart-io/HttpClient-class.html) implementation,
has several advantages:

- It automatically supports platform features such VPNs and HTTP proxies.
- It supports many more configuration options such as only allowing access through WiFi and blocking cookies.
- It supports more HTTP features such as HTTP/3 and custom redirect handling.

## Get started

### Install

Add the `native_dio_adapter` package to your
[pubspec dependencies](https://pub.dev/packages/native_dio_adapter/install).

### Example

```dart
final dioClient = Dio();
dioClient.httpClientAdapter = NativeAdapter();
```

### Opt-in Cronet provider fallback (Android)

On Android, `NativeAdapter` uses Cronet. Some devices — for example, AOSP
emulators or devices without Google Play services — install Cronet providers
but leave every provider disabled. On those devices `CronetEngine.build()`
throws and every request fails
([issue #2444](https://github.com/cfug/dio/issues/2444)).

If your application needs to support that environment, pass an opt-in
`createFallbackAdapter`. The factory is invoked **only** when the provider is
known to be disabled and lets you choose any `HttpClientAdapter`:

```dart
import 'package:dio/io.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

dioClient.httpClientAdapter = NativeAdapter(
  createFallbackAdapter: (error, stackTrace) => IOHttpClientAdapter(),
);
```

Notes:

- Detection is limited to Cronet's provider-disabled `RuntimeException`.
  Connection, TLS, timeout, redirect, cancellation, and response-stream
  errors remain Cronet errors and are propagated unchanged.
- The selection is sticky for the lifetime of the `NativeAdapter`. Once
  Cronet is picked, later requests do not probe again; once the fallback is
  picked, later requests reuse it.
- Changing adapters can change observable networking behavior: TLS
  configuration, proxy handling, cookie storage, supported protocols
  (HTTP/2, HTTP/3), and connection pooling. Callers opting in own that
  tradeoff — pick the adapter that best matches your requirements.

### Use embedded Cronet

Starting from `cronet_http` v1.2.0,
you can to use the embedded Cronet implementation
using a simple configuration with `dart-define`.
See https://pub.dev/packages/cronet_http#use-embedded-cronet
for more details.

## 📣 About the author

- [![Twitter Follow](https://img.shields.io/twitter/follow/ue_man?style=social)](https://twitter.com/ue_man)
- [![GitHub followers](https://img.shields.io/github/followers/ueman?style=social)](https://github.com/ueman)
