# dio_http_compatibility_layer

[![pub package](https://img.shields.io/pub/v/dio_http_compatibility_layer.svg)](https://pub.dev/packages/dio_http_compatibility_layer)
[![likes](https://img.shields.io/pub/likes/dio_http_compatibility_layer)](https://pub.dev/packages/dio_http_compatibility_layer/score)
[![popularity](https://img.shields.io/pub/popularity/dio_http_compatibility_layer)](https://pub.dev/packages/dio_http_compatibility_layer/score)
[![pub points](https://img.shields.io/pub/points/dio_http_compatibility_layer)](https://pub.dev/packages/dio_http_compatibility_layer/score)

If you encounter bugs, consider fixing it by opening a PR or at least contribute a failing test case.

This is adapters for [Dio](https://pub.dev/packages/dio)
which enables you to make use of a `http` client as underlying implementation.

## Get started

### Install

Add the `dio_http_compatibility_layer` package to your
[pubspec dependencies](https://pub.dev/packages/dio_http_compatibility_layer/install).

### Example

```dart
Dio().httpClientAdapter = ConversionLayerAdapter(Client());
```
