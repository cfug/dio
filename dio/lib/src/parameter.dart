import 'package:dio/dio.dart';

class Param<T> {
  final T value;

  Param(this.value);
}

class MultiParam<T> extends Param<List<T>> {
  final ListFormat format;

  MultiParam(List<T> value, this.format) : super(value);
}
