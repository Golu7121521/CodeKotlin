# Since minifyEnabled is false (see app/build.gradle for why), these
# rules are inert for the default build but are kept so that anyone who
# re-enables minification later has a safe starting point rather than
# hitting the class-stripping crashes this project intentionally avoids.

-dontwarn com.google.android.play.core.**
-dontwarn androidx.media3.**
-dontwarn io.flutter.embedding.**
-ignorewarnings

# Flutter wrapper classes.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# video_player / ExoPlayer (Media3) internals referenced via reflection.
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
