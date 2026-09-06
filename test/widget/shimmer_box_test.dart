import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_stream/providers/performance_provider.dart';
import 'package:movie_stream/widgets/shimmer_box.dart';

void main() {
  testWidgets('ShimmerBox renders at the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShimmerBox(width: 100, height: 150),
        ),
      ),
    );

    final size = tester.getSize(find.byType(ShimmerBox));
    expect(size.width, 100);
    expect(size.height, 150);
  });

  testWidgets('ShimmerBox in reduced performance mode renders a static box',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShimmerBox(
            width: 100,
            height: 150,
            performanceMode: AppPerformanceMode.reduced,
          ),
        ),
      ),
    );
    await tester.pump();

    // In reduced mode there should be no ShaderMask (the animated sweep).
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('ShimmerPosterRow renders the requested item count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShimmerPosterRow(itemCount: 4),
        ),
      ),
    );

    expect(find.byType(ShimmerBox), findsNWidgets(4));
  });
}
