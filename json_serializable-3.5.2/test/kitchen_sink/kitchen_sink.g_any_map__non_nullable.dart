// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: annotate_overrides, hash_and_equals
import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';
import 'kitchen_sink_interface.dart' as k;
import 'simple_object.dart';
import 'strict_keys_object.dart';

part 'kitchen_sink.g_any_map__non_nullable.g.dart';

// NOTE: these methods are replaced in the `non_nullable` cases to return
// non-null values.
List<T> _defaultList<T>() => <T>[];
Set<T> _defaultSet<T>() => <T>{};
Map<String, T> _defaultMap<T>() => <String, T>{};
SimpleObject _defaultSimpleObject() => SimpleObject(42);
StrictKeysObject _defaultStrictKeysObject() => StrictKeysObject(10, 'cool');

const k.KitchenSinkFactory factory = _Factory();

class _Factory implements k.KitchenSinkFactory<dynamic, dynamic> {
  const _Factory();

  String get description => 'any_map__non_nullable';
  bool get anyMap => true;
  bool get checked => false;
  bool get nullable => false;
  bool get excludeNull => false;
  bool get explicitToJson => false;

  k.KitchenSink ctor({
    int ctorValidatedNo42,
    Iterable iterable,
    Iterable dynamicIterable,
    Iterable<Object> objectIterable,
    Iterable<int> intIterable,
    Iterable<DateTime> dateTimeIterable,
  }) =>
      KitchenSink(
        ctorValidatedNo42: ctorValidatedNo42,
        iterable: iterable,
        dynamicIterable: dynamicIterable,
        objectIterable: objectIterable,
        intIterable: intIterable,
        dateTimeIterable: dateTimeIterable,
      );

  k.KitchenSink fromJson(Map json) => KitchenSink.fromJson(json);

  k.JsonConverterTestClass jsonConverterCtor() => JsonConverterTestClass();

  k.JsonConverterTestClass jsonConverterFromJson(Map<String, dynamic> json) =>
      JsonConverterTestClass.fromJson(json);
}

@JsonSerializable(
  nullable: false,
  anyMap: true,
)
class KitchenSink implements k.KitchenSink {
  // NOTE: exposing these as Iterable, but storing the values as List
  // to make the equality test work trivially.
  final Iterable _iterable;
  final Iterable<dynamic> _dynamicIterable;
  final Iterable<Object> _objectIterable;
  final Iterable<int> _intIterable;
  final Iterable<DateTime> _dateTimeIterable;

  @JsonKey(name: 'no-42')
  final int ctorValidatedNo42;

  KitchenSink({
    this.ctorValidatedNo42,
    Iterable iterable,
    Iterable<dynamic> dynamicIterable,
    Iterable<Object> objectIterable,
    Iterable<int> intIterable,
    Iterable<DateTime> dateTimeIterable,
  })  : _iterable = iterable?.toList() ?? _defaultList(),
        _dynamicIterable = dynamicIterable?.toList() ?? _defaultList(),
        _objectIterable = objectIterable?.toList() ?? _defaultList(),
        _intIterable = intIterable?.toList() ?? _defaultList(),
        _dateTimeIterable = dateTimeIterable?.toList() ?? _defaultList() {
    if (ctorValidatedNo42 == 42) {
      throw ArgumentError.value(
          42, 'ctorValidatedNo42', 'The value `42` is not allowed.');
    }
  }

  factory KitchenSink.fromJson(Map json) => _$KitchenSinkFromJson(json);

  Map<String, dynamic> toJson() => _$KitchenSinkToJson(this);

  DateTime dateTime = DateTime(1981, 6, 5);

  BigInt bigInt = BigInt.parse('10000000000000000000');

  Iterable get iterable => _iterable;
  Iterable<dynamic> get dynamicIterable => _dynamicIterable;
  Iterable<Object> get objectIterable => _objectIterable;
  Iterable<int> get intIterable => _intIterable;

  Set set = _defaultSet();
  Set<dynamic> dynamicSet = _defaultSet();
  Set<Object> objectSet = _defaultSet();
  Set<int> intSet = _defaultSet();
  Set<DateTime> dateTimeSet = _defaultSet();

  // Added a one-off annotation on a property (not a field)
  @JsonKey(name: 'datetime-iterable')
  Iterable<DateTime> get dateTimeIterable => _dateTimeIterable;

  List list = _defaultList();
  List<dynamic> dynamicList = _defaultList();
  List<Object> objectList = _defaultList();
  List<int> intList = _defaultList();
  List<DateTime> dateTimeList = _defaultList();

  Map map = _defaultMap();
  Map<String, String> stringStringMap = _defaultMap();
  Map<dynamic, int> dynamicIntMap = _defaultMap();
  Map<Object, DateTime> objectDateTimeMap = _defaultMap();

  List<Map<String, Map<String, List<List<DateTime>>>>> crazyComplex =
      _defaultList();

  // Handle fields with names that collide with helper names
  Map<String, bool> val = _defaultMap();
  bool writeNotNull;
  @JsonKey(name: r'$string')
  String string;

  SimpleObject simpleObject = _defaultSimpleObject();

  StrictKeysObject strictKeysObject = _defaultStrictKeysObject();

  int _validatedPropertyNo42;
  int get validatedPropertyNo42 => _validatedPropertyNo42;

  set validatedPropertyNo42(int value) {
    if (value == 42) {
      throw StateError('Cannot be 42!');
    }
    _validatedPropertyNo42 = value;
  }

  bool operator ==(Object other) => k.sinkEquals(this, other);
}

@JsonSerializable(
  nullable: false,
  anyMap: true,
)
// referencing a top-level field should work
@durationConverter
// referencing via a const constructor should work
@BigIntStringConverter()
@TrivialNumberConverter.instance
@EpochDateTimeConverter()
class JsonConverterTestClass implements k.JsonConverterTestClass {
  JsonConverterTestClass();

  factory JsonConverterTestClass.fromJson(Map<String, dynamic> json) =>
      _$JsonConverterTestClassFromJson(json);

  Map<String, dynamic> toJson() => _$JsonConverterTestClassToJson(this);

  Duration duration;
  List<Duration> durationList;

  BigInt bigInt = BigInt.parse('10000000000000000000');
  Map<String, BigInt> bigIntMap;

  TrivialNumber numberSilly;
  Set<TrivialNumber> numberSillySet;

  DateTime dateTime = DateTime(1981, 6, 5);
}

@JsonSerializable(
  nullable: false,
  anyMap: true,
)
@GenericConverter()
class JsonConverterGeneric<S, T, U> {
  S item;
  List<T> itemList;
  Map<String, U> itemMap;

  JsonConverterGeneric();

  factory JsonConverterGeneric.fromJson(Map<String, dynamic> json) =>
      _$JsonConverterGenericFromJson(json);

  Map<String, dynamic> toJson() => _$JsonConverterGenericToJson(this);
}
