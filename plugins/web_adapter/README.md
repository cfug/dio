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

## Downloading files

`Dio.download` is supported on Web by fetching the response bytes and triggering
a browser download with a Blob URL. The `savePath` argument is treated as the
suggested filename, not as a local filesystem path. The browser decides the
actual save location.

The browser schedules the download from a `blob:` URL created in the current
page. A returned `Response` means Dio fetched the response and dispatched the
browser download click; it does not guarantee that the browser wrote the file to
disk, kept the suggested filename, or skipped a user prompt. Those decisions are
controlled by the browser, user settings, and page security policies.

Web downloads have platform limitations:

- The request is still subject to CORS because it is fetched through Dio.
- The network request is handled by the browser through XHR, so HTTP protocol
  details such as HTTP/1.1, HTTP/2, or HTTP/3 are browser-controlled.
- The whole response is loaded into memory before the browser download starts.
- The download trigger relies on standard browser support for `Blob`,
  `URL.createObjectURL`, and `HTMLAnchorElement.download`.
- `FileAccessMode.append` is not supported.
- `deleteOnError` has no local file to delete on Web.
- Custom `lengthHeader` values are not used; progress totals come from the
  browser response progress event.
