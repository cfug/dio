// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_sink.g_exclude_null.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KitchenSink _$KitchenSinkFromJson(Map<String, dynamic> json) {
  return KitchenSink(
    ctorValidatedNo42: json['no-42'] as int,
    iterable: json['iterable'] as List,
    dynamicIterable: json['dynamicIterable'] as List,
    objectIterable: json['objectIterable'] as List,
    intIterable: (json['intIterable'] as List)?.map((e) => e as int),
    dateTimeIterable: (json['datetime-iterable'] as List)
        ?.map((e) => e == null ? null : DateTime.parse(e as String)),
  )
    ..dateTime = json['dateTime'] == null
        ? null
        : DateTime.parse(json['dateTime'] as String)
    ..bigInt =
        json['bigInt'] == null ? null : BigInt.parse(json['bigInt'] as String)
    ..set = (json['set'] as List)?.toSet()
    ..dynamicSet = (json['dynamicSet'] as List)?.toSet()
    ..objectSet = (json['objectSet'] as List)?.toSet()
    ..intSet = (json['intSet'] as List)?.map((e) => e as int)?.toSet()
    ..dateTimeSet = (json['dateTimeSet'] as List)
        ?.map((e) => e == null ? null : DateTime.parse(e as String))
        ?.toSet()
    ..list = json['list'] as List
    ..dynamicList = json['dynamicList'] as List
    ..objectList = json['objectList'] as List
    ..intList = (json['intList'] as List)?.map((e) => e as int)?.toList()
    ..dateTimeList = (json['dateTimeList'] as List)
        ?.map((e) => e == null ? null : DateTime.parse(e as String))
        ?.toList()
    ..map = json['map'] as Map<String, dynamic>
    ..stringStringMap = (json['stringStringMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    )
    ..dynamicIntMap = (json['dynamicIntMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as int),
    )
    ..objectDateTimeMap =
        (json['objectDateTimeMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : DateTime.parse(e as String)),
    )
    ..crazyComplex = (json['crazyComplex'] as List)
        ?.map((e) => (e as Map<String, dynamic>)?.map(
              (k, e) => MapEntry(
                  k,
                  (e as Map<String, dynamic>)?.map(
                    (k, e) => MapEntry(
                        k,
                        (e as List)
                            ?.map((e) => (e as List)
                                ?.map((e) => e == null
                                    ? null
                                    : DateTime.parse(e as String))
                                ?.toList())
                            ?.toList()),
                  )),
            ))
        ?.toList()
    ..val = (json['val'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as bool),
    )
    ..writeNotNull = json['writeNotNull'] as bool
    ..string = json[r'$string'] as String
    ..simpleObject = json['simpleObject'] == null
        ? null
        : SimpleObject.fromJson(json['simpleObject'] as Map<String, dynamic>)
    ..strictKeysObject = json['strictKeysObject'] == null
        ? null
        : StrictKeysObject.fromJson(
            json['strictKeysObject'] as Map<String, dynamic>)
    ..validatedPropertyNo42 = json['validatedPropertyNo42'] as int;
}

Map<String, dynamic> _$KitchenSinkToJson(KitchenSink instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('no-42', instance.ctorValidatedNo42);
  writeNotNull('dateTime', instance.dateTime?.toIso8601String());
  writeNotNull('bigInt', instance.bigInt?.toString());
  writeNotNull('iterable', instance.iterable?.toList());
  writeNotNull('dynamicIterable', instance.dynamicIterable?.toList());
  writeNotNull('objectIterable', instance.objectIterable?.toList());
  writeNotNull('intIterable', instance.intIterable?.toList());
  writeNotNull('set', instance.set?.toList());
  writeNotNull('dynamicSet', instance.dynamicSet?.toList());
  writeNotNull('objectSet', instance.objectSet?.toList());
  writeNotNull('intSet', instance.intSet?.toList());
  writeNotNull('dateTimeSet',
      instance.dateTimeSet?.map((e) => e?.toIso8601String())?.toList());
  writeNotNull('datetime-iterable',
      instance.dateTimeIterable?.map((e) => e?.toIso8601String())?.toList());
  writeNotNull('list', instance.list);
  writeNotNull('dynamicList', instance.dynamicList);
  writeNotNull('objectList', instance.objectList);
  writeNotNull('intList', instance.intList);
  writeNotNull('dateTimeList',
      instance.dateTimeList?.map((e) => e?.toIso8601String())?.toList());
  writeNotNull('map', instance.map);
  writeNotNull('stringStringMap', instance.stringStringMap);
  writeNotNull('dynamicIntMap', instance.dynamicIntMap);
  writeNotNull(
      'objectDateTimeMap',
      instance.objectDateTimeMap
          ?.map((k, e) => MapEntry(k, e?.toIso8601String())));
  writeNotNull(
      'crazyComplex',
      instance.crazyComplex
          ?.map((e) => e?.map((k, e) => MapEntry(
              k,
              e?.map((k, e) => MapEntry(
                  k,
                  e
                      ?.map(
                          (e) => e?.map((e) => e?.toIso8601String())?.toList())
                      ?.toList())))))
          ?.toList());
  writeNotNull('val', instance.val);
  writeNotNull('writeNotNull', instance.writeNotNull);
  writeNotNull(r'$string', instance.string);
  writeNotNull('simpleObject', instance.simpleObject);
  writeNotNull('strictKeysObject', instance.strictKeysObject);
  writeNotNull('validatedPropertyNo42', instance.validatedPropertyNo42);
  return val;
}

JsonConverterTestClass _$JsonConverterTestClassFromJson(
    Map<String, dynamic> json) {
  return JsonConverterTestClass()
    ..duration = durationConverter.fromJson(json['duration'] as int)
    ..durationList = (json['durationList'] as List)
        ?.map((e) => durationConverter.fromJson(e as int))
        ?.toList()
    ..bigInt = const BigIntStringConverter().fromJson(json['bigInt'] as String)
    ..bigIntMap = (json['bigIntMap'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(k, const BigIntStringConverter().fromJson(e as String)),
    )
    ..numberSilly =
        TrivialNumberConverter.instance.fromJson(json['numberSilly'] as int)
    ..numberSillySet = (json['numberSillySet'] as List)
        ?.map((e) => TrivialNumberConverter.instance.fromJson(e as int))
        ?.toSet()
    ..dateTime =
        const EpochDateTimeConverter().fromJson(json['dateTime'] as int);
}

Map<String, dynamic> _$JsonConverterTestClassToJson(
    JsonConverterTestClass instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('duration', durationConverter.toJson(instance.duration));
  writeNotNull('durationList',
      instance.durationList?.map(durationConverter.toJson)?.toList());
  writeNotNull('bigInt', const BigIntStringConverter().toJson(instance.bigInt));
  writeNotNull(
      'bigIntMap',
      instance.bigIntMap?.map(
          (k, e) => MapEntry(k, const BigIntStringConverter().toJson(e))));
  writeNotNull('numberSilly',
      TrivialNumberConverter.instance.toJson(instance.numberSilly));
  writeNotNull(
      'numberSillySet',
      instance.numberSillySet
          ?.map(TrivialNumberConverter.instance.toJson)
          ?.toList());
  writeNotNull(
      'dateTime', const EpochDateTimeConverter().toJson(instance.dateTime));
  return val;
}

JsonConverterGeneric<S, T, U> _$JsonConverterGenericFromJson<S, T, U>(
    Map<String, dynamic> json) {
  return JsonConverterGeneric<S, T, U>()
    ..item =
        GenericConverter<S>().fromJson(json['item'] as Map<String, dynamic>)
    ..itemList = (json['itemList'] as List)
        ?.map((e) => GenericConverter<T>().fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..itemMap = (json['itemMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k, GenericConverter<U>().fromJson(e as Map<String, dynamic>)),
    );
}

Map<String, dynamic> _$JsonConverterGenericToJson<S, T, U>(
    JsonConverterGeneric<S, T, U> instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('item', GenericConverter<S>().toJson(instance.item));
  writeNotNull('itemList',
      instance.itemList?.map(GenericConverter<T>().toJson)?.toList());
  writeNotNull(
      'itemMap',
      instance.itemMap
          ?.map((k, e) => MapEntry(k, GenericConverter<U>().toJson(e))));
  return val;
}
