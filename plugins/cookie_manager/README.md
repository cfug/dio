# dio_cookie_manager

[![Pub](https://img.shields.io/pub/v/dio_cookie_manager.svg)](https://pub.dev/packages/dio_cookie_manager)

A cookie manager combines `cookie_jar` and `dio`, based on the interceptor algorithm.

## Getting Started

### Install

Add the `dio_cookie_manager` package to your
[pubspec dependencies](https://pub.dev/packages/dio_cookie_manager/install).

## Usage

```dart
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

void main() async {
  final dio = Dio();
  final cookieJar = CookieJar();
  dio.interceptors.add(CookieManager(cookieJar));
  // First request, and save cookies (CookieManager do it).
  await dio.get("https://dart.dev");
  // Print cookies
  print(await cookieJar.loadForRequest(Uri.parse("https://dart.dev")));
  // Second request with the cookies
  await dio.get('https://dart.dev');
}
```

### Creates a `CookieManager`

`CookieManager` is an interceptor that can help you to manage cookies automatically.
`CookieManager` depends on the `cookie_jar` package:

> The dio_cookie_manager manage API is based on the
> [cookie_jar](https://github.com/flutterchina/cookie_jar).

`CookieJar` manages cookies automatically, and it's memory-based.
If you want to persist cookies, you can use the `PersistCookieJar` class,
`PersistCookieJar` persists the cookies in local files,
the cookies always exist unless `delete` is called explicitly.

> [!NOTE]
> The path for `PersistCookieJar` must be existed on devices and with write access when running in Flutter.
> Use [path_provider](https://pub.dev/packages/path_provider) package to get a valid path.

In Flutter:
```dart
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path/path' as path;

Future<void> prepareCookieManager() async {
  final directory = await getApplicationDocumentsDirectory();
  final cookieJar = PersistCookieJar(
    ignoreExpires: true,
    storage: FileStorage(path.join(directory.path, "/.cookies/")),
  );
  dio.interceptors.add(CookieManager(cookieJar));
}
```

### Handling Cookies with redirect requests

Redirect requests require extra configuration to parse cookies correctly.
In shortly:
- Set `followRedirects` to `false`.
- Allow `statusCode` from `300` to `399` responses predicated as succeed.
- Make further requests using the `HttpHeaders.locationHeader`.

For example:
```dart
void main() async {
  final cookieJar = CookieJar();
  final dio = Dio()
    ..interceptors.add(CookieManager(cookieJar))
    ..options.followRedirects = false
    ..options.validateStatus =
        (status) => status != null && status >= 200 && status < 400;
  final redirected = await dio.get('/redirection');
  final response = await dio.get(
    redirected.headers.value(HttpHeaders.locationHeader)!,
  );
}
```
