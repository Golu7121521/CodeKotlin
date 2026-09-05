import 'dart:io';
import 'package:path/path.dart' as p;
import 'github_service.dart';
import '../models/project_model.dart';

/// A small, safe command interpreter scoped to the current project folder.
/// It supports the everyday basic commands users expect from a terminal,
/// plus two special commands that drive the GitHub Actions build feature.
class TerminalService {
  final Project project;
  late String cwd;

  TerminalService(this.project) {
    cwd = project.path;
  }

  Future<String> run(String input) async {
    final line = input.trim();
    if (line.isEmpty) return '';
    final parts = _splitArgs(line);
    final cmd = parts.first;
    final args = parts.skip(1).toList();

    try {
      switch (cmd) {
        case 'help':
          return _help();
        case 'pwd':
          return cwd;
        case 'ls':
          return _ls();
        case 'cd':
          return _cd(args);
        case 'mkdir':
          return _mkdir(args);
        case 'touch':
          return _touch(args);
        case 'rm':
          return _rm(args);
        case 'cat':
          return _cat(args);
        case 'clear':
          return '\x1B[CLEAR]';
        case 'echo':
          return args.join(' ');
        case 'push':
        case 'git-push':
          return await _push(args);
        case 'build':
          return await _build(args);
        case 'status':
        case 'build-status':
          return await _status();
        default:
          return 'command not found: $cmd  (type "help")';
      }
    } catch (e) {
      return 'error: $e';
    }
  }

  List<String> _splitArgs(String line) {
    final re = RegExp(r'"([^"]*)"|(\S+)');
    return re.allMatches(line).map((m) => m.group(1) ?? m.group(2) ?? '').toList();
  }

  String _help() => '''
Basic:  ls  cd  pwd  mkdir  touch  rm  cat  echo  clear
Build:  push [commit message]   -> uploads project files to GitHub
        build                  -> triggers GitHub Actions build
        status                 -> checks latest build status / APK link
''';

  String _resolve(String path) =>
      p.isAbsolute(path) ? path : p.normalize(p.join(cwd, path));

  String _ls() {
    final dir = Directory(cwd);
    final entries = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
    if (entries.isEmpty) return '(empty)';
    return entries
        .map((e) => e is Directory ? '${p.basename(e.path)}/' : p.basename(e.path))
        .join('  ');
  }

  String _cd(List<String> args) {
    if (args.isEmpty) {
      cwd = project.path;
      return cwd;
    }
    final target = args[0] == '..' ? p.dirname(cwd) : _resolve(args[0]);
    if (!Directory(target).existsSync()) return 'no such directory: ${args[0]}';
    if (!p.isWithin(project.path, target) && target != project.path) {
      return 'cannot leave project folder';
    }
    cwd = target;
    return cwd;
  }

  String _mkdir(List<String> args) {
    if (args.isEmpty) return 'usage: mkdir <name>';
    Directory(_resolve(args[0])).createSync(recursive: true);
    return 'created ${args[0]}';
  }

  String _touch(List<String> args) {
    if (args.isEmpty) return 'usage: touch <file>';
    final f = File(_resolve(args[0]));
    if (!f.existsSync()) f.createSync(recursive: true);
    return 'created ${args[0]}';
  }

  String _rm(List<String> args) {
    if (args.isEmpty) return 'usage: rm [-r] <path>';
    final recursive = args.contains('-r');
    final target = args.firstWhere((a) => a != '-r');
    final path = _resolve(target);
    if (Directory(path).existsSync()) {
      Directory(path).deleteSync(recursive: recursive);
    } else if (File(path).existsSync()) {
      File(path).deleteSync();
    } else {
      return 'no such file or directory: $target';
    }
    return 'removed $target';
  }

  String _cat(List<String> args) {
    if (args.isEmpty) return 'usage: cat <file>';
    final f = File(_resolve(args[0]));
    if (!f.existsSync()) return 'no such file: ${args[0]}';
    return f.readAsStringSync();
  }

  Future<String> _push(List<String> args) async {
    final token = await GithubService.getToken();
    if (token == null || token.isEmpty) {
      return 'no GitHub token set. Add one from Settings > GitHub first.';
    }
    if (project.githubRepo == null || project.githubRepo!.isEmpty) {
      return 'this project is not linked to a GitHub repo yet. Link it from the project menu.';
    }
    await GithubService.ensureRepo(token, project.githubRepo!.split('/').last);
    final buf = StringBuffer('pushing to ${project.githubRepo} ...\n');
    await GithubService.pushProject(
      token: token,
      ownerRepo: project.githubRepo!,
      projectPath: project.path,
      onFile: (f) => buf.writeln('  + $f'),
    );
    buf.writeln('push complete.');
    return buf.toString();
  }

  Future<String> _build(List<String> args) async {
    final token = await GithubService.getToken();
    if (token == null || token.isEmpty) {
      return 'no GitHub token set. Add one from Settings > GitHub first.';
    }
    if (project.githubRepo == null) {
      return 'this project is not linked to a GitHub repo yet.';
    }
    await GithubService.triggerBuild(token: token, ownerRepo: project.githubRepo!);
    return 'build triggered on GitHub Actions. Use "status" to check progress.';
  }

  Future<String> _status() async {
    final token = await GithubService.getToken();
    if (token == null || project.githubRepo == null) {
      return 'no GitHub link configured yet.';
    }
    final runs = await GithubService.listRuns(
        token: token, ownerRepo: project.githubRepo!);
    if (runs.isEmpty) return 'no build runs found yet.';
    final latest = runs.first;
    final status = latest['status'];
    final conclusion = latest['conclusion'];
    final buf = StringBuffer('latest run: $status ${conclusion ?? ''}\n');
    if (status == 'completed' && conclusion == 'success') {
      final artifacts = await GithubService.listArtifacts(
          token: token, ownerRepo: project.githubRepo!, runId: latest['id']);
      for (final a in artifacts) {
        buf.writeln('APK artifact: ${a['name']} (${a['archive_download_url']})');
      }
    }
    return buf.toString();
  }
}
