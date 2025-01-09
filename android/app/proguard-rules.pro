# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign-In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keepattributes Signature
-keepattributes *Annotation*

# Keep safe parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Prevent obfuscation of classes annotated with @Keep
-keep @androidx.annotation.Keep class *
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Optional: Keep all classes extending FirebaseMessagingService or other Firebase services
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService {
    *;
}
-keep class * extends com.google.firebase.iid.FirebaseInstanceIdService {
    *;
}
