/// {@template dio.DioFileMode}
///  The file access mode when downloading the file.
/// - [DioFileMode.write]: Mode for opening a file for reading and writing.
///    The file is overwritten if it already exists. The file is created if it
///    does not already exist
/// - [DioFileMode.append]: Mode for opening a file for reading and writing
///    to the end of it. The file is created if it does not already exist.
/// {@endtemplate}
enum DioFileMode {
  write,
  append;

  T map<T>({
    required T Function() write,
    required T Function() append,
  }) {
    switch (this) {
      case DioFileMode.write:
        return write();
      case DioFileMode.append:
        return append();
    }
  }
}
