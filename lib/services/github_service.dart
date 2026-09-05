import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to the GitHub REST API so a project can be pushed and built via
/// GitHub Actions without needing a native `git` binary on the device.
class GithubService {
  static const _tokenKey = 'flutide_gh_token';
  static const _api = 'https://api.github.com';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  /// Creates the repo if it doesn't exist yet.
  static Future<void> ensureRepo(String token, String repoName) async {
    final res = await http.post(
      Uri.parse('$_api/user/repos'),
      headers: _headers(token),
      body: jsonEncode({'name': repoName, 'auto_init': true, 'private': false}),
    );
    if (res.statusCode != 201 && res.statusCode != 422) {
      throw Exception('Repo create failed: ${res.statusCode} ${res.body}');
    }
  }

  /// Uploads every file under [projectPath] to `owner/repo` using the
  /// Contents API (create-or-update), one call per file. Simple and
  /// reliable for project-sized codebases without shelling out to git.
  static Future<void> pushProject({
    required String token,
    required String ownerRepo, // "owner/repo"
    required String projectPath,
    void Function(String path)? onFile,
  }) async {
    final dir = Directory(projectPath);
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => !p.split(f.path).any((seg) => seg == '.git' || seg == 'build'));

    for (final file in files) {
      final rel = p.relative(file.path, from: projectPath).replaceAll('\\', '/');
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);

      String? sha;
      final getRes = await http.get(
        Uri.parse('$_api/repos/$ownerRepo/contents/$rel'),
        headers: _headers(token),
      );
      if (getRes.statusCode == 200) {
        sha = jsonDecode(getRes.body)['sha'];
      }

      final putRes = await http.put(
        Uri.parse('$_api/repos/$ownerRepo/contents/$rel'),
        headers: _headers(token),
        body: jsonEncode({
          'message': 'Update $rel via FlutIDE',
          'content': b64,
          if (sha != null) 'sha': sha,
        }),
      );
      if (putRes.statusCode != 200 && putRes.statusCode != 201) {
        throw Exception('Push failed for $rel: ${putRes.statusCode} ${putRes.body}');
      }
      onFile?.call(rel);
    }
  }

  /// Triggers the `flutter_build.yml` workflow via workflow_dispatch.
  static Future<void> triggerBuild({
    required String token,
    required String ownerRepo,
    String workflowFile = 'flutter_build.yml',
    String ref = 'main',
  }) async {
    final res = await http.post(
      Uri.parse('$_api/repos/$ownerRepo/actions/workflows/$workflowFile/dispatches'),
      headers: _headers(token),
      body: jsonEncode({'ref': ref}),
    );
    if (res.statusCode != 204) {
      throw Exception('Trigger failed: ${res.statusCode} ${res.body}');
    }
  }

  /// Returns the most recent workflow runs (status/conclusion) for polling.
  static Future<List<Map<String, dynamic>>> listRuns({
    required String token,
    required String ownerRepo,
  }) async {
    final res = await http.get(
      Uri.parse('$_api/repos/$ownerRepo/actions/runs?per_page=5'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('List runs failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    return (data['workflow_runs'] as List).cast<Map<String, dynamic>>();
  }

  /// Lists artifacts for a run (e.g. the built APK).
  static Future<List<Map<String, dynamic>>> listArtifacts({
    required String token,
    required String ownerRepo,
    required int runId,
  }) async {
    final res = await http.get(
      Uri.parse('$_api/repos/$ownerRepo/actions/runs/$runId/artifacts'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('List artifacts failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    return (data['artifacts'] as List).cast<Map<String, dynamic>>();
  }
}
