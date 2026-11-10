import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. android/key.properties is gitignored; CI writes it from the
// NEWORDERS_KEYSTORE_* secrets. Every APK must carry the same key: a phone
// refuses to update an installed app whose signature changed, and a CI
// runner's debug key is new on every run.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKey = keystorePropertiesFile.exists()

android {
    // Its own id, so it never collides with the customer app
    // (com.sribeesonline.sribees_mobile) or Sribees Price on a staff phone.
    namespace = "com.sribeesonline.sribees_new_orders"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sribeesonline.sribees_new_orders"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // dev talks to devapionline.sribees.com and installs next to prod
    // (".dev" id, "DEV" in the name), so testers can keep both on one phone.
    // The Dart side reads the flavor through `appFlavor`.
    buildFeatures {
        resValues = true // app_name comes from each flavor's resValue
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Sribees New Orders DEV")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Sribees New Orders")
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKey) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // Relative to android/, which is where key.properties lives.
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // A local `flutter run --release` has no key.properties and falls
            // back to the debug key; CI refuses to build without the real one.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("android/key.properties not found -- signing the release build with the DEBUG key.")
                signingConfigs.getByName("debug")
            }
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
