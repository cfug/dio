import 'dart:typed_data';

/// Consolidates a stream of [Uint8List] into a single [Uint8List]
Future<Uint8List> consolidateBytes(Stream<Uint8List> stream) async {
  final builder = BytesBuilder(copy: false);

  await for (final chunk in stream) {
    builder.add(chunk);
  }

  return builder.takeBytes();
}
