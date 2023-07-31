// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'simple_object.dart';

abstract class KitchenSinkFactory<K, V> {
  String get description;
  bool get anyMap;
  bool get checked;
  bool get nullable;
  bool get excludeNull;
  bool get explicitToJson;

  KitchenSink ctor({
    int ctorValidatedNo42,
    Iterable iterable,
    Iterable<dynamic> dynamicIterable,
    Iterable<Object> objectIterable,
    Iterable<int> intIterable,
    Iterable<DateTime> dateTimeIterable,
  });

  KitchenSink fromJson(Map<K, V> json);

  JsonConverterTestClass jsonConverterCtor();

  JsonConverterTestClass jsonConverterFromJson(Map<String, dynamic> json);

  @override
  String toString() => description;
}

abstract class JsonConverterTestClass {
  Map<String, dynamic> toJson();
}

abstract class KitchenSink {
  int get ctorValidatedNo42;
  DateTime dateTime;
  BigInt bigInt;

  Iterable get iterable;
  Iterable<dynamic> get dynamicIterable;
  Iterable<Object> get objectIterable;
  Iterable<int> get intIterable;

  Iterable<DateTime> get dateTimeIterable;

  List list;
  List<dynamic> dynamicList;
  List<Object> objectList;
  List<int> intList;
  List<DateTime> dateTimeList;

  Set set;
  Set<dynamic> dynamicSet;
  Set<Object> objectSet;
  Set<int> intSet;
  Set<DateTime> dateTimeSet;

  Map map;
  Map<String, String> stringStringMap;
  Map<dynamic, int> dynamicIntMap;
  Map<Object, DateTime> objectDateTimeMap;

  List<Map<String, Map<String, List<List<DateTime>>>>> crazyComplex;

  Map<String, bool> val;
  bool writeNotNull;
  String string;

  SimpleObject get simpleObject;

  int validatedPropertyNo42;

  Map<String, dynamic> toJson();
}

// TODO: finish this...
bool sinkEquals(KitchenSink a, Object other) =>
    other is KitchenSink &&
    a.ctorValidatedNo42 == other.ctorValidatedNo42 &&
    a.dateTime == other.dateTime &&
    _deepEquals(a.iterable, other.iterable) &&
    _deepEquals(a.dynamicIterable, other.dynamicIterable) &&
    // objectIterable
    // intIterable
    _deepEquals(a.dateTimeIterable, other.dateTimeIterable) &&
    // list
    // dynamicList
    // objectList
    // intList
    _deepEquals(a.dateTimeList, other.dateTimeList) &&
    // map
    // stringStringMap
    // stringIntMap
    _deepEquals(a.objectDateTimeMap, other.objectDateTimeMap) &&
    _deepEquals(a.crazyComplex, other.crazyComplex) &&
    // val
    a.writeNotNull == other.writeNotNull &&
    a.string == other.string;

bool _deepEquals(Object a, Object b) =>
    const DeepCollectionEquality().equals(a, b);
