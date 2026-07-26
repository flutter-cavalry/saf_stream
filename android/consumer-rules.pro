# SafStreamJni is never referenced by any Dart-generated or Java/Kotlin
# static call -- it's looked up purely by string name at runtime via JNI
# (JClass.forName("com/fluttercavalry/saf_stream/SafStreamJni") from Dart).
# R8 has no static call graph edge to it, so in a release build it gets
# stripped (or renamed, which breaks the string lookup just as badly) unless
# explicitly kept.
#
# This is a *consumer* rule: it ships inside the plugin's AAR and is
# automatically applied to any app that depends on this plugin, with no
# action needed in the app's own proguard rules.
-keep class com.fluttercavalry.saf_stream.SafStreamJni { *; }
