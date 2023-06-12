# CHANGELOG

**Before you upgrade: Breaking changes might happen in major and minor versions of packages.<br/>
See the [Migration Guide][] for the complete breaking changes list.**

## Unreleased

*None.*

## 5.2.1+1

- Fix changelog on pub.dev.

## 5.2.1

- Revert changes to handling of `List<int>` body data.

## 5.2.0+1

- Fix `DioErrorType` deprecation hint.

## 5.2.0

- Make `LogInterceptor` prints in DEBUG mode (when the assertion is enabled) by default.
- Deprecate `DioError` in favor of `DioException`.
- Fix `IOHttpClientAdapter.onHttpClientCreate` Repeated calls
- `IOHttpClientAdapter.onHttpClientCreate` has been deprecated and is scheduled for removal in
  Dio 6.0.0 - Please use the replacement `IOHttpClientAdapter.createHttpClient` instead.
- Using `CancelToken` no longer closes and re-creates `HttpClient` for each request when `IOHttpClientAdapter` is used.
- Fix timeout handling for browser `receiveTimeout`.
- Improve performance when sending binary data (`List<int>`/`Uint8List`). 

## 5.1.2

- Allow `FormData` to send a null entry value as an empty string.

## 5.1.1

- Revert changes to `CancelToken.cancel()` behavior, as a result the `DioError`
  provided by the `CancelToken.cancelError` does not contain useful information
  when the token was not used with a request.
- Fix wrong `ListFormat` being used for comparison during encoding of `FormData`
  and `application/x-www-form-urlencoded`, resulting in potential wrong output encoding
  for `ListFormat.multi` and `ListFormat.multiCompatible` since Dio 4.0.x.
- Respect `Options.listFormat` when encoding `x-www-url-encoded` content.

## 5.1.0

- Fix double-completion when using `connectionTimeout` on web platform.
- Allow defining adapter methods through their constructors.
- Fix `FormData` encoding regression for maps with dynamic keys, introduced in 5.0.3.
- Mark several static `DioMixin` functions as `@internal`.
- Make `DioError.stackTrace` non-nullable.
- Ensure `DioError.stackTrace` always points to the correct call site.

## 5.0.3

- Imply `List<Map>` as JSON content in `ImplyContentTypeInterceptor`.
- Fix `FormData` encoding for collections and objects.

## 5.0.2

- Improve code formats according to linter rules.
- Remove the force conversion for the response body.
- Fix `DioErrorType.cancel` in `Interceptors`.
- Fix wrong encoding of collection query parameters.
- Fix "unsupported operation" error on web platform.

## 5.0.1

- Add `ImplyContentTypeInterceptor` as a default interceptor.
- Add `Headers.multipartFormDataContentType` for headers usage.
- Fix variable shadowing of `withCredentials` in `browser_adapers.dart`.

## 5.0.0

- Raise the min Dart SDK version to 2.15.0 to support `BackgroundTransformer`.
- Change `Dio.transformer` from `DefaultTransformer` to `BackgroundTransformer`.
- Remove plain ASCII check in `FormData`.
- Allow asynchronized method with `savePath`.
- Allow `data` in all request methods.
- A platform independent `HttpClientAdapter` can now be instantiated by doing
  `dio.httpClientAdapter = HttpClientAdapter();`.
- Add `ValidateCertificate` to handle certificate pinning better.
- Support `Content-Disposition` header case sensitivity.

### Breaking Changes

- The default charset `utf-8` in `Headers` content type constants has been removed.
- `BaseOptions.setRequestContentTypeWhenNoPayload` has been removed.
- Improve `DioError`s. There are now more cases in which the inner original stacktrace is supplied.
- `HttpClientAdapter` must now be implemented instead of extended.
- Any classes specific to `dart:io` platforms can now be imported via `import 'package:dio/io.dart';`.
  Classes specific to web can be imported via `import 'package:dio/browser.dart';`.
- `connectTimeout`, `sendTimeout`, and `receiveTimeout` are now `Duration`s.

## 4.0.6

- fix #1452

## 4.0.5

- require Dart `2.12.1` which fixes exception handling for secure socket connections (#45214)
- Only delete file if it exists when downloading.
- Fix `BrowserHttpClientAdapter` canceled hangs
- Correct JSON MIME Type detection
- [Web] support send/receive progress in web platform
- refactor timeout logic
- use 'arraybuffer' instead of 'blob' for xhr requests in web platform

## 4.0.4

- Fix fetching null data in a response

## 4.0.3

- fix #1311

## 4.0.2

- Add QueuedInterceptor
- merge #1316 #1317

## 4.0.1

- merge pr #1177 #1196 #1205 #1224 #1225 #1227 #1256 #1263 #1291
- fix #1257

## 4.0.0

stable version

## 4.0.0-prev3

- fix #1091 , #1089 , #1087

## 4.0.0-prev2

- fix #1082 and # 1076

## 4.0.0-prev1

**Interceptors:** Add `handler` for Interceptor APIs which can specify
the subsequent interceptors processing logic more finely (whether to skip them or not).

## 4.0.0-beta7

- fix #1074

## 4.0.0-beta6

- fix #1070

## 4.0.0-beta5

- support ListParam

## 4.0.0-beta4

- fix #1060

## 4.0.0-beta3

- rename CollectionFormat to ListFormat
- change default value of Options.listFormat from `mutiComptible` to `multi`
- add upload_stream_test.dart

## 4.0.0-beta2

- support null-safety
- add `CollectionFormat` configuration in Options
- add `fetch` API for Dio
- rename DioErrorType enums from uppercase to camel style
- rename 'Options.merge' to 'Options.copyWith'

## 3.0.10 2020.8.7

1. fix #877 'dio.interceptors.errorLock.lock()'
2. fix #851
3. fix #641

## 3.0.9 2020.2.24

- Add test cases

## 3.0.8 2019.12.29

- Code style improvement

## 3.0.7 2019.11.25

- Merge #574 : fix upload image header error, support both oss and other server

## 3.0.6 2019.11.22

- revert #562, and fixed #566

## 3.0.5 2019.11.19

- merge #557 #531

## 3.0.4 2019.10.29

- fix #502 #515 #523

## 3.0.3 2019.10.1

- fix encode bug

## 3.0.2 2019.9.26

- fix #474 #480

## 3.0.2-dev.1 2019.9.20

- fix #470 #471

## 3.0.1 2019.9.20

- Fix #467
- Export `DioForNative` and `DioForBrowser` classes.

## 3.0.0

### New features

- Support Flutter Web.
- Extract [CookieManager](../plugins/cookie_manager) into a separate package（No need for Flutter Web）.
- Provides [HTTP/2.0 HttpClientAdapter](../plugins/http2_adapter).

### Change List

- ~~Options.cookies~~

- ~~Options.connectionTimeout~~ ；We should config connection timed out in `BaseOptions`. For keep-alive reasons, not every request requires a separate connection。

- `Options.followRedirects`、`Options.maxRedirects`、`Response.redirects` don't make sense in Flutter Web，because redirection can be automatically handled by browsers.
- ~~FormData.from~~，use `FormData.fromMap` instead.
- Delete ~~Formdata.asBytes()~~、~~Formdata.asBytesAsync()~~ , use `Formdata.readAsBytes()` instead.
- Delete ~~`UploadFileInfo`~~ class， `MultipartFile` instead.
- The return type of Interceptor's callback changes from `FutureOr<dynamic>` to `Future`.
  The reason is [here](https://dart.dev/guides/language/effective-dart/design#avoid-using-futureort-as-a-return-type).
- The type of `Response.headers` changes from `HttpHeaders` to `Headers`,
  because `HttpHeaders` is in "dart:io" library which is not supported in Flutter Web.

## 2.1.16

Add `deleteOnError` parameter to `downloadUri`

## 2.1.14

- fix #402 #385 #422

## 2.1.13

- fix #369

## 2.1.12

- fix #367 #365

## 2.1.10

- fix #360

## 2.1.9

- support flutter version>=1.8 (fix #357)

## 2.1.8

- fix #354 #312
- Allow "delete" method with request body(#223)

## 2.1.7

- fix #321 #318

## 2.1.6

- fix #316

## 2.1.5

- fix #309

## 2.1.4

- Add `options.responseDecoder`
- Make DioError catchable by implementing Exception instead of Error

## 2.1.3

Add `statusMessage` attribute for `Response` and `ResponseBody`

## 2.1.2

First Stable version for 2.x

## 2.0

**Refactor the Interceptors**

- Support add Multiple Interceptors.
- Add Log Interceptor
- Add CookieManager Interceptor

**API**

- Support Uri
- Support `queryParameters` for all request API
- Modify the `get` API

**Options**

- Separate Options to three class: Options、BaseOptions、RequestOptions
- Add `queryParameters` and `cookies` for BaseOptions

**Adapter**

- Abstract HttpClientAdapter layer.
- Provide a DefaultHttpClientAdapter which make http requests by `dart:io:HttpClient`

## 0.1.8

- change file name "TransFormer" to "Transformer"
- change "dio.transFormer" to "dio.transformer"
- change deprecated "UTF8" to "utf8"

## 0.1.5

- add `clear` method for dio instance

## 0.1.4

- fix `download` bugs

## 0.1.3

- support upload files with Array
- support create `HttpClient` by user self in `onHttpClientCreate`
- support generic
- bug fix

## 0.0.1

- Initial version, created by Stagehand

[Migration Guide]: ./migration_guide.md
