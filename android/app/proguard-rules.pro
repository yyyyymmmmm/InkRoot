# Flutter 相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Kotlin 相关规则
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# 保留 Parcelable 实现类
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# 保留 Serializable 实现类
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 图片选择器相关规则
-keep class com.luck.picture.lib.** { *; }

# OkHttp 相关规则
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# SQLite 相关规则
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# 保留 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留 R 文件中的属性
-keepclassmembers class **.R$* {
    public static <fields>;
}

# 避免混淆泛型
-keepattributes Signature

# 保留注解
-keepattributes *Annotation*

# 保留 JavaScript 接口
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Google Play Core 相关规则
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google Crypto Tink 相关规则
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.google.errorprone.annotations.**

# Flutter 引擎相关规则
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# 🚀 友盟统计 SDK 混淆规则（完整版）
# ===== 核心SDK =====
-keep class com.umeng.** { *; }
-keep class com.uc.** { *; }
-keepclassmembers class * {
    public <init>(org.json.JSONObject);
}

# ===== 友盟Analytics =====
-keep public class com.umeng.analytics.** { *; }
-keep public class com.umeng.commonsdk.** { *; }

# ===== 友盟Common =====
-keep class com.umeng.common.** { *; }
-dontwarn com.umeng.common.**

# ===== UMDevice（设备信息）=====
-keep class com.umeng.umzid.** { *; }
-keep class com.uc.crashsdk.** { *; }

# ===== UTDID（设备唯一标识）=====
-keep class com.ta.utdid2.** { *; }
-keep class com.ut.device.** { *; }

# ===== 保留枚举和内部类 =====
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keepattributes InnerClasses
-keepattributes Exceptions
-keepattributes Signature

# ===== 保留Native方法 =====
-keepclasseswithmembernames class * {
    native <methods>;
}

# ===== 防止反射被混淆 =====
-keepattributes *Annotation*

# ===== 保留友盟的异常捕获 =====
-keep public class * extends java.lang.Exception

# Gson 混淆规则（友盟依赖）
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }

# 移除日志
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
} 