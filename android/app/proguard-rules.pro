# Pounce – R8 rules for the release build.
#
# Flutter, Media3 and most plugins ship their own consumer rules. Only list here what is
# reached via reflection, JNI or by name from outside and would otherwise be optimised away.

# Own plugins: classes are loaded by name from GeneratedPluginRegistrant and by the system
# (MediaSessionService from the manifest); MethodChannel handlers are named as in the Dart code.
-keep class dev.pounce.** { *; }

# package:jni (libdartjni.so) calls Java methods by name via JNI.
-keep class com.github.dart_lang.jni.** { *; }

# Media3: the session service and extractors are partly found via reflection (consumer rules
# cover most of it; these lines protect the parts Pounce extends directly).
-keep class androidx.media3.session.MediaSessionService { *; }
-keep class * extends androidx.media3.common.audio.BaseAudioProcessor { *; }
-keep class * extends androidx.media3.exoplayer.audio.ForwardingAudioSink { *; }

# Keep native methods of all classes (JNI signatures must match).
-keepclasseswithmembernames class * { native <methods>; }

# Note: deckengine (Rust) and sqlite3 are loaded via dart:ffi with dlopen – no JNI,
# so no Java rules are needed. R8 doesn't touch the .so files.

# Play Core is only included in the "play" flavor; in the "github" flavor the classes are missing on purpose.
-dontwarn com.google.android.play.core.**
