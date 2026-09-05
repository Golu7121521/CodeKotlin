import 'package:shared_preferences/shared_preferences.dart';

/// Every default file that gets written into a freshly created project.
/// Users can override any of these from the Settings screen - the override
/// is stored in SharedPreferences and used instead of the built-in default
/// the next time a project is created.
class TemplateService {
  static const _prefPrefix = 'flutide_template_override_';

  static const Map<String, String> keys = {
    'main_dart': 'lib/main.dart',
    'pubspec_yaml': 'pubspec.yaml',
    'workflow_yml': '.github/workflows/flutter_build.yml',
    'gitignore': '.gitignore',
    'analysis_options': 'analysis_options.yaml',
    'readme': 'README.md',
  };

  static Future<Map<String, String>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, String>{};
    for (final id in keys.keys) {
      result[id] = prefs.getString('$_prefPrefix$id') ?? _defaults[id]!;
    }
    return result;
  }

  static Future<String> get(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefPrefix$id') ?? _defaults[id]!;
  }

  static Future<void> save(String id, String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefPrefix$id', content);
  }

  static Future<void> resetToDefault(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefPrefix$id');
  }

  static String defaultOf(String id) => _defaults[id]!;

  static final Map<String, String> _defaults = {
    'main_dart': '''import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '\$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
''',
    'pubspec_yaml': '''name: flutter_project
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
''',
    'workflow_yml': '''name: Build Flutter APK

on:
  workflow_dispatch:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: "temurin"
          java-version: "17"

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.24.0"
          channel: "stable"
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build APK (arm64 only, no split-per-abi)
        run: flutter build apk --release --target-platform android-arm64 --android-skip-build-dependency-validation

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
''',
    'gitignore': '''.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
*.iml
.idea/
android/local.properties
android/.gradle/
''',
    'analysis_options': '''include: package:flutter_lints/flutter.yaml
''',
    'readme': '''# Flutter Project

Created with FlutIDE. Push to GitHub and let GitHub Actions build your APK.
''',
  };
}
