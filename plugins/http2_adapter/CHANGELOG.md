# CHANGELOG

**Before you upgrade: Breaking changes might happen in major and minor versions of packages.<br/>
See the [Migration Guide][] for the complete breaking changes list.**

## Unreleased

- Add `handshakeTimeout` (defaults to 15 seconds) to the `ConnectionManager` to prevent long waiting if there's something wrong with the handshake procedure.

## 2.6.0

- Make cached connections respect redirections and scheme.

## 2.5.3

- Improves memory allocating when using `CancelToken`.

## 2.5.2

- Remove client stream termination in `Http2Adapter`.

## 2.5.1

- Wrap `SocketException` in `DioExceptionType.connectionError`
  instead of `DioExceptionType.unknown`.

## 2.5.0

- Fix cancellation for streamed responses and downloads.
- Fix progress for streamed responses and downloads.
- Bump minimum Dart SDK to 3.0.0 as required by the `http2` package.
- Allows `HTTP/1.0` when connecting to proxies.
- Add the ability to use a fallback `HttpClientAdapter`
  when HTTP/2 is unavailable for the current request.

## 2.4.0

- Support non-TLS connection requests.
- Improve the implementation of `receiveTimeout`.
- Add more header value types implicit support.

## 2.3.2

- Implement `sendTimeout` and `receiveTimeout` for the adapter.
- Fix redirect not working when requestStream is null.
- Ignores `Duration.zero` timeouts.

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

[Migration Guide]: doc/migration_guide.md
