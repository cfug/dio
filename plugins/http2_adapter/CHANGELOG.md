# CHANGELOG

## Unreleased

- Implement `sendTimeout` and `receiveTimeout` for the adapter.
- Fix redirect not working when requestStream is null.

## 2.3.1+1

- Add topics to packages.

## 2.3.1

- Fix cached `initFuture` not remove when throw exception.

## 2.3.0

- Replace `DioError` with `DioException`.

## 2.2.0

- Support proxy for the adapter.
- Improve code formats according to linter rules.

## 2.1.0

- For the `dio`'s 5.0 release.
- Add `validateCertificate` for `ClientSetting`.

## 2.0.0

- support dio 4.0.0

## 2.0.0-beta2

- support null-safety
- support dio 4.x

## 1.0.1 - 2020.8.7

- merge #760

## 1.0.0 - 2019.9.18

- Support redirect

## 0.0.2 - 2019.9.17

- A Dio HttpAdapter which support Http/2.0.
