// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

enum Category {
  top,
  bottom,
  strange,
  charmed,
  up,
  down,
  @JsonValue('not_discovered_yet')
  notDiscoveredYet
}

enum StatusCode {
  @JsonValue(200)
  success,
  @JsonValue(404)
  notFound,

  // Intentionally using a non-int value to validate heterogeneous
  // type-inference.
  @JsonValue('500')
  weird,

  unknown,
}

Duration durationFromInt(int ms) =>
    ms == null ? null : Duration(milliseconds: ms);

int durationToInt(Duration duration) => duration?.inMilliseconds;

DateTime dateTimeFromEpochUs(int us) =>
    us == null ? null : DateTime.fromMicrosecondsSinceEpoch(us);

int dateTimeToEpochUs(DateTime dateTime) => dateTime?.microsecondsSinceEpoch;

bool deepEquals(a, b) => const DeepCollectionEquality().equals(a, b);

class Platform {
  final String description;

  static const Platform foo = Platform._('foo');
  static const Platform undefined = Platform._('undefined');

  const Platform._(this.description);

  factory Platform.fromJson(String value) {
    switch (value) {
      case 'foo':
        return foo;
      case 'undefined':
        return undefined;
      default:
        throw ArgumentError.value(value, 'value', 'Not a supported value.');
    }
  }

  String toJson() => description;
}

abstract class ItemCore {
  final int price;

  ItemCore(this.price);
}

class MyList<T> extends ListBase<T> {
  final List<T> _data;

  MyList(Iterable<T> source) : _data = source.toList() ?? [];

  factory MyList.fromJson(List<T> items) => MyList(items);

  @override
  int get length => _data.length;

  @override
  set length(int value) {
    _data.length = value;
  }

  @override
  T operator [](int index) => _data[index];

  @override
  void operator []=(int index, T value) {
    _data[index] = value;
  }
}
