import '../models/movie_model.dart';

/// A small, embedded catalog used when the TMDB API is unreachable
/// (DNS failure, network timeout, offline). This keeps the Home screen
/// populated with *something* browsable instead of an empty error state
/// on first launch or flaky connections. Data is intentionally minimal
/// (no live posters beyond what TMDB's CDN can still serve if only the
/// API host, not the image CDN, is down) and is replaced by live TMDB
/// data as soon as a request succeeds.
class FallbackCatalog {
  FallbackCatalog._();

  static List<Movie> trending() => [
        Movie(
          id: 27205,
          title: 'Inception',
          originalTitle: 'Inception',
          overview:
              'A thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea into the mind of a CEO.',
          posterPath: '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
          backdropPath: '/s3TBrRGB1iav7gFOCNx3H31MoES.jpg',
          voteAverage: 8.4,
          voteCount: 35000,
          releaseDate: DateTime(2010, 7, 15),
          genreIds: const [28, 878, 12],
          originalLanguage: 'en',
          popularity: 90.0,
          adult: false,
        ),
        Movie(
          id: 155,
          title: 'The Dark Knight',
          originalTitle: 'The Dark Knight',
          overview:
              'Batman raises the stakes in his war on crime with the help of Lt. Jim Gordon and District Attorney Harvey Dent.',
          posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
          backdropPath: '/hqkIcbrOHL86UncnHIsHVcVmzue.jpg',
          voteAverage: 8.5,
          voteCount: 32000,
          releaseDate: DateTime(2008, 7, 16),
          genreIds: const [18, 28, 80, 53],
          originalLanguage: 'en',
          popularity: 88.0,
          adult: false,
        ),
        Movie(
          id: 550,
          title: 'Fight Club',
          originalTitle: 'Fight Club',
          overview:
              'An insomniac office worker and a devil-may-care soap maker form an underground fight club that evolves into much more.',
          posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
          backdropPath: '/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
          voteAverage: 8.4,
          voteCount: 29000,
          releaseDate: DateTime(1999, 10, 15),
          genreIds: const [18],
          originalLanguage: 'en',
          popularity: 70.0,
          adult: false,
        ),
      ];

  static List<Movie> bollywood() => [
        Movie(
          id: 19404,
          title: 'Dilwale Dulhania Le Jayenge',
          originalTitle: 'Dilwale Dulhania Le Jayenge',
          overview:
              'Raj and Simran fall in love during a trip across Europe, but Simran\'s father has already promised her hand in marriage.',
          posterPath: '/2CAL2433ZeIihfX1Hb2139CX0pW.jpg',
          backdropPath: '/nBQR8SNlYaeK8yGdAg2xoRQCSf7.jpg',
          voteAverage: 8.1,
          voteCount: 4200,
          releaseDate: DateTime(1995, 10, 20),
          genreIds: const [35, 18, 10749],
          originalLanguage: 'hi',
          popularity: 40.0,
          adult: false,
        ),
        Movie(
          id: 267413,
          title: 'Dangal',
          originalTitle: 'Dangal',
          overview:
              'Former wrestler Mahavir Singh Phogat trains his daughters to become world-class wrestlers against social odds.',
          posterPath: '/lFmqrN5fpk9zLpj4gjRUJvpVh6a.jpg',
          backdropPath: '/9zkgcuJfEB0Ozs9xnbdKu2SDlJv.jpg',
          voteAverage: 8.3,
          voteCount: 3300,
          releaseDate: DateTime(2016, 12, 23),
          genreIds: const [18, 10751],
          originalLanguage: 'hi',
          popularity: 35.0,
          adult: false,
        ),
      ];

  static List<Genre> genres() => const [
        Genre(id: 28, name: 'Action'),
        Genre(id: 35, name: 'Comedy'),
        Genre(id: 18, name: 'Drama'),
        Genre(id: 878, name: 'Science Fiction'),
        Genre(id: 53, name: 'Thriller'),
        Genre(id: 10749, name: 'Romance'),
        Genre(id: 10751, name: 'Family'),
        Genre(id: 80, name: 'Crime'),
        Genre(id: 12, name: 'Adventure'),
      ];
}
