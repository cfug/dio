// Taken from https://github.com/Zekfad/fetch_api/blob/dee32249d9ecb4bf6b4eb05062930b5d704423c9/lib/src/js_promise_or.dart
// Copyright 2023-2024 Yaroslav Vorobev and contributors. All rights reserved.
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import 'dart:async';
import 'dart:js_interop';

extension type JSPromiseOr<T extends JSAny?>._(JSAny _) implements JSAny {
  static JSPromiseOr<T>? fromDart<T extends JSAny?>(FutureOr<T> futureOr) => switch (futureOr) {
        final Future<T> future => future.toJS,
        // Always succeeds, because of JS type erasure.
        final T value => value,
      } as JSPromiseOr<T>?;

  FutureOr<T> get toDart => switch (this) {
        final JSPromise<T> promise => promise.toDart as FutureOr<T>,
        // Always succeeds, because of JS type erasure.
        final T value => value,
        _ => throw StateError('Invalid state op JSPromiseOr: unexpected type: $runtimeType'),
      };
}

extension FutureOrToJSPromiseOr<T extends JSAny?> on FutureOr<T> {
  JSPromiseOr<T>? get toJSPromiseOr => switch (this) {
        final Future<T> future => future.toJS as JSPromiseOr<T>,
        // Always succeeds, because of JS type erasure.
        final T value => value as JSPromiseOr<T>?,
      };
}
