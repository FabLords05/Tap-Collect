# Tap&Collect - Stable Build Versions

This document records the finalized and tested versions for building Tap&Collect on Android.

## Gradle & Build Tools

| Component | Version | Notes |
|-----------|---------|-------|
| **Gradle Wrapper** | 8.7 | Updated from 8.2.1; required for AGP 8.6.0 compatibility |
| **Android Gradle Plugin (AGP)** | 8.6.0 | Stable version supporting Android API 35 |
| **Kotlin Plugin** | 2.0.0 | Latest stable; required by Gradle 8.7 and AGP 8.6.0 |
| **Build Tools** | 35.0.0 | Matches compileSdk 35 |
| **Compile SDK** | 35 | Required by androidx.camera 1.5.1 and other dependencies |

## Java/Kotlin Targets

| Configuration | Version | Notes |
|---------------|---------|-------|
| **Java sourceCompatibility** | 17 (VERSION_17) | Set in `android/app/build.gradle` |
| **Java targetCompatibility** | 17 (VERSION_17) | Set in `android/app/build.gradle` |
| **Kotlin jvmTarget** | 17 | Set in `android/app/build.gradle` and global `android/build.gradle` |

## Key Dependencies

| Package | Version | Notes |
|---------|---------|-------|
| **nfc_manager** | 3.5.0 | Compatible with current Flutter SDK; Java 1.8 target |
| **mobile_scanner** | 7.1.3 | QR code scanning |
| **shared_preferences** | 2.2.2 | Local persistence |
| **http** | 1.6.0 | REST API communication |

## Configuration Files

### android/gradle/wrapper/gradle-wrapper.properties
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-all.zip
```

### android/settings.gradle (plugins block)
```gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.6.0" apply false
    id "org.jetbrains.kotlin.android" version "2.0.0" apply false
}
```

### android/build.gradle (ext block)
```gradle
ext {
    kotlin_version = '2.0.0'
}
```

### android/app/build.gradle (compileOptions & kotlinOptions)
```gradle
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlinOptions {
    jvmTarget = "17"
}
```

### android/gradle.properties
```properties
kotlin.jvm.target.validation.mode=warning
```

## Build Command

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

## Output

Release APK location:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Testing

- Build tested successfully with all specified versions
- JVM target validation set to warning mode to allow mixed JVM targets (app at 17, dependencies at 1.8)
- Compiled against Android API 35
- Ready for installation on physical Android devices

---

**Last Updated**: December 10, 2025  
**Status**: Stable & Verified
