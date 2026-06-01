@TestOn('browser')
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:dio_web_adapter/src/download_trigger.dart' as download_trigger;
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('DioForBrowser.download', () {
    late DioForBrowser dio;
    late _TestAdapter adapter;
    late List<_Download> downloads;

    setUp(() {
      adapter = _TestAdapter();
      dio = DioForBrowser(BaseOptions(baseUrl: 'https://example.com'))
        ..httpClientAdapter = adapter;
      downloads = [];
      download_trigger.triggerBrowserDownload = ({
        required Uint8List bytes,
        required String filename,
        String? contentType,
      }) {
        downloads.add(
          _Download(
            bytes: bytes,
            filename: filename,
            contentType: contentType,
          ),
        );
      };
    });

    tearDown(download_trigger.resetBrowserDownloadHooks);

    test('downloads bytes using savePath as suggested filename', () async {
      adapter.body = Uint8List.fromList([1, 2, 3]);
      adapter.headers = {
        Headers.contentLengthHeader: ['3'],
        Headers.contentTypeHeader: ['application/octet-stream'],
      };

      final options = Options(responseType: ResponseType.plain);
      var progressEventCount = 0;
      int? received;
      int? total;

      final response = await dio.download(
        '/bytes/3',
        'nested/file.bin',
        options: options,
        onReceiveProgress: (count, expectedTotal) {
          progressEventCount++;
          received = count;
          total = expectedTotal;
        },
      );

      expect(response.statusCode, 200);
      expect(response.data, [1, 2, 3]);
      expect(options.responseType, ResponseType.plain);
      expect(adapter.requests.single.responseType, ResponseType.bytes);
      expect(progressEventCount, greaterThanOrEqualTo(1));
      expect(received, 3);
      expect(total, 3);
      expect(downloads, hasLength(1));
      expect(downloads.single.filename, 'file.bin');
      expect(downloads.single.bytes, [1, 2, 3]);
      expect(downloads.single.contentType, 'application/octet-stream');
    });

    test('keeps query and fragment characters in suggested filenames',
        () async {
      await dio.download('/bytes/1', 'report#1?.csv');

      expect(downloads.single.filename, 'report#1?.csv');
    });

    test('resolves savePath callback after response headers are available',
        () async {
      adapter.body = Uint8List.fromList([4, 5]);

      await dio.download(
        '/payload',
        (Headers headers) {
          expect(headers.value('redirects'), '0');
          expect(headers.value('uri'), 'https://example.com/payload');
          return 'from-headers.txt';
        },
      );

      expect(downloads.single.filename, 'from-headers.txt');
      expect(downloads.single.bytes, [4, 5]);
    });

    test('rejects unsupported savePath types', () async {
      await expectLater(
        dio.download('/bytes/1', Object()),
        throwsA(isA<ArgumentError>()),
      );
      expect(adapter.requests, isEmpty);
      expect(downloads, isEmpty);
    });

    test('rejects append mode', () async {
      await expectLater(
        dio.download(
          '/bytes/1',
          'file.bin',
          fileAccessMode: FileAccessMode.append,
        ),
        throwsA(isA<UnsupportedError>()),
      );
      expect(adapter.requests, isEmpty);
      expect(downloads, isEmpty);
    });

    test('does not trigger browser download for bad responses', () async {
      adapter.statusCode = 500;
      adapter.body = Uint8List.fromList([1]);

      await expectLater(
        dio.download('/status/500', 'error.bin'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.badResponse,
          ),
        ),
      );
      expect(downloads, isEmpty);
    });

    test('does not trigger browser download when cancelled before request',
        () async {
      final cancelToken = CancelToken()..cancel('cancelled');

      await expectLater(
        dio.download('/bytes/1', 'cancelled.bin', cancelToken: cancelToken),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
      expect(downloads, isEmpty);
    });

    test('does not trigger browser download when cancelled after response',
        () async {
      final cancelToken = CancelToken();
      final completer = Completer<String>();
      adapter.body = Uint8List.fromList([1]);

      final download = dio.download(
        '/bytes/1',
        (_) => completer.future,
        cancelToken: cancelToken,
      );

      await Future<void>.delayed(Duration.zero);
      cancelToken.cancel('cancelled');
      completer.complete('cancelled.bin');

      await expectLater(
        download,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(downloads, isEmpty);
    });

    test('wraps browser download trigger failures in a DioException', () async {
      download_trigger.triggerBrowserDownload = ({
        required Uint8List bytes,
        required String filename,
        String? contentType,
      }) {
        throw StateError('trigger');
      };

      await expectLater(
        dio.download('/bytes/1', 'file.bin'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.unknown)
              .having((e) => e.error, 'error', isA<StateError>()),
        ),
      );
    });
  });

  group('triggerBrowserDownload', () {
    tearDown(download_trigger.resetBrowserDownloadHooks);

    test('creates, clicks, removes, and revokes an object URL', () {
      final revokedUrls = <String>[];
      web.HTMLAnchorElement? clickedAnchor;

      download_trigger.createObjectUrl = (_) => 'blob:dio-test';
      download_trigger.revokeObjectUrl = revokedUrls.add;
      download_trigger.clickDownloadAnchor = (anchor) {
        clickedAnchor = anchor;
        expect(web.document.body!.contains(anchor), isTrue);
      };

      download_trigger.triggerBrowserDownload(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'file.bin',
        contentType: 'application/octet-stream',
      );

      expect(clickedAnchor, isNotNull);
      expect(clickedAnchor!.href, 'blob:dio-test');
      expect(clickedAnchor!.download, 'file.bin');
      expect(web.document.body!.contains(clickedAnchor), isFalse);
      expect(revokedUrls, ['blob:dio-test']);
    });

    test('revokes the object URL when clicking throws', () {
      final revokedUrls = <String>[];

      download_trigger.createObjectUrl = (_) => 'blob:dio-test';
      download_trigger.revokeObjectUrl = revokedUrls.add;
      download_trigger.clickDownloadAnchor = (_) => throw StateError('click');

      expect(
        () => download_trigger.triggerBrowserDownload(
          bytes: Uint8List.fromList([1]),
          filename: 'file.bin',
        ),
        throwsStateError,
      );

      expect(revokedUrls, ['blob:dio-test']);
    });

    test('revokes the object URL when creating the anchor throws', () {
      final revokedUrls = <String>[];

      download_trigger.createObjectUrl = (_) => 'blob:dio-test';
      download_trigger.revokeObjectUrl = revokedUrls.add;
      download_trigger.createDownloadAnchor =
          (_, __) => throw StateError('anchor');

      expect(
        () => download_trigger.triggerBrowserDownload(
          bytes: Uint8List.fromList([1]),
          filename: 'file.bin',
        ),
        throwsStateError,
      );

      expect(revokedUrls, ['blob:dio-test']);
    });
  });
}

class _TestAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Uint8List body = Uint8List(0);
  Map<String, List<String>> headers = const {};
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromBytes(
      body,
      statusCode,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Download {
  const _Download({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String? contentType;
}
