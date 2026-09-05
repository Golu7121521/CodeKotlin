import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';

class StorageService {
  static const _projectsKey = 'flutide_projects_v1';

  static Future<Directory> projectsRoot() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/FlutideProjects');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<List<Project>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_projectsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Project.fromJson).toList();
  }

  static Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(projects.map((p) => p.toJson()).toList());
    await prefs.setString(_projectsKey, raw);
  }

  static Future<void> addProject(Project project) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.path == project.path);
    projects.insert(0, project);
    await saveProjects(projects);
  }

  static Future<void> removeProject(Project project) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.path == project.path);
    await saveProjects(projects);
  }
}
