import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'storage_service.dart';
import '../models/project_model.dart';

class ArchiveService {
  /// Exports a project folder to a .zip file placed in the app's temp/export
  /// area and returns its path, ready to be shared or saved by the user.
  static Future<String> exportProject(Project project) async {
    final encoder = ZipFileEncoder();
    final root = await StorageService.projectsRoot();
    final outPath = p.join(root.parent.path, '${project.name}.zip');
    if (File(outPath).existsSync()) File(outPath).deleteSync();
    encoder.create(outPath);
    encoder.addDirectory(Directory(project.path), includeDirName: false);
    encoder.close();
    return outPath;
  }

  /// Imports a .zip file (a Flutter project) into the projects root and
  /// registers it. Returns the created Project.
  static Future<Project> importZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    var name = p.basenameWithoutExtension(zipPath);
    final root = await StorageService.projectsRoot();
    var targetDir = Directory(p.join(root.path, name));
    var suffix = 1;
    while (await targetDir.exists()) {
      targetDir = Directory(p.join(root.path, '${name}_$suffix'));
      suffix++;
    }
    await targetDir.create(recursive: true);

    for (final file in archive) {
      final outPath = p.join(targetDir.path, file.name);
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    final project = Project(name: p.basename(targetDir.path), path: targetDir.path);
    await StorageService.addProject(project);
    return project;
  }
}
