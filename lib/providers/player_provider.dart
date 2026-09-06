import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/storage_service.dart';

enum RepeatMode { off, all, one }

/// Centralized, observable playback state shared across all screens.
/// Wraps just_audio's AudioPlayer and exposes a simple queue-aware API.
class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StorageService _storage = StorageService();
  final Random _random = Random();

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isBuffering = false;
  bool _shuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  String? _errorMessage;

  PlayerProvider() {
    _audioPlayer.playerStateStream.listen(_onPlayerStateChanged);
    _audioPlayer.positionStream.listen((_) => notifyListeners());
  }

  // ---------------- Getters ----------------

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;

  bool get isPlaying => _audioPlayer.playing;
  bool get isBuffering => _isBuffering;
  Duration get position => _audioPlayer.position;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  bool get shuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  String? get errorMessage => _errorMessage;
  bool get hasActiveSong => currentSong != null;

  bool get hasNext {
    if (_queue.isEmpty) return false;
    if (_repeatMode == RepeatMode.all) return true;
    return _currentIndex < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_queue.isEmpty) return false;
    if (_repeatMode == RepeatMode.all) return true;
    return _currentIndex > 0;
  }

  void clearError() {
    _errorMessage = null;
  }

  // ---------------- Playback controls ----------------

  Future<void> playFromQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    _queue = List<Song>.from(songs);
    _currentIndex = startIndex;
    notifyListeners();

    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final song = currentSong;
    if (song == null) return;

    if (!song.hasPlayableUrl) {
      _errorMessage = "This song can't be played right now.";
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _isBuffering = true;
    notifyListeners();

    try {
      await _audioPlayer.setUrl(song.mediaUrl);
      await _audioPlayer.play();
      await _storage.addRecentlyPlayed(song);
    } catch (e) {
      _errorMessage = 'Playback error. Skipping to next song.';
      _isBuffering = false;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      await playNext();
      return;
    }

    _isBuffering = false;
    notifyListeners();
  }

  void _onPlayerStateChanged(PlayerState state) {
    _isBuffering = state.processingState == ProcessingState.buffering ||
        state.processingState == ProcessingState.loading;

    if (state.processingState == ProcessingState.completed) {
      _handleCompletion();
    }

    notifyListeners();
  }

  void _handleCompletion() {
    if (_repeatMode == RepeatMode.one) {
      _playCurrent();
      return;
    }

    final nextIndex = _computeNextIndex();
    if (nextIndex == -1) {
      notifyListeners();
      return;
    }

    _currentIndex = nextIndex;
    _playCurrent();
  }

  int _computeNextIndex() {
    if (_queue.isEmpty) return -1;

    if (_shuffleEnabled && _queue.length > 1) {
      int next;
      do {
        next = _random.nextInt(_queue.length);
      } while (next == _currentIndex);
      return next;
    }

    if (_currentIndex < _queue.length - 1) {
      return _currentIndex + 1;
    }

    if (_repeatMode == RepeatMode.all) return 0;

    return -1;
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    final nextIndex = _computeNextIndex();
    if (nextIndex == -1) return;
    _currentIndex = nextIndex;
    await _playCurrent();
  }

  Future<void> playPrevious() async {
    if (_audioPlayer.position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex -= 1;
      await _playCurrent();
    } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      _currentIndex = _queue.length - 1;
      await _playCurrent();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    notifyListeners();
  }

  void cycleRepeatMode() {
    _repeatMode = RepeatMode.values[(_repeatMode.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }

  // ---------------- Queue management ----------------

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void playNextInQueue(Song song) {
    final insertAt = _currentIndex >= 0 ? _currentIndex + 1 : 0;
    _queue.insert(insertAt, song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex -= 1;
    }
    notifyListeners();
  }

  Future<void> playQueueIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrent();
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _audioPlayer.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
