# CHANGELOG

## Unreleased

*None.*

## 3.1.0

- Replace `DioError` with `DioException`.

## 3.0.0

### Breaking changes

- Bump cookie_jar from 3.0.0 to 4.0.0.
  Upgrading to this version will lose all previous cookies.

## 2.1.4

- Fix cookie not applied to the original destination during redirect handling.
- Resolves the location for cookies during redirect handling.

## 2.1.3

- Allow `Set-Cookie` to be parsed in redirect responses.
- Fix new cookies being replaced by old cookies with the same name.
- Sort the cookie by path (longer path first).

## 2.1.2

- Fix empty cookie parsing and header value set.
- Improve code formats according to linter rules.

## 2.1.1

- Fix #1651
- Fix #1674

## 2.1.0

- For the `dio`'s 5.0 release.

## 2.0.0

- support dio 4.0.0

## 2.0.0-beta1

- support nullsafety

## 1.0.0 - 2019.9.18

- First stable version

## 0.0.1 - 2019.9.17

- A cookie manager for Dio.
