enum DownloadStatus { queued, downloading, paused, downloaded, failed, expired }

/// Represents a single offline download entry, tracked across the
/// Queued -> Downloading -> (Paused) -> Downloaded -> (Expired) state
/// machine described in the download-manager spec.
class DownloadItem {
  final int movieId;
  final String title;
  final String? posterUrl;
  final String sourceUrl;
  String localPath;
  DownloadStatus status;
  int downloadedBytes;
  int? totalBytes;
  String? pauseReason; // e.g. "Low battery", "No Wi-Fi"
  final DateTime createdAt;
  DateTime? completedAt;

  DownloadItem({
    required this.movieId,
    required this.title,
    this.posterUrl,
    required this.sourceUrl,
    this.localPath = '',
    this.status = DownloadStatus.queued,
    this.downloadedBytes = 0,
    this.totalBytes,
    this.pauseReason,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (totalBytes == null || totalBytes == 0) return 0.0;
    final f = downloadedBytes / totalBytes!;
    return f.isFinite ? f.clamp(0.0, 1.0) : 0.0;
  }

  Map<String, dynamic> toJson() => {
        'movieId': movieId,
        'title': title,
        'posterUrl': posterUrl,
        'sourceUrl': sourceUrl,
        'localPath': localPath,
        'status': status.name,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'pauseReason': pauseReason,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      movieId: json['movieId'] as int,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String? ?? '',
      localPath: json['localPath'] as String? ?? '',
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.failed,
      ),
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int?,
      pauseReason: json['pauseReason'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
    );
  }
}
