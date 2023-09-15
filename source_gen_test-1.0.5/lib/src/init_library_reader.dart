import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

const testPackageName = '__test__';

/// Returns a [LibraryReader] for library specified by [targetLibraryFileName]
/// using the files in [sourceDirectory].
Future<LibraryReader> initializeLibraryReaderForDirectory(
  String sourceDirectory,
  String targetLibraryFileName,
) async {
  final map = Map.fromEntries(
    Directory(sourceDirectory)
        .listSync()
        .whereType<File>()
        .map((f) => MapEntry(p.basename(f.path), f.readAsStringSync())),
  );

  try {
    return await initializeLibraryReader(map, targetLibraryFileName);
  } on ArgumentError catch (e) // ignore: avoid_catching_errors
  {
    if (e.message == 'Must exist as a key in `contentMap`.') {
      throw ArgumentError.value(
        targetLibraryFileName,
        'targetLibraryFileName',
        'Must exist as a file in `sourceDirectory`.',
      );
    }
    rethrow;
  }
}

/// Returns a [LibraryReader] for library specified by [targetLibraryFileName]
/// using the file contents described by [contentMap].
///
/// [contentMap] contains the Dart file contents to from which to create the
/// library stored as filename / file content pairs.
Future<LibraryReader> initializeLibraryReader(
  Map<String, String> contentMap,
  String targetLibraryFileName,
) async {
  if (!contentMap.containsKey(targetLibraryFileName)) {
    throw ArgumentError.value(
      targetLibraryFileName,
      'targetLibraryFileName',
      'Must exist as a key in `contentMap`.',
    );
  }

  String assetIdForFile(String fileName) => '$testPackageName|lib/$fileName';

  final targetLibraryAssetId = assetIdForFile(targetLibraryFileName);

  final assetMap = contentMap
      .map((file, content) => MapEntry(assetIdForFile(file), content));

  final library = await resolveSources(
    assetMap,
    (item) async {
      final assetId = AssetId.parse(targetLibraryAssetId);
      return item.libraryFor(assetId);
    },
    resolverFor: targetLibraryAssetId,
  );

  return LibraryReader(library);
}
