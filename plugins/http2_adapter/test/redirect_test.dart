import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('Http2Adapter.resolveRedirectUri', () {
    test('empty location', () async {
      final current = Uri.parse('https://example.com');
      final result = Http2Adapter.resolveRedirectUri(
        current,
        Uri.parse(''),
      );
      expect(result.toString(), current.toString());
    });

    test('relative location 1', () async {
      final result = Http2Adapter.resolveRedirectUri(
        Uri.parse('https://example.com/foo'),
        Uri.parse('/bar'),
      );

      expect(result.toString(), 'https://example.com/bar');
    });

    test('relative location 2', () async {
      final result = Http2Adapter.resolveRedirectUri(
        Uri.parse('https://example.com/foo'),
        Uri.parse('../bar'),
      );
      expect(result.toString(), 'https://example.com/bar');
    });

    test('different location', () async {
      final current = Uri.parse('https://example.com/foo');
      final target = 'https://somewhere.com/bar';
      final result = Http2Adapter.resolveRedirectUri(
        current,
        Uri.parse(target),
      );
      expect(result.toString(), target);
    });
  });
}
