# Reglas ProGuard para Bob Ventas.
# Mantienen las clases del plugin térmico y de SQLite que se usan por
# reflexión / JNI.

-keep class io.flutter.** { *; }
-keep class com.technozenmedia.flutter_thermal_printer.** { *; }
-keep class com.sunildevx.flutter_thermal_printer.** { *; }
-dontwarn org.jetbrains.annotations.**

# El embedding de Flutter referencia Play Core (componentes diferidos de
# Play Store) pero esta app no los usa. Sin estas reglas R8 falla con
# "Missing class com.google.android.play.core..." si se activa minify.
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**
