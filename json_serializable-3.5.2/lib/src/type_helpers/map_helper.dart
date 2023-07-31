// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

import '../constants.dart';
import '../shared_checkers.dart';
import '../type_helper.dart';
import '../unsupported_type_error.dart';
import '../utils.dart';
import 'to_from_string.dart';

const _keyParam = 'k';

class MapHelper extends TypeHelper<TypeHelperContextWithConfig> {
  const MapHelper();

  @override
  String serialize(
    DartType targetType,
    String expression,
    TypeHelperContextWithConfig context,
  ) {
    if (!coreMapTypeChecker.isAssignableFromType(targetType)) {
      return null;
    }
    final args = typeArgumentsOf(targetType, coreMapTypeChecker);
    assert(args.length == 2);

    final keyType = args[0];
    final valueType = args[1];

    _checkSafeKeyType(expression, keyType);

    final subFieldValue = context.serialize(valueType, closureArg);
    final subKeyValue =
        _forType(keyType)?.serialize(keyType, _keyParam, false) ??
            context.serialize(keyType, _keyParam);

    if (closureArg == subFieldValue && _keyParam == subKeyValue) {
      return expression;
    }

    final optionalQuestion = context.nullable ? '?' : '';

    return '$expression$optionalQuestion'
        '.map(($_keyParam, $closureArg) => '
        'MapEntry($subKeyValue, $subFieldValue))';
  }

  @override
  String deserialize(
    DartType targetType,
    String expression,
    TypeHelperContextWithConfig context,
  ) {
    if (!coreMapTypeChecker.isExactlyType(targetType)) {
      return null;
    }

    final typeArgs = typeArgumentsOf(targetType, coreMapTypeChecker);
    assert(typeArgs.length == 2);
    final keyArg = typeArgs.first;
    final valueArg = typeArgs.last;

    _checkSafeKeyType(expression, keyArg);

    final valueArgIsAny = isObjectOrDynamic(valueArg);
    final isKeyStringable = _isKeyStringable(keyArg);

    if (!isKeyStringable) {
      if (valueArgIsAny) {
        if (context.config.anyMap) {
          if (isObjectOrDynamic(keyArg)) {
            return '$expression as Map';
          }
        } else {
          // this is the trivial case. Do a runtime cast to the known type of
          // JSON map values - `Map<String, dynamic>`
          return '$expression as Map<String, dynamic>';
        }
      }

      if (!context.nullable &&
          (valueArgIsAny ||
              simpleJsonTypeChecker.isAssignableFromType(valueArg))) {
        // No mapping of the values or null check required!
        final valueString = valueArg.getDisplayString(withNullability: false);
        return 'Map<String, $valueString>.from($expression as Map)';
      }
    }

    // In this case, we're going to create a new Map with matching reified
    // types.

    final itemSubVal = context.deserialize(valueArg, closureArg);

    final optionalQuestion = context.nullable ? '?' : '';

    final mapCast =
        context.config.anyMap ? 'as Map' : 'as Map<String, dynamic>';

    String keyUsage;
    if (isEnum(keyArg)) {
      keyUsage = context.deserialize(keyArg, _keyParam).toString();
    } else if (context.config.anyMap && !isObjectOrDynamic(keyArg)) {
      keyUsage = '$_keyParam as String';
    } else {
      keyUsage = _keyParam;
    }

    final toFromString = _forType(keyArg);
    if (toFromString != null) {
      keyUsage = toFromString.deserialize(keyArg, keyUsage, false, true);
    }

    return '($expression $mapCast)$optionalQuestion.map( '
        '($_keyParam, $closureArg) => MapEntry($keyUsage, $itemSubVal),)';
  }
}

final _intString = ToFromStringHelper('int.parse', 'toString()', 'int');

/// [ToFromStringHelper] instances representing non-String types that can
/// be used as [Map] keys.
final _instances = [
  bigIntString,
  dateTimeString,
  _intString,
  uriString,
];

ToFromStringHelper _forType(DartType type) =>
    _instances.singleWhere((i) => i.matches(type), orElse: () => null);

/// Returns `true` if [keyType] can be automatically converted to/from String –
/// and is therefor usable as a key in a [Map].
bool _isKeyStringable(DartType keyType) =>
    isEnum(keyType) || _instances.any((inst) => inst.matches(keyType));

void _checkSafeKeyType(String expression, DartType keyArg) {
  // We're not going to handle converting key types at the moment
  // So the only safe types for key are dynamic/Object/String/enum
  if (isObjectOrDynamic(keyArg) ||
      coreStringTypeChecker.isExactlyType(keyArg) ||
      _isKeyStringable(keyArg)) {
    return;
  }

  throw UnsupportedTypeError(
    keyArg,
    expression,
    'Map keys must be one of: ${_allowedTypeNames.join(', ')}.',
  );
}

/// The names of types that can be used as [Map] keys.
///
/// Used in [_checkSafeKeyType] to provide a helpful error with unsupported
/// types.
Iterable<String> get _allowedTypeNames => const [
      'Object',
      'dynamic',
      'enum',
      'String',
    ].followedBy(_instances.map((i) => i.coreTypeName));
