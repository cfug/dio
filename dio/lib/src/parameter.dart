import 'package:collection/collection.dart';

import 'options.dart';

/// Indicates a param being used as queries or form data,
/// and how does it gets formatted.
class ListParam<T> {
  const ListParam(this.value, this.format);

  /// The value used in queries or in form data.
  final List<T> value;

  /// How does the value gets formatted.
  final ListFormat format;

  /// Generate a new [ListParam] by copying fields.
  ListParam<T> copyWith({List<T>? value, ListFormat? format}) {
    return ListParam(value ?? this.value, format ?? this.format);
  }

  @override
  String toString() {
    return 'ListParam{value: $value, format: $format}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListParam &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(value, other.value) &&
          format == other.format;

  @override
  int get hashCode => Object.hash(
        const DeepCollectionEquality().hash(value),
        format,
      );
}
