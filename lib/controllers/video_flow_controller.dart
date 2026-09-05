import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/api_response.dart';
import '../models/download_item.dart';
import '../providers/downloads_provider.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../utils/filename_sanitizer.dart';
import '../utils/url_validator.dart';

enum FlowState {
  idle,
  validating,
  callingApi,
  fetchingPreview,
  previewReady,
  error,
}

/// Orchestrates the full URL -> API -> temp preview -> mini preview ->
/// (optional) permanent download flow described in the app spec.
///
/// This keeps the temp preview file path around so that pressing
/// "Download" reuses the already-downloaded bytes instead of
/// re-fetching from the network.
class VideoFlowController extends ChangeNotifier {
  VideoFlowController({
    required this.downloadsProvider,
    ApiService? apiService,
    DownloadService? downloadService,
  })  : _apiService = apiService ?? ApiService(),
        _downloadService = downloadService ?? DownloadService();

  final DownloadsProvider downloadsProvider;
  final ApiService _apiService;
  final DownloadService _downloadService;

  FlowState _state = FlowState.idle;
  String? _errorMessage;
  String? _tempFilePath;
  DownloadItem? _currentItem;
  DownloadProgress? _previewProgress;
  String _statusMessage = '';

  FlowState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get tempFilePath => _tempFilePath;
  DownloadItem? get currentItem => _currentItem;
  DownloadProgress? get previewProgress => _previewProgress;
  String get statusMessage => _statusMessage;

  bool get isBusy =>
      _state == FlowState.validating ||
      _state == FlowState.callingApi ||
      _state == FlowState.fetchingPreview;

  /// Starts the full flow for a user-entered URL.
  Future<void> processUrl(String rawUrl) async {
    _reset();
    _state = FlowState.validating;
    _statusMessage = 'Validating URL...';
    notifyListeners();

    final normalized = UrlValidator.normalize(rawUrl);
    if (normalized == null) {
      _fail('Please enter a valid video URL.');
      return;
    }

    _state = FlowState.callingApi;
    _statusMessage = 'Processing URL...';
    notifyListeners();

    ApiVideoResponse apiResponse;
    try {
      apiResponse = await _apiService.resolveVideo(normalized);
    } on ApiException catch (e) {
      _fail(e.userMessage);
      return;
    } catch (e) {
      _fail('Unable to process this URL.');
      return;
    }

    _state = FlowState.fetchingPreview;
    _statusMessage = 'Fetching video...';
    notifyListeners();

    final suggestedName = _buildSuggestedFilename(apiResponse, normalized);

    final item = downloadsProvider.createPendingItem(
      sourceUrl: normalized,
      downloadUrl: apiResponse.downloadUrl,
      filename: suggestedName,
    );
    _currentItem = item.copyWith(
      title: apiResponse.title,
      fileSizeBytes: apiResponse.fileSizeBytes,
      durationMs: apiResponse.durationMs,
      status: DownloadStatus.downloading,
    );
    downloadsProvider.updateItem(_currentItem!);

    try {
      _statusMessage = 'Preparing preview...';
      notifyListeners();

      final tempPath = await _downloadService.downloadToTemp(
        url: apiResponse.downloadUrl,
        suggestedFilename: suggestedName,
        onProgress: (progress) {
          _previewProgress = progress;
          notifyListeners();
        },
      );

      _tempFilePath = tempPath;
      _currentItem = _currentItem!.copyWith(
        localPath: tempPath,
        status: DownloadStatus.completed,
        fileSizeBytes: _currentItem!.fileSizeBytes ?? _previewProgress?.totalBytes,
      );
      downloadsProvider.updateItem(_currentItem!);

      _state = FlowState.previewReady;
      _statusMessage = 'Preview ready';
      notifyListeners();
    } on DownloadFailure catch (e) {
      _currentItem = _currentItem?.copyWith(status: DownloadStatus.failed);
      if (_currentItem != null) downloadsProvider.updateItem(_currentItem!);
      _fail(e.userMessage);
    } catch (e) {
      _currentItem = _currentItem?.copyWith(status: DownloadStatus.failed);
      if (_currentItem != null) downloadsProvider.updateItem(_currentItem!);
      _fail('Video preview could not be loaded.');
    }
  }

  /// Confirms the download: moves the already-downloaded temp file to
  /// permanent storage without re-downloading, per spec section 40.
  Future<DownloadItem?> confirmDownload() async {
    if (_currentItem == null || _tempFilePath == null) {
      _fail('Video preview could not be loaded.');
      return null;
    }

    try {
      final permanentPath = await _downloadService.moveTempToPermanent(
        tempFilePath: _tempFilePath!,
        desiredFilename: _currentItem!.filename,
      );

      _currentItem = _currentItem!.copyWith(
        localPath: permanentPath,
        status: DownloadStatus.completed,
        completedAt: DateTime.now(),
      );
      downloadsProvider.updateItem(_currentItem!);
      _tempFilePath = null;
      notifyListeners();
      return _currentItem;
    } on DownloadFailure catch (e) {
      _fail(e.userMessage);
      return null;
    } catch (e) {
      _fail('Not enough storage available.');
      return null;
    }
  }

  /// Discards the current preview, cleaning up its temp file if the user
  /// never confirmed a download.
  Future<void> discardPreview() async {
    if (_tempFilePath != null) {
      await _downloadService.clearTempCache();
    }
    _reset();
    notifyListeners();
  }

  String _buildSuggestedFilename(ApiVideoResponse response, String sourceUrl) {
    final base = (response.title != null && response.title!.trim().isNotEmpty)
        ? response.title!.trim()
        : _filenameFromUrl(sourceUrl);
    final ext = p.extension(Uri.parse(response.downloadUrl).path);
    final safeExt = ext.isNotEmpty ? ext : '.mp4';
    return FilenameSanitizer.sanitize('$base$safeExt');
  }

  String _filenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video';
      return last.isNotEmpty ? last : 'video';
    } catch (_) {
      return 'video';
    }
  }

  void _fail(String message) {
    _state = FlowState.error;
    _errorMessage = message;
    _statusMessage = message;
    notifyListeners();
  }

  void _reset() {
    _state = FlowState.idle;
    _errorMessage = null;
    _tempFilePath = null;
    _currentItem = null;
    _previewProgress = null;
    _statusMessage = '';
  }

  @override
  void dispose() {
    _apiService.dispose();
    _downloadService.dispose();
    super.dispose();
  }
}
