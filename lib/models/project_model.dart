class Project {
  final String name;
  final String path; // absolute path on device
  String? githubRepo; // "owner/repo" once linked
  DateTime lastOpened;

  Project({
    required this.name,
    required this.path,
    this.githubRepo,
    DateTime? lastOpened,
  }) : lastOpened = lastOpened ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'githubRepo': githubRepo,
        'lastOpened': lastOpened.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        name: json['name'],
        path: json['path'],
        githubRepo: json['githubRepo'],
        lastOpened: DateTime.tryParse(json['lastOpened'] ?? '') ?? DateTime.now(),
      );
}
