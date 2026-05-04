# ProGuard rules for Flutter app

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Supabase & GoTrue (CRITICAL - keep all classes)
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-keep class io.github.gotrue.** { *; }
-keep class io.github.postgresttclient.** { *; }
-keep class io.github.realtimeclient.** { *; }
-keep class io.github.storageClient.** { *; }
-keep class io.github.functions_dart.** { *; }
-keep class io.github.realtime_client.** { *; }

# UUID Package (used by Supabase)
-keep class com.google.uuid.** { *; }
-keep class java.util.UUID { *; }
-keep class java.util.UUID$* { *; }

# JWT Decoder (used for auth tokens)
-keep class com.auth0.jwt.** { *; }
-keep class com.auth0.jwt.algorithms.** { *; }
-keep class com.auth0.jwt.exceptions.** { *; }

# OkHttp (critical for networking)
-keep class okhttp3.** { *; }
-keep class okhttp3.internal.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-keep interface okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Retrofit (used for REST APIs)
-keep class retrofit2.** { *; }
-keep interface retrofit2.** { *; }
-keep class com.squareup.retrofit2.** { *; }
-dontwarn retrofit2.**

# JSON Serialization (Gson/Moshi)
-keep class com.google.gson.** { *; }
-keep interface com.google.gson.** { *; }
-keep class com.squareup.moshi.** { *; }
-keep interface com.squareup.moshi.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}

# Cronet & Conscrypt (Android networking)
-keep class org.chromium.net.** { *; }
-keep class com.google.android.gms.net.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn org.chromium.net.**
-dontwarn com.google.android.gms.**

# Bouncycastle (SSL/TLS)
-keep class org.bouncycastle.** { *; }
-keep interface org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# dart_web_crypto
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses,EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations

# Keep Dart bindings
-keep class com.myazz.app.** { *; }
-keep class com.myazz.** { *; }

# Prevent obfuscation of entity/model classes
-keep class **.models.** { *; }
-keep class **.entities.** { *; }
-keep class **.domain.** { *; }
-keep class **.data.** { *; }
-keep class **.presentation.** { *; }

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep all Serializable classes
-keep class * implements java.io.Serializable { *; }

# Keep Parcelable implementations
-keep interface android.os.Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Provider package (state management)
-keep class **.providers.** { *; }
-keep class **.presentation.providers.** { *; }

# Equatable package
-keep class com.google.common.collect.** { *; }

# Dartz package (Either, Option, etc)
-keep class dartz.** { *; }

# Intl package
-keep class com.ibm.icu.** { *; }
-dontwarn com.ibm.icu.**

# Lottie animation
-keep class com.airbnb.lottie.** { *; }
-keep interface com.airbnb.lottie.** { *; }

# Flutter dotenv
-keep class dotenv.** { *; }

# Keep shared_preferences classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep image_picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep geolocator classes
-keep class com.baseflow.geolocator.** { *; }

# Keep geocoding classes
-keep class com.baseflow.geocoding.** { *; }

# Keep url_launcher classes
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep share_plus classes
-keep class dev.fluttercommunity.plus.share.** { *; }

# HTTP package
-keep class io.flutter.plugins.http.** { *; }

# Cached network image
-keep class com.bumptech.glide.** { *; }
-keep interface com.bumptech.glide.** { *; }

# Ignore warnings for external libraries
-dontwarn io.flutter.embedding.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.*
-dontwarn com.google.j2objc.annotations.**
-dontwarn java.lang.ClassValue
-dontwarn sun.misc.Unsafe
-dontwarn java.lang.invoke.**
