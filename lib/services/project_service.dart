import 'dart:io';
import 'package:path/path.dart' as p;
import 'storage_service.dart';
import 'template_service.dart';
import '../models/project_model.dart';

class ProjectService {
  /// Creates a brand-new Flutter project on disk with the standard folder
  /// layout you'd get from `flutter create`, plus a ready-to-use
  /// .github/workflows/flutter_build.yml so the user can build via GitHub
  /// Actions immediately.
  static Future<Project> createProject(String rawName) async {
    final name = _sanitize(rawName);
    final root = await StorageService.projectsRoot();
    final projectDir = Directory(p.join(root.path, name));
    if (await projectDir.exists()) {
      throw Exception('Project "$name" already exists');
    }
    await projectDir.create(recursive: true);

    // --- Standard flutter create folders ---
    final folders = [
      'lib',
      'test',
      'assets',
      '.github/workflows',
      'android/app/src/main/kotlin/com/example/$name',
      'android/app/src/main/res/values',
      'android/gradle/wrapper',
      'ios/Runner',
      'web',
    ];
    for (final f in folders) {
      await Directory(p.join(projectDir.path, f)).create(recursive: true);
    }

    // --- User-editable template files ---
    final templates = await TemplateService.loadAll();
    await _write(projectDir.path, 'lib/main.dart', templates['main_dart']!);
    await _write(projectDir.path, 'pubspec.yaml',
        templates['pubspec_yaml']!.replaceFirst('flutter_project', name));
    await _write(projectDir.path, '.github/workflows/flutter_build.yml',
        templates['workflow_yml']!);
    await _write(projectDir.path, '.gitignore', templates['gitignore']!);
    await _write(
        projectDir.path, 'analysis_options.yaml', templates['analysis_options']!);
    await _write(projectDir.path, 'README.md',
        templates['readme']!.replaceFirst('# Flutter Project', '# $name'));

    // --- test/widget_test.dart (basic, standard flutter create content) ---
    await _write(projectDir.path, 'test/widget_test.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:$name/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
''');

    // --- Android build files (strict-compliance, same rules as this IDE app) ---
    await _write(projectDir.path, 'android/build.gradle', _androidRootGradle);
    await _write(projectDir.path, 'android/settings.gradle',
        _androidSettingsGradle(name));
    await _write(projectDir.path, 'android/gradle.properties', _androidGradleProps);
    await _write(projectDir.path, 'android/gradle/wrapper/gradle-wrapper.properties',
        _gradleWrapperProps);
    await _write(
        projectDir.path, 'android/app/build.gradle', _appGradle(name));
    await _write(projectDir.path, 'android/app/proguard-rules.pro', _proguardRules);
    await _write(projectDir.path, 'android/app/src/main/AndroidManifest.xml',
        _androidManifest(name));
    await _write(
        projectDir.path,
        'android/app/src/main/kotlin/com/example/$name/MainActivity.kt',
        _mainActivity(name));

    final project = Project(name: name, path: projectDir.path);
    await StorageService.addProject(project);
    return project;
  }

  static String _sanitize(String input) {
    var s = input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    if (s.isEmpty) s = 'my_flutter_app';
    if (RegExp(r'^[0-9]').hasMatch(s)) s = 'app_$s';
    return s;
  }

  static Future<void> _write(String projectPath, String rel, String content) async {
    final file = File(p.join(projectPath, rel));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Reads back the current file tree of a project as a nested map, used by
  /// the file explorer widget.
  static Future<List<FileSystemEntity>> listDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    final items = await dir.list().toList();
    items.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return p.basename(a.path).compareTo(p.basename(b.path));
    });
    return items;
  }

  static Future<void> deleteProject(Project project) async {
    final dir = Directory(project.path);
    if (await dir.exists()) await dir.delete(recursive: true);
    await StorageService.removeProject(project);
  }

  // ---- fixed, strict-compliance android files for GENERATED projects ----

  static const _androidRootGradle = '''
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = "../build"
subprojects {
    project.buildDir = "\${rootProject.buildDir}/\${project.name}"
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
''';

  static String _androidSettingsGradle(String name) => '''
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("\$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.11.1" apply false
    id "org.jetbrains.kotlin.android" version "2.2.20" apply false
}

include ":app"
''';

  static const _androidGradleProps = '''
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
android.nonTransitiveRClass=true
''';

  static const _gradleWrapperProps = '''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-8.14-all.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
''';

  static String _appGradle(String name) => '''
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader("UTF-8") { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
def flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.0"

android {
    namespace "com.example.$name"
    compileSdk 35
    ndkVersion "27.0.12077973"

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    defaultConfig {
        applicationId "com.example.$name"
        minSdkVersion 23
        targetSdkVersion 35
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
        }
    }
}

flutter {
    source '../..'
}
''';

  static const _proguardRules = '''
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn androidx.media3.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-ignorewarnings
''';

  static String _androidManifest(String name) => '''
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        android:label="$name"
        android:name="\${applicationName}"
        android:icon="@android:drawable/sym_def_app_icon"
        android:usesCleartextTraffic="true">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
</manifest>
''';

  static String _mainActivity(String name) => '''
package com.example.$name

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
''';
}
