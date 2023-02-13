import 'package:dio/dio.dart';

class ListParam<T> {
  final ListFormat format;
  List<T> value;

  ListParam(this.value, this.format);

  @override
  String toString() {
    return 'ListParam{format: $format, value: $value}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListParam &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          value == other.value;

  @override
  int get hashCode => format.hashCode ^ value.hashCode;
}
