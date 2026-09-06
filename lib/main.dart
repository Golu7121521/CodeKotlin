import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/catalog_provider.dart';
import 'providers/downloads_provider.dart';
import 'providers/performance_provider.dart';
import 'providers/search_provider.dart';
import 'providers/watchlist_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final performanceProvider = PerformanceProvider();
  await performanceProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: performanceProvider),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => DownloadsProvider()),
      ],
      child: const MovieStreamApp(),
    ),
  );
}
