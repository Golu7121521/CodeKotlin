import 'package:flutter_test/flutter_test.dart';
import 'package:movie_stream/models/movie_model.dart';

void main() {
  group('Movie.fromJson', () {
    test('parses a well-formed TMDB movie response', () {
      final movie = Movie.fromJson({
        'id': 27205,
        'title': 'Inception',
        'original_title': 'Inception',
        'overview': 'A thief who steals corporate secrets...',
        'poster_path': '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
        'backdrop_path': '/s3TBrRGB1iav7gFOCNx3H31MoES.jpg',
        'vote_average': 8.4,
        'vote_count': 35000,
        'release_date': '2010-07-15',
        'genre_ids': [28, 878, 12],
        'original_language': 'en',
        'popularity': 90.0,
        'adult': false,
      });

      expect(movie.id, 27205);
      expect(movie.title, 'Inception');
      expect(movie.posterUrl, contains('9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg'));
      expect(movie.releaseYear, 2010);
      expect(movie.ratingLabel, '8.4');
    });

    test('falls back gracefully when poster_path is missing', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'Test'});
      expect(movie.posterUrl, isNull);
      expect(movie.overview, 'No overview available.');
      expect(movie.genreIds, isEmpty);
    });

    test('falls back to Untitled when title is missing entirely', () {
      final movie = Movie.fromJson({'id': 1});
      expect(movie.title, 'Untitled');
    });

    test('handles malformed release_date without throwing', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'Test', 'release_date': 'not-a-date'});
      expect(movie.releaseDate, isNull);
      expect(movie.releaseYear, isNull);
    });

    test('coerces numeric fields provided as strings', () {
      final movie = Movie.fromJson({
        'id': '42',
        'title': 'Test',
        'vote_average': '7.5',
        'vote_count': '100',
      });
      expect(movie.id, 42);
      expect(movie.voteAverage, 7.5);
      expect(movie.voteCount, 100);
    });

    test('runtimeLabel formats hours and minutes correctly', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'Test', 'runtime': 148});
      expect(movie.runtimeLabel, '2h 28m');
    });

    test('runtimeLabel omits minutes when exactly on the hour', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'Test', 'runtime': 120});
      expect(movie.runtimeLabel, '2h');
    });
  });

  group('MoviePage.fromJson', () {
    test('parses a paginated results list', () {
      final page = MoviePage.fromJson({
        'page': 1,
        'total_pages': 5,
        'total_results': 100,
        'results': [
          {'id': 1, 'title': 'A'},
          {'id': 2, 'title': 'B'},
        ],
      });
      expect(page.results.length, 2);
      expect(page.hasNextPage, isTrue);
    });

    test('returns empty results for a malformed results field', () {
      final page = MoviePage.fromJson({'page': 1, 'results': 'not-a-list'});
      expect(page.results, isEmpty);
    });
  });
}
