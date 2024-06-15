# dio_web_adapter

[![pub package](https://img.shields.io/pub/v/dio_web_adapter.svg)](https://pub.dev/packages/dio_web_adapter)
[![likes](https://img.shields.io/pub/likes/dio_web_adapter)](https://pub.dev/packages/dio_web_adapter/score)
[![popularity](https://img.shields.io/pub/popularity/dio_web_adapter)](https://pub.dev/packages/dio_web_adapter/score)
[![pub points](https://img.shields.io/pub/points/dio_web_adapter)](https://pub.dev/packages/dio_web_adapter/score)

If you encounter bugs, consider fixing it by opening a PR or at least contribute a failing test case.

This package contains adapters for [Dio](https://pub.dev/packages/dio)
which enables you to use the library on the Web platform.

## Versions compatibility

| Version | Dart (min) | Flutter (min) |
|---------|------------|---------------|
| 1.x     | 2.18.0     | 3.3.0         |
| 2.x     | 3.3.0      | 3.19.0        |

> Note: the resolvable version will be determined by the SDK you are using.
> Run `dart pub upgrade` or `flutter pub upgrade` to get the latest resolvable version.

## Get started

The package is embedded into the `package:dio`.
You don't need to explicitly install the package unless you have other concerns.

### Install

Add the `dio_web_adapter` package to your
[pubspec dependencies](https://pub.dev/packages/dio_web_adapter/install).

### Example


```dart
import 'package:dio/dio.dart';
// The import is not required and could produce lints.
// import 'package:dio_web_adapter/dio_web_adapter.dart';

void main() async {
  final dio = Dio();
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);

  // Make a request.
  final response = await dio.get('https://dart.dev');
  print(response);
}
```
