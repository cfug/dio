import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('application/json', () {
    expect(Transformer.isJsonMimeType('application/json'), isTrue);
  });

  test('text/json', () {
    expect(Transformer.isJsonMimeType('text/json'), isTrue);
  });

  test('application/vnd.example.com+json', () {
    expect(
      Transformer.isJsonMimeType('application/vnd.example.com+json'),
      isTrue,
    );
  });
}
