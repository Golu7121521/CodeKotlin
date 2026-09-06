/// Status of a download/history entry.
enum DownloadStatus {
  preparing,
  connecting,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

DownloadStatus downloadStatusFromString(String value) {
  return DownloadStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => DownloadStatus.failed,
  );
}

/// Represents a single downloaded / in-progress / historical video item.
class DownloadItem {
  final String id;
  final String url;
  final String downloadUrl;
  String filename;
  String? localPath;
  String? thumbnailPath;
  int? fileSizeBytes;
  int? downloadedBytes;
  int? durationMs;
  String? title;
  DownloadStatus status;
  final DateTime createdAt;
  DateTime? completedAt;

  DownloadItem({
    required this.id,
    required this.url,
    required this.downloadUrl,
    required this.filename,
    this.localPath,
    this.thumbnailPath,
    this.fileSizeBytes,
    this.downloadedBytes,
    this.durationMs,
    this.title,
    this.status = DownloadStatus.preparing,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (fileSizeBytes == null || fileSizeBytes == 0) return 0.0;
    final downloaded = downloadedBytes ?? 0;
    final p = downloaded / fileSizeBytes!;
    if (p.isNaN || p.isInfinite) return 0.0;
    return p.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'downloadUrl': downloadUrl,
      'filename': filename,
      'localPath': localPath,
      'thumbnailPath': thumbnailPath,
      'fileSizeBytes': fileSizeBytes,
      'downloadedBytes': downloadedBytes,
      'durationMs': durationMs,
      'title': title,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'] as String,
      url: map['url'] as String,
      downloadUrl: map['downloadUrl'] as String? ?? '',
      filename: map['filename'] as String,
      localPath: map['localPath'] as String?,
      thumbnailPath: map['thumbnailPath'] as String?,
      fileSizeBytes: map['fileSizeBytes'] as int?,
      downloadedBytes: map['downloadedBytes'] as int?,
      durationMs: map['durationMs'] as int?,
      title: map['title'] as String?,
      status: downloadStatusFromString(map['status'] as String? ?? 'failed'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
    );
  }

  DownloadItem copyWith({
    String? filename,
    String? localPath,
    String? thumbnailPath,
    int? fileSizeBytes,
    int? downloadedBytes,
    int? durationMs,
    String? title,
    DownloadStatus? status,
    DateTime? completedAt,
  }) {
    return DownloadItem(
      id: id,
      url: url,
      downloadUrl: downloadUrl,
      filename: filename ?? this.filename,
      localPath: localPath ?? this.localPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      durationMs: durationMs ?? this.durationMs,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
