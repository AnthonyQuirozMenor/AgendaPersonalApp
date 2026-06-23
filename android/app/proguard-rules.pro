# Flutter Local Notifications Proguard Rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.internal.** { *; }
-keep class com.google.gson.stream.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-dontwarn com.google.gson.**
