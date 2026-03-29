# LINE SDK ProGuard Rules
-keep class com.linecorp.linesdk.** { *; }
-keep interface com.linecorp.linesdk.** { *; }
-dontwarn com.linecorp.linesdk.**

# Optional: Fix for DataBinding missing class BR if needed
-keep class com.linecorp.linesdk.databinding.** { *; }
-keep class com.linecorp.linesdk.BR { *; }

# Strip all android.util.Log calls to pass MobSF logging checks
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}
