plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.akhdar.akhdar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.akhdar.akhdar"
        // Firebase Auth بيطلب 23 كحد أدنى. الافتراضي في Flutter دلوقتي 24
        // (أندرويد ٧ وفوق) فهو مغطّي المطلوب. متسبهوش يقل عن 23.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // مؤقتًا بمفتاح الديبج عشان `flutter build apk --release` يشتغل
            // ويتوزّع على الزباين مباشرة. قبل الرفع على Google Play لازم
            // مفتاح توقيع حقيقي — راجع SETUP.md خطوة (٦).
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
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
