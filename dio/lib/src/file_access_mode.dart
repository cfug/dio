/// {@template dio.FileAccessMode}
///  The file access mode when downloading the file.
/// - [FileAccessMode.write]: Mode for opening a file for reading and writing.
///    The file is overwritten if it already exists. The file is created if it
///    does not already exist
/// - [FileAccessMode.append]: Mode for opening a file for reading and writing
///    to the end of it. The file is created if it does not already exist.
/// {@endtemplate}
enum FileAccessMode {
  write,
  append,
}

extension FileAccessModeExtension on FileAccessMode {
  T map<T>({
    required T Function() write,
    required T Function() append,
  }) {
    switch (this) {
      case FileAccessMode.write:
        return write();
      case FileAccessMode.append:
        return append();
    }
  }
}
