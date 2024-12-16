/// {@template dio.options.FileAccessMode}
/// The file access mode when downloading a file, corresponds to a subset of 
/// dart:io::[FileMode].
/// {@endtemplate}
enum FileAccessMode {
  /// Mode for opening a file for reading and writing. The file is overwritten
  /// if it already exists. The file is created if it does not already exist.
  write,

  /// Mode for opening a file for reading and writing to the end of it.
  /// The file is created if it does not already exist.
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
