# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| >=5.0   | ✅        |
| < 5.0   | ❌        |

## Reporting a Vulnerability

Contact <cfug-team@googlegroups.com> with your vulnerability report.
Please do **not** open a public GitHub issue for security vulnerabilities.

---

## Secure Usage Guide

This section documents Dio's security-relevant behaviour, known limitations,
and recommended configuration for production applications.

### 1. Always Set Timeouts

All three timeouts default to `null` (no limit). A server that never sends
bytes will hold the connection open forever, exhausting resources and freezing
UI threads.

```dart
final dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    sendTimeout:    const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ),
);
```

Dio emits a developer warning (suppressed in release builds) when a request
is dispatched without `connectTimeout` or `receiveTimeout` set.

---

### 2. TLS and Certificate Validation

Dio uses `dart:io`'s `HttpClient` on native platforms, which validates the
server certificate against the system trust store by default. Do not disable
this:

```dart
// ❌ NEVER do this in production — disables ALL certificate validation
IOHttpClientAdapter(
  createHttpClient: () => HttpClient()
    ..badCertificateCallback = (cert, host, port) => true,
)
```

**Critical warning:** Setting `badCertificateCallback` to return `true`
causes `dart:io` to accept any certificate *before* Dio's own
`validateCertificate` callback is invoked, silently bypassing all pinning.

#### Certificate Pinning

Use `IOHttpClientAdapter.validateCertificate` together with the built-in
`CertificatePinner` helper (available via `package:dio/io.dart`):

```dart
import 'package:dio/io.dart';

final pinner = CertificatePinner(
  // Get fingerprint with:
  // openssl x509 -in cert.pem -fingerprint -sha1 -noout
  allowedSHA1Fingerprints: {'AA:BB:CC:DD:EE:FF:...'},
);

final dio = Dio();
dio.httpClientAdapter = IOHttpClientAdapter(
  validateCertificate: pinner.validate,
);
```

For SHA-256 pinning, add the `crypto` package and provide a custom
`ValidateCertificate` callback that computes
`sha256.convert(cert!.der).toString()`.

**Note:** `validateCertificate` only receives the *leaf* certificate. Pinning
to an intermediate CA or root requires a custom callback that inspects the
full chain via `SecurityContext`.

---

### 3. Redirect Security

By default Dio follows up to 5 redirects (`followRedirects: true`,
`maxRedirects: 5`). Redirects are handled manually by Dio (not delegated to
`dart:io`) so that **credential headers are stripped when a redirect crosses
an origin boundary** (different host or scheme), in accordance with
[RFC 9110 §15.4](https://www.rfc-editor.org/rfc/rfc9110#section-15.4).

Headers stripped on cross-origin redirects: `Authorization`,
`Proxy-Authorization`, `Cookie`.

To disable redirect following entirely:

```dart
final response = await dio.get(
  url,
  options: Options(followRedirects: false),
);
```

---

### 4. Logging — Do Not Expose Credentials

`LogInterceptor` masks sensitive headers by default using
`LogInterceptor.defaultRedactedHeaders`:

```text
authorization, proxy-authorization, cookie, set-cookie,
x-api-key, x-auth-token, x-csrf-token
```

These are replaced with `**REDACTED**` in all log output. To customise:

```dart
// Add extra headers to mask
dio.interceptors.add(
  LogInterceptor(
    redactedHeaders: {
      ...LogInterceptor.defaultRedactedHeaders,
      'x-my-secret-header',
    },
  ),
);

// Disable masking (local development only — never in production)
dio.interceptors.add(LogInterceptor(redactedHeaders: {}));
```

Do **not** enable `LogInterceptor` in release builds without confirming that
credential headers are masked, as logs are accessible via `adb logcat` and
may be forwarded to crash-reporting services.

---

### 5. Response Size Limits

Dio does not cap response body size by default. A server can stream an
arbitrarily large body into memory. Set `maxResponseSize` to guard against
this:

```dart
final dio = Dio(
  BaseOptions(
    maxResponseSize: 10 * 1024 * 1024, // 10 MB global limit
  ),
);

// Or per-request
final response = await dio.get(
  url,
  options: Options(maxResponseSize: 1 * 1024 * 1024), // 1 MB
);
```

When the limit is exceeded, a `DioException` with type
`DioExceptionType.badResponse` is thrown and the connection is closed
immediately without buffering the remaining bytes.

---

### 6. Multipart Boundary Generation

Multipart form-data boundaries are generated with `dart:math`'s
`Random.secure()` (a CSPRNG backed by the OS entropy source). This prevents
boundary prediction and multipart-injection attacks.

---

### 7. Platform-Specific Notes

#### iOS — App Transport Security (ATS)

iOS enforces HTTPS and TLS 1.2+ by default. HTTP connections require an ATS
exception in `Info.plist`. Avoid broad `NSAllowsArbitraryLoads` exceptions;
use per-domain exceptions instead.

#### Android — Network Security Config

Android 9+ blocks cleartext HTTP by default. Configure a
`network_security_config.xml` if you need to pin certificates or allow
specific cleartext domains. Never use `android:usesCleartextTraffic="true"`
globally in production.

---

### 8. Cookie Security

When using `dio_cookie_manager`, cookies are stored and replayed by the
`cookie_jar` package. Note that Dio does not inspect `HttpOnly` or `Secure`
cookie flags — enforcement of those flags depends on the `cookie_jar`
implementation and your storage configuration. Use an encrypted cookie jar
for sensitive session cookies.

---

### 9. Production Baseline

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

Dio createSecureDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout:    const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      maxResponseSize: 10 * 1024 * 1024, // 10 MB
    ),
  );

  // Certificate pinning (replace fingerprint with your certificate's)
  final pinner = CertificatePinner(
    allowedSHA1Fingerprints: {'AA:BB:CC:DD:EE:FF:00:11:22:33:...'},
  );
  dio.httpClientAdapter = IOHttpClientAdapter(
    validateCertificate: pinner.validate,
  );

  // Logging only in debug; credentials are masked by default
  assert(() {
    dio.interceptors.add(LogInterceptor());
    return true;
  }());

  return dio;
}
```
