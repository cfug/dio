// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file corresponds to Flutter's
// [`foundation/_isolates_web.dart`](https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/foundation/_isolates_web.dart).
//
// Changes are only synced with the `stable` branch.
//
// Last synced commit:
// [978a2e7](https://github.com/flutter/flutter/commit/978a2e7bf6a2ed287130af8dbd94cef019fb7bef)
//
// The changes are currently manually synced. If you noticed that the Flutter's
// original `compute` function (and any of the related files) have changed
// on the `stable` branch and you would like to see those changes in the `compute` package
// please open an [issue](https://github.com/dartsidedev/compute/issues),
// and I'll try my best to "merge".
//
// The file is intentionally not refactored so that it is easier to keep the
// compute package up to date with Flutter's implementation.

import 'package:dio/src/compute/compute.dart' as c;

/// The dart:html implementation of [c.compute].
Future<R> compute<Q, R>(
  c.ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
}) async {
  // To avoid blocking the UI immediately for an expensive function call, we
  // pump a single frame to allow the framework to complete the current set
  // of work.
  await null;
  return callback(message);
}
