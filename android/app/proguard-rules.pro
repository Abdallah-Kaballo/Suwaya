# حماية مكتبات فايربيز من الحذف (R8 Stripping) في نسخة الـ Release
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class io.flutter.plugins.firebase.** { *; }