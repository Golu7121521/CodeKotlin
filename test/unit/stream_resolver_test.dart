import 'package:flutter_test/flutter_test.dart';
import 'package:movie_stream/models/stream_source_model.dart';
import 'package:movie_stream/services/stream_resolver.dart';

void main() {
  group('StreamResolver (demo catalog mode)', () {
    test('resolves a known movie ID to its demo sources', () async {
      final resolver = StreamResolver(useDemoCatalog: true);
      final result = await resolver.resolve(550); // Fight Club demo mapping
      expect(result.hasSources, isTrue);
      expect(result.sources.length, greaterThanOrEqualTo(1));
      expect(result.preferred, isNotNull);
    });

    test('falls back to a generic sample for an unmapped movie ID', () async {
      final resolver = StreamResolver(useDemoCatalog: true);
      final result = await resolver.resolve(999999999);
      expect(result.hasSources, isTrue);
      expect(result.sources.single.label, 'Sample Preview');
    });
  });

  group('StreamResolver (backend mode without configuration)', () {
    test('returns an empty resolved stream rather than throwing', () async {
      final resolver = StreamResolver(useDemoCatalog: false, backendBaseUrl: null);
      final result = await resolver.resolve(1);
      expect(result.hasSources, isFalse);
    });
  });

  group('ResolvedStream', () {
    test('ResolvedStream.empty has no sources and no preferred', () {
      final empty = ResolvedStream.empty(1);
      expect(empty.hasSources, isFalse);
      expect(empty.preferred, isNull);
    });
  });
}
