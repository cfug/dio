part of '_json_serializable_test_input.dart';

@ShouldGenerate(
  r'''
JustSetter _$JustSetterFromJson(Map<String, dynamic> json) {
  return JustSetter();
}

Map<String, dynamic> _$JustSetterToJson(JustSetter instance) =>
    <String, dynamic>{};
''',
  expectedLogItems: ['Setters are ignored: JustSetter.someSetter'],
  configurations: ['default'],
)
@JsonSerializable()
class JustSetter {
  set someSetter(Object name) {}
}

@ShouldGenerate(
  r'''
JustSetterNoToJson _$JustSetterNoToJsonFromJson(Map<String, dynamic> json) {
  return JustSetterNoToJson();
}
''',
  expectedLogItems: ['Setters are ignored: JustSetterNoToJson.someSetter'],
  configurations: ['default'],
)
@JsonSerializable(createToJson: false)
class JustSetterNoToJson {
  set someSetter(Object name) {}
}

@ShouldGenerate(
  r'''
Map<String, dynamic> _$JustSetterNoFromJsonToJson(
        JustSetterNoFromJson instance) =>
    <String, dynamic>{};
''',
  expectedLogItems: ['Setters are ignored: JustSetterNoFromJson.someSetter'],
  configurations: ['default'],
)
@JsonSerializable(createFactory: false)
class JustSetterNoFromJson {
  set someSetter(Object name) {}
}
