import 'dart:io';

void main() {
  final v = RegExp(r'(\d*\.\d*)\.\d*').firstMatch(Platform.version)!.group(1)!;
  final patches = patchesForVersions[v];
  if (patches != null && patches.isNotEmpty) {
    print('Found file patches for Dart $v.');
    for (final patch in patches) {
      print('Applying patch for ${patch.path}');
      final before = File(patch.path).readAsStringSync();
      final after = before.replaceAll(patch.before, patch.after);
      File(patch.path).writeAsStringSync(after);
    }
  }
}

class Patch {
  const Patch(this.path, this.before, this.after);

  final String path;
  final String before;
  final String after;
}

final patchesForVersions = <String, List<Patch>>{
  '2.15': [
    Patch(
      'dio/lib/src/adapters/io_adapter.dart',
      '    this.onHttpClientCreate',
      '        this.onHttpClientCreate',
    ),
  ],
};
