# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Preserve generic signatures (required for notification serialization)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Keep TypeToken (used by notification plugin)
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}