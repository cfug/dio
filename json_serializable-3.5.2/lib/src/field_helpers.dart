// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart' // ignore: implementation_imports
    show
        InheritanceManager3;
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

class _FieldSet implements Comparable<_FieldSet> {
  final FieldElement field;
  final FieldElement sortField;

  _FieldSet._(this.field, this.sortField)
      : assert(field.name == sortField.name);

  factory _FieldSet(FieldElement classField, FieldElement superField) {
    // At least one of these will != null, perhaps both.
    final fields = [classField, superField].where((fe) => fe != null).toList();

    // Prefer the class field over the inherited field when sorting.
    final sortField = fields.first;

    // Prefer the field that's annotated with `JsonKey`, if any.
    // If not, use the class field.
    final fieldHasJsonKey =
        fields.firstWhere(hasJsonKeyAnnotation, orElse: () => fields.first);

    return _FieldSet._(fieldHasJsonKey, sortField);
  }

  @override
  int compareTo(_FieldSet other) => _sortByLocation(sortField, other.sortField);

  static int _sortByLocation(FieldElement a, FieldElement b) {
    final checkerA =
        TypeChecker.fromStatic((a.enclosingElement as ClassElement).thisType);

    if (!checkerA.isExactly(b.enclosingElement)) {
      // in this case, you want to prioritize the enclosingElement that is more
      // "super".

      if (checkerA.isAssignableFrom(b.enclosingElement)) {
        return -1;
      }

      final checkerB =
          TypeChecker.fromStatic((b.enclosingElement as ClassElement).thisType);

      if (checkerB.isAssignableFrom(a.enclosingElement)) {
        return 1;
      }
    }

    /// Returns the offset of given field/property in its source file – with a
    /// preference for the getter if it's defined.
    int _offsetFor(FieldElement e) {
      if (e.getter != null && e.getter.nameOffset != e.nameOffset) {
        assert(e.nameOffset == -1);
        return e.getter.nameOffset;
      }
      return e.nameOffset;
    }

    return _offsetFor(a).compareTo(_offsetFor(b));
  }
}

/// Returns a [Set] of all instance [FieldElement] items for [element] and
/// super classes, sorted first by their location in the inheritance hierarchy
/// (super first) and then by their location in the source file.
Iterable<FieldElement> createSortedFieldSet(ClassElement element) {
  // Get all of the fields that need to be assigned
  // TODO: support overriding the field set with an annotation option
  final elementInstanceFields = Map.fromEntries(
      element.fields.where((e) => !e.isStatic).map((e) => MapEntry(e.name, e)));

  final inheritedFields = <String, FieldElement>{};
  final manager = InheritanceManager3();

  // ignore: deprecated_member_use
  for (final v in manager.getInheritedConcreteMap(element.thisType).values) {
    assert(v is! FieldElement);
    if (_dartCoreObjectChecker.isExactly(v.enclosingElement)) {
      continue;
    }

    if (v is PropertyAccessorElement && v.isGetter) {
      assert(v.variable is FieldElement);
      final variable = v.variable as FieldElement;
      assert(!inheritedFields.containsKey(variable.name));
      inheritedFields[variable.name] = variable;
    }
  }

  // Get the list of all fields for `element`
  final allFields =
      elementInstanceFields.keys.toSet().union(inheritedFields.keys.toSet());

  final fields = allFields
      .map((e) => _FieldSet(elementInstanceFields[e], inheritedFields[e]))
      .toList()
        ..sort();

  return fields.map((fs) => fs.field).toList();
}

const _dartCoreObjectChecker = TypeChecker.fromRuntime(Object);
