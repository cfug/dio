import 'dart:async';
import 'dart:typed_data';
import '../dio_error.dart';
import '../options.dart';
import '../adapter.dart';
import 'dart:html';
import '../headers.dart';

HttpClientAdapter createAdapter() => BrowserHttpClientAdapter();

class BrowserHttpClientAdapter implements HttpClientAdapter {
  /// These are aborted if the client is closed.
  final _xhrs = <HttpRequest>[];

  /// Whether to send credentials such as cookies or authorization headers for
  /// cross-site requests.
  ///
  /// Defaults to `false`.
  ///
  /// You can also override this value in Options.extra['withCredentials'] for each request
  bool withCredentials = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) {
    var xhr = HttpRequest();
    _xhrs.add(xhr);

    xhr
      ..open(options.method, options.uri.toString(), async: true)
      ..responseType = 'blob'
      ..withCredentials = options.extra['withCredentials'] ?? withCredentials;
    options.headers.remove(Headers.contentLengthHeader);
    options.headers.forEach((key, v) => xhr.setRequestHeader(key, '$v'));

    var completer = Completer<ResponseBody>();

    xhr.onLoad.first.then((_) {
      // TODO: Set the response type to "arraybuffer" when issue 18542 is fixed.
      var blob = xhr.response ?? Blob([]);
      var reader = FileReader();

      reader.onLoad.first.then((_) {
        var body = reader.result as Uint8List;
        completer.complete(
          ResponseBody.fromBytes(
            body,
            xhr.status,
            headers: xhr.responseHeaders
                .map((k, v) => MapEntry(k.toLowerCase(), v.split(','))),
            statusMessage: xhr.statusText,
            isRedirect: xhr.status == 302 || xhr.status == 301,
          ),
        );
      });

      reader.onError.first.then((error) {
        completer.completeError(
          DioError(
            type: DioErrorType.RESPONSE,
            error: error,
            request: options,
          ),
          StackTrace.current,
        );
      });
      reader.readAsArrayBuffer(blob);
    });

    xhr.onError.first.then((_) {
      // Unfortunately, the underlying XMLHttpRequest API doesn't expose any
      // specific information about the error itself.
      completer.completeError(
        DioError(
          type: DioErrorType.RESPONSE,
          error: 'XMLHttpRequest error.',
          request: options,
        ),
        StackTrace.current,
      );
    });

    cancelFuture?.then((_) {
      if (xhr.readyState < 4 && xhr.readyState > 0) {
        try {
          xhr.abort();
        } catch (e) {
          // ignore
        }
      }
    });

    if (requestStream == null) {
      xhr.send();
    } else {
      requestStream
          .reduce((a, b) => Uint8List.fromList([...a, ...b]))
          .then(xhr.send);
    }

    return completer.future.whenComplete(() {
      _xhrs.remove(xhr);
    });
  }

  /// Closes the client.
  ///
  /// This terminates all active requests.
  @override
  void close({bool force = false}) {
    if (force) {
      for (var xhr in _xhrs) {
        xhr.abort();
      }
    }
    _xhrs.clear();
  }
}
