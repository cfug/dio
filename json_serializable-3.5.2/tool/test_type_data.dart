import 'package:meta/meta.dart';

import 'shared.dart';

const customEnumType = 'EnumType';

const _annotationImport =
    "import 'package:json_annotation/json_annotation.dart';";

class TestTypeData {
  final String defaultExpression;
  final String jsonExpression;
  final String altJsonExpression;
  final Set<String> genericArgs;

  const TestTypeData({
    this.defaultExpression,
    String jsonExpression,
    @required String altJsonExpression,
    this.genericArgs = const {},
  })  : jsonExpression = jsonExpression ?? defaultExpression,
        altJsonExpression =
            altJsonExpression ?? jsonExpression ?? defaultExpression;

  String libContent(String source, String type) {
    const classAnnotationSplit = '@JsonSerializable()';

    final split = source.split(classAnnotationSplit);

    assert(split.length == 2);

    final newPart = toTypeExtension(type, includeDotDart: false);

    final headerReplacements = [
      if (type == customEnumType ||
          genericArgs.any((element) => element.contains(customEnumType)))
        const Replacement(
          _annotationImport,
          '$_annotationImport'
          "import 'enum_type.dart';",
        ),
      Replacement(
        "part 'input.g.dart';",
        "part 'input$newPart.g.dart';",
      )
    ];

    final buffer =
        StringBuffer(Replacement.generate(split[0], headerReplacements));

    final simpleClassContent = '$classAnnotationSplit${split[1]}';

    buffer.write(Replacement.generate(
      simpleClassContent,
      _libReplacements(type),
    ));

    for (var genericArg in genericArgs) {
      final genericArgClassPart = _genericClassPart(genericArg);

      final genericType = '$type<$genericArg>';

      buffer.write(Replacement.generate(
        simpleClassContent.replaceAll(
          'SimpleClass',
          'SimpleClass$genericArgClassPart',
        ),
        _libReplacements(genericType),
      ));
    }

    return buffer.toString();
  }

  Iterable<Replacement> _libReplacements(String type) sync* {
    yield Replacement(
      'final dynamic value;',
      'final $type value;',
    );
    yield Replacement(
      'final dynamic nullable;',
      'final $type nullable;',
    );

    final defaultReplacement = (defaultExpression == null // no default provided
            ||
            type.contains('<') // no support for default values and generic args
        )
        ? ''
        : _defaultSource
            .replaceFirst('42', defaultExpression)
            .replaceFirst('dynamic', type);

    yield Replacement(
      _defaultSource,
      defaultReplacement,
    );
  }

  String testContent(String sourceContent, String type) => Replacement.generate(
        sourceContent,
        _testReplacements(type),
      );

  Iterable<Replacement> _testReplacements(String type) sync* {
    yield Replacement(
      "import 'input.dart';",
      "import 'input.type_${typeToPathPart(type)}.dart';",
    );

    yield Replacement(
      '''
final _defaultValue = 42;
final _altValue = 43;
''',
      '''
final _defaultValue = $jsonExpression;
final _altValue = $altJsonExpression;
''',
    );

    if (defaultExpression == null) {
      yield const Replacement(
        "  'withDefault': _defaultValue,\n",
        '',
      );
      yield const Replacement(
        "  'withDefault': _altValue,\n",
        '',
      );
    }
  }

  static const _defaultSource = r'''
  @JsonKey(defaultValue: 42)
  dynamic withDefault;

''';
}

String _genericClassPart(String genericArg) => genericArg
    .split(',')
    .map((e) => [
          e.substring(0, 1).toUpperCase(),
          e.substring(1),
        ].join())
    .join('To');

String toTypeExtension(String e, {bool includeDotDart = true}) =>
    '.type_${typeToPathPart(e)}${includeDotDart ? '.dart' : ''}';

String typeToPathPart(String type) => type.toLowerCase();
