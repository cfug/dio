import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('JSON MimeType "application/json" ', () {
    expect(Transformer.isJsonMimeType("application/json"), isTrue);
  });

  test('JSON MimeType "text/json" ', () {
    expect(Transformer.isJsonMimeType("text/json"), isTrue);
  });

  test('JSON MimeType "application/vnd.example.com+json" ', () {
    expect(
        Transformer.isJsonMimeType("application/vnd.example.com+json"), isTrue);
  });
}
