part of '_json_serializable_test_input.dart';

@ShouldGenerate(r'''
MapKeyVariety _$MapKeyVarietyFromJson(Map<String, dynamic> json) {
  return MapKeyVariety()
    ..intIntMap = (json['intIntMap'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e as int),
    );
}

Map<String, dynamic> _$MapKeyVarietyToJson(MapKeyVariety instance) =>
    <String, dynamic>{
      'intIntMap': instance.intIntMap?.map((k, e) => MapEntry(k.toString(), e)),
    };
''')
@JsonSerializable()
class MapKeyVariety {
  Map<int, int> intIntMap;
}
