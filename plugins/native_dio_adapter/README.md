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

### Use embedded Cronet

Starting from `cronet_http` v1.2.0,
you can to use the embedded Cronet implementation
using a simple configuration with `dart-define.
See https://pub.dev/packages/cronet_http#use-embedded-cronet
for more details.

## 📣 About the author

- [![Twitter Follow](https://img.shields.io/twitter/follow/ue_man?style=social)](https://twitter.com/ue_man)
- [![GitHub followers](https://img.shields.io/github/followers/ueman?style=social)](https://github.com/ueman)
