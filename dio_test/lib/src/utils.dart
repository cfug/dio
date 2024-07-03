const kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

const nonRoutableUrl = 'http://10.0.0.0';

/// https://github.com/dart-lang/sdk/blob/59add4f01ef4741e10f64db9c2c8655cfe738ccb/tests/corelib/finalizer_test.dart#L86-L101
void produceGarbage() {
  const approximateWordSize = 4;

  List<dynamic> sink = [];
  for (int i = 0; i < 500; ++i) {
    final filler = i % 2 == 0 ? 1 : sink;
    if (i % 250 == 1) {
      // 2 x 25 MB in old space.
      sink = List.filled(25 * 1024 * 1024 ~/ approximateWordSize, filler);
    } else {
      // 498 x 50 KB in new space
      sink = List.filled(50 * 1024 ~/ approximateWordSize, filler);
    }
  }
  print(sink.hashCode); // Ensure there's real use of the allocation.
}
