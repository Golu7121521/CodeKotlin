import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum HomeStatus { loading, success, empty, error, offline }

class HomeSection {
  final String title;
  final List<Song> songs;
  HomeSection(this.title, this.songs);
}

/// Populates Home sections from real API search results (since the API
/// has no dedicated chart endpoints) plus the user's local recently
/// played history. Never uses fake/hardcoded song data.
class HomeProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  HomeStatus _status = HomeStatus.loading;
  List<HomeSection> _sections = [];
  Song? _featuredSong;

  HomeStatus get status => _status;
  List<HomeSection> get sections => _sections;
  Song? get featuredSong => _featuredSong;

  Future<void> loadHome() async {
    _status = HomeStatus.loading;
    notifyListeners();

    final List<HomeSection> sections = [];

    final recent = await _storage.getRecentlyPlayed();
    if (recent.isNotEmpty) {
      sections.add(HomeSection('Your Recent Echo', recent.take(10).toList()));
    }

    await _addSearchSection(sections, 'The Pulse — Trending Now', 'top hits 2025');
    await _addSearchSection(sections, 'Frequently Resonating', 'top songs');
    await _addSearchSection(sections, 'Fresh Signal', 'new songs');
    await _addSearchSection(sections, 'Curated For Your Ear', 'best songs');

    _sections = sections;

    if (sections.isEmpty) {
      _status = HomeStatus.empty;
    } else {
      _status = HomeStatus.success;
      for (final section in sections) {
        if (section.songs.isNotEmpty) {
          _featuredSong = section.songs.first;
          break;
        }
      }
    }

    notifyListeners();
  }

  Future<void> _addSearchSection(
    List<HomeSection> sections,
    String title,
    String query,
  ) async {
    final result = await _api.searchSongs(query);
    if (result.success && result.data != null && result.data!.isNotEmpty) {
      sections.add(HomeSection(title, result.data!.take(10).toList()));
    }
  }
}
