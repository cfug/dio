# dio_compatibility_layer

[![pub package](https://img.shields.io/pub/v/dio_compatibility_layer.svg)](https://pub.dev/packages/dio_compatibility_layer)
[![likes](https://img.shields.io/pub/likes/dio_compatibility_layer)](https://pub.dev/packages/dio_compatibility_layer/score)
[![popularity](https://img.shields.io/pub/popularity/dio_compatibility_layer)](https://pub.dev/packages/dio_compatibility_layer/score)
[![pub points](https://img.shields.io/pub/points/dio_compatibility_layer)](https://pub.dev/packages/dio_compatibility_layer/score)

If you encounter bugs, consider fixing it by opening a PR or at least contribute a failing test case.

This package contains adapters for [Dio](https://pub.dev/packages/dio)
which enables you to make use of other HTTP clients as the underlying implementation.

Currently, it supports compatibility with
- [`http`](https://pub.dev/packages/http)

## Get started

### Install

Add the `dio_compatibility_layer` package to your
[pubspec dependencies](https://pub.dev/packages/dio_compatibility_layer/install).

### Example

To use the `http` compatibility:

```dart
import 'package:dio/dio.dart';
import 'package:dio_compatibility_layer/dio_compatibility_layer.dart';
import 'package:http/http.dart';

void main() async {
  // Start in the `http` world. You can use `http`, `cronet_http`,
  // `cupertino_http` and other `http` compatible packages.
  final httpClient = Client();

  // Make the `httpClient` compatible via the `ConversionLayerAdapter` class.
  final dioAdapter = ConversionLayerAdapter(httpClient);

  // Make dio use the `httpClient` via the conversion layer.
  final dio = Dio()..httpClientAdapter = dioAdapter;

  // Make a request
  final response = await dio.get('https://dart.dev');
  print(response);
}
```
