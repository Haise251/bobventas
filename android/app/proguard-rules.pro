# Reglas ProGuard para Bob Ventas.
# Mantienen las clases del plugin térmico y de SQLite que se usan por
# reflexión / JNI.

-keep class io.flutter.** { *; }
-keep class com.technozenmedia.flutter_thermal_printer.** { *; }
-keep class com.sunildevx.flutter_thermal_printer.** { *; }
-dontwarn org.jetbrains.annotations.**
