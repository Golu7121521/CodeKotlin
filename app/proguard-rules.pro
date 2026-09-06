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
