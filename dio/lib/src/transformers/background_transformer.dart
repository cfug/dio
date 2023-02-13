import 'dart:async';
import 'dart:convert';

import 'package:dio/src/compute/compute.dart';
import 'package:dio/src/transformers/sync_transformer.dart';

/// [BackgroundTransformer] will do the deserialization of JSON
/// in a background isolate if possible.
class BackgroundTransformer extends SyncTransformer {
  BackgroundTransformer() : super(jsonDecodeCallback: _decodeJson);
}

FutureOr<dynamic> _decodeJson(String text) {
  // Taken from https://github.com/flutter/flutter/blob/135454af32477f815a7525073027a3ff9eff1bfd/packages/flutter/lib/src/services/asset_bundle.dart#L87-L93
  // 50 KB of data should take 2-3 ms to parse on a Moto G4, and about 400 μs
  // on a Pixel 4.
  if (text.codeUnits.length < 50 * 1024) {
    return jsonDecode(text);
  }
  // For strings larger than 50 KB, run the computation in an isolate to
  // avoid causing main thread jank.
  return compute(jsonDecode, text);
}
