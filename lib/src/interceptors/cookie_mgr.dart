import 'dart:io';
import '../interceptor.dart';
import '../options.dart';
import '../response.dart';
import 'package:cookie_jar/cookie_jar.dart';

class CookieManager extends Interceptor {
  /// Cookie manager for http requests。Learn more details about
  /// CookieJar please refer to [cookie_jar](https://github.com/flutterchina/cookie_jar)
  final CookieJar cookieJar;

  /// Dart SDK will cause an exception When response cookie's value is empty,
  /// eg. 'Set-Cookie: session=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT'
  ///
  /// This is a bug of Dart SDK: https://github.com/dart-lang/sdk/issues/35804
  /// So, we should normalize the cookie value before this bug is fixed.
  bool needNormalize = false;

  CookieManager(this.cookieJar) {
    // Set `needNormalize` value by Duck test
    try {
      Cookie.fromSetCookieValue("k=;");
    } catch (e) {
      needNormalize = true;
    }
  }

  @override
  onRequest(RequestOptions options) {
    var cookies=cookieJar.loadForRequest(options.uri)..addAll(options.cookies);
    options.headers["cookie"] = getCookies(cookies);
  }

  @override
  onResponse(Response response) {
    List<String> cookies = response.headers[HttpHeaders.setCookieHeader];
    if (cookies != null) {
      if (needNormalize) {
        var _cookies = normalizeCookies(cookies);
        cookies
          ..clear()
          ..addAll(_cookies);
      }
      cookieJar.saveFromResponse(
        response.request.uri,
        cookies.map((str) => Cookie.fromSetCookieValue(str)).toList(),
      );
    }
  }

  static String getCookies(List<Cookie> cookies) {
    StringBuffer buffer = new StringBuffer();
    cookies
        ?.forEach((cookie) => buffer.write('${cookie.name}=${cookie.value};'));
    return buffer.toString();
  }

  static List<String> normalizeCookies(List<String> cookies) {
    if (cookies != null) {
      const String expires = " Expires=Thu, 01 Jan 1970 00:00:00 GMT";
      return cookies.map((cookie) {
        var _cookie = cookie.split(";");
        var kv = _cookie.first?.split("=");
        if (kv != null && kv[1].isEmpty) {
          kv[1] = "_invalid_";
          _cookie[0] = kv.join('=');
          if (_cookie.length > 1) {
            int i = 1;
            while (i < _cookie.length) {
              if (_cookie[i].trim().toLowerCase().startsWith("expires")) {
                _cookie[i] = expires;
                break;
              }
              ++i;
            }
            if (i == _cookie.length) {
              _cookie.add(expires);
            }
          }
        }
        return _cookie.join(";");
      }).toList();
    }
    return [];
  }
}
