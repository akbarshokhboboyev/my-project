import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) signingFile.inputStream().use { signingProperties.load(it) }
fun signingValue(key: String, variable: String): String? =
    System.getenv(variable)?.takeIf { it.isNotBlank() } ?: signingProperties.getProperty(key)
val releaseStore = signingValue("storeFile", "SHIELD_STORE_FILE")
val releasePassword = signingValue("storePassword", "SHIELD_STORE_PASSWORD")
val releaseAlias = signingValue("keyAlias", "SHIELD_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "SHIELD_KEY_PASSWORD")
val hasSigning = listOf(releaseStore, releasePassword, releaseAlias, releaseKeyPassword).all { !it.isNullOrBlank() }

android {
    namespace = "uz.app.shieldguard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    signingConfigs {
        if (hasSigning) create("production") {
            storeFile = rootProject.file(releaseStore!!)
            storePassword = releasePassword
            keyAlias = releaseAlias
            keyPassword = releaseKeyPassword
        }
    }
    buildTypes {
        getByName("release") {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            if (hasSigning) signingConfig = signingConfigs.getByName("production")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "uz.app.shieldguard"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

}

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name in setOf("assembleRelease", "bundleRelease") } && !hasSigning &&
        !project.hasProperty("shieldAllowUnsigned") && System.getenv("SHIELD_ALLOW_UNSIGNED") != "true") {
        throw GradleException("Release imzolash sozlanmagan. RELEASE_GUIDE.md hujjatini ko‘ring.")
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

dependencies {
    implementation("com.android.tools.build:apksig:9.1.0")
    implementation("com.tom-roush:pdfbox-android:2.0.27.0")
}
