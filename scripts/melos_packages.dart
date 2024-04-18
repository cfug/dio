import 'dart:io';

import 'package:cli_util/cli_logging.dart' show Logger;
import 'package:melos/melos.dart'
    show MelosLogger, MelosWorkspace, MelosWorkspaceConfig;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Writes a `.melos_packages` file to the root of the workspace with the
/// packages that are compatible with the current Dart SDK version.
///
/// Additionally creates a `.melos_package` file in each package directory
/// which is compatible with the current Dart SDK version. This is required
/// until the minimum Dart SDK can be updated to a version that allows
/// to run at least melos 4.1.0 - this seems to be Dart 3.0.0.
///
/// This is useful for CI scripts that need to know which packages to run
/// melos for using the `MELOS_PACKAGES` environment variable.
void main() async {
  final root =
      Platform.environment['MELOS_ROOT_PATH'] ?? Directory.current.path;
  final config = MelosWorkspaceConfig.fromYaml(
    loadYamlNode(
      File('$root/melos.yaml').readAsStringSync(),
    ).toPlainObject() as Map,
    path: root,
  );
  final workspace = await MelosWorkspace.fromConfig(
    config,
    logger: MelosLogger(Logger.standard()),
  );
  final packages = workspace.filteredPackages.values;

  // Delete old melos marker files
  for (final package in packages) {
    final marker = File(p.join(package.path, '.melos_package'));
    if (marker.existsSync()) {
      marker.deleteSync();
    }
  }

  final current = Version.parse(
    RegExp(r'\d*\.\d*\.\d*').firstMatch(Platform.version)!.group(0)!,
  );
  final validPackages = packages
      .where((e) => e.pubSpec.environment!.sdkConstraint!.allows(current));

  // Create melos marker files
  for (final package in validPackages) {
    File(p.join(package.path, '.melos_package')).createSync();
  }

  final validPackagesString = validPackages.map((p) => p.name).join(',');
  File('$root/.melos_packages')
      .writeAsStringSync('MELOS_PACKAGES=$validPackagesString');
}

extension YamlUtils on YamlNode {
  /// Converts a YAML node to a regular mutable Dart object.
  Object? toPlainObject() {
    final node = this;
    if (node is YamlScalar) {
      return node.value;
    }
    if (node is YamlMap) {
      return {
        for (final entry in node.nodes.entries)
          (entry.key as YamlNode).toPlainObject(): entry.value.toPlainObject(),
      };
    }
    if (node is YamlList) {
      return node.nodes.map((node) => node.toPlainObject()).toList();
    }
    throw FormatException(
      'Unsupported YAML node type encountered: ${node.runtimeType}',
      this,
    );
  }
}
