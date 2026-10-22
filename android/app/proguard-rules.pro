-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Isar Database JNI & Models protection
-keep class dev.isar.** { *; }
-keepclassmembers class * {
    @dev.isar.** <fields>;
    @dev.isar.** <methods>;
}

# Flutter Local Notifications & Alarm receivers
-keep class com.dexterous.** { *; }
-keep class com.gdelataillade.alarm.** { *; }

# RevenueCat & Play Billing / In-App Update protection
-keep class com.revenuecat.purchases.** { *; }
-keep class com.google.android.play.core.** { *; }