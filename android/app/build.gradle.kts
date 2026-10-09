plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "sanadi.quran"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once published on Google Play.
        applicationId = "sanadi.quran"
        // Android 8.0+ (API 26), per the product spec; Firebase needs 23+.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // The permanent upload key comes from CI secrets (never from the repo).
    // Without them (e.g. a local build) the debug key is used.
    val keystorePath = System.getenv("SANADI_KEYSTORE")
    val keystorePassword = System.getenv("SANADI_KEYSTORE_PASSWORD")
    val hasUploadKey = !keystorePath.isNullOrEmpty() && file(keystorePath).exists() && !keystorePassword.isNullOrEmpty()

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(keystorePath!!)
                storePassword = keystorePassword
                keyAlias = System.getenv("SANADI_KEY_ALIAS") ?: "sanadi"
                keyPassword = System.getenv("SANADI_KEY_PASSWORD") ?: keystorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasUploadKey) "upload" else "debug")
            // Keeps the WebRTC (calls) classes that are reached from native code.
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
