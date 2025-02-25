## Unreleased

*None.*

## 1.1.1

- Move all source Dart files to `*_impl.dart` to avoid naming collision.
  This is a workaround of https://github.com/dart-lang/sdk/issues/56498.

## 1.1.0

- Support `FileAccessMode` in `Dio.download` and `Dio.downloadUri` to change download file opening mode.

## 1.0.1

- Improves warning logs on the Web platform.

## 1.0.0

- Split the Web ability from the `package:dio`.
