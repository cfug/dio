# CHANGELOG

## Unreleased

- Support `cupertino_http` 2.0.0

## 1.3.0

- Provide fix suggestions for `dart fix`.
- Bump cronet_http version to `>=0.4.0 <=2.0.0`.

## 1.2.0

- Adds `createCronetEngine` and `createCupertinoConfiguration`
  to deprecate `cronetEngine` and `cupertinoConfiguration`
  for the `NativeAdapter`, to avoid platform exceptions.
- Improve the request stream byte conversion.

## 1.1.1

- Adds the missing `flutter` dependency.

## 1.1.0

- Bump `cronet_http` version.
- Minimal required Dart version is now 3.1.
- Minimal required Flutter version is now 3.13.0.
- Allow case-sensitive header keys with the `preserveHeaderCase` flag through options.

## 1.0.0+2

- Add topics to packages.

## 1.0.0+1

- Update dependencies to make use of stable versions.
- Replace `DioError` with `DioException`.
- Fix `onReceiveProgress` callback.

## 0.1.0

- Bump cupertino_http and cronet_http versions.
- Improve code formats according to linter rules.

## 0.0.1

- Initial version.
