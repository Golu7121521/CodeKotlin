# Gitbox release ProGuard/R8 rules

# Kotlinx Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.json.** { kotlinx.serialization.KSerializer serializer(...); }
-keep,includedescriptorclasses class com.gitbox.**$$serializer { *; }
-keepclassmembers class com.gitbox.** { *** Companion; }
-keepclasseswithmembers class com.gitbox.** { kotlinx.serialization.KSerializer serializer(...); }

# Ktor (client engine reflection + Netty/OkHttp internals)
-dontwarn io.ktor.**
-keep class io.ktor.client.engine.okhttp.** { *; }
-keep class io.ktor.util.reflect.** { *; }

# slf4j — ktor-client-logging references slf4j classes optionally (via OkHttp's logging
# interceptor chain) but no slf4j binding is on the runtime classpath. These are safe to
# ignore: they're only reached if an app explicitly wires up an slf4j logger, which Gitbox
# does not.
-dontwarn org.slf4j.**
-dontwarn org.slf4j.impl.StaticLoggerBinder

# OkHttp's other optional TLS providers — referenced reflectively for platform detection,
# never actually invoked unless present on the classpath (they aren't here).
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Hilt / Dagger
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep,allowobfuscation,allowshrinking class dagger.hilt.android.internal.managers.ViewComponentManager$FragmentContextWrapper

# Coroutines
-keepclassmembernames class kotlinx.coroutines.internal.MainDispatcherFactory
-keepclassmembernames class kotlinx.coroutines.CoroutineExceptionHandler
-dontwarn kotlinx.coroutines.flow.**internal**

# Keep Gitbox model classes (Git Data API DTOs) fully intact
-keep class com.gitbox.data.remote.model.** { *; }
-keep class com.gitbox.domain.model.** { *; }
