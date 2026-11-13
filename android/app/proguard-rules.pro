# --- Flutter plugins (Pigeon/JNI gọi bằng tên method nên không được đổi tên) ---
-keep class io.flutter.plugins.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }

# --- Kotlin / coroutines / DataStore (shared_preferences_android) ---
-keep class kotlin.Metadata { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class androidx.datastore.** { *; }
-dontwarn androidx.datastore.**

# --- WorkManager / Room (lỗi trước đó) ---
-keep class * extends androidx.room.RoomDatabase
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# --- in_app_purchase_android (Google Play Billing) ---
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# --- google_mobile_ads ---
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.**

# --- google_sign_in v7 (Credential Manager) ---
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn androidx.credentials.**

# --- sign_in_with_apple (Android dùng Custom Tabs) ---
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }
-keep class androidx.browser.** { *; }

# --- flutter_zxing (native C++/FFI, giữ để JNI không mất) ---
-keep class com.github.zxingcpp.** { *; }
-keepclasseswithmembernames class * { native <methods>; }

# --- printing / pdf ---
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# --- Google Play Core (Flutter deferred components, tránh lỗi missing class) ---
-dontwarn com.google.android.play.core.**