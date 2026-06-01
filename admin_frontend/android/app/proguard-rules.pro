# Flutter Background Service
-keep class id.flutter.flutter_background_service.** { *; }
-keep class androidx.lifecycle.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Keep all Flutter plugin registrants
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# General: keep all classes that are serialized/deserialized
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Prevent stripping of Dart entry points
-keep @interface com.google.android.gms.common.annotation.KeepName
-keepnames @com.google.android.gms.common.annotation.KeepName class *
