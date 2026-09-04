plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.suwaya"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // 🟢 تفعيل الـ Desugaring بشكل صحيح للـ Kotlin DSL
        isCoreLibraryDesugaringEnabled = true 
    }

    defaultConfig {
        applicationId = "com.example.suwaya"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
} // 🌟 تم إغلاق كتلة android هنا بشكل صحيح

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🟢 مكتبة الـ Desugaring لمعالجة الدوال الحديثة (مثل الاشعارات والزمن) في الأجهزة القديمة
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // 🌟 الحل الجذري لـ Crashlytics: إضافة مكتبات فايربيز الأصلية لمنع المحسن (R8) من حذفها في الـ Release
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics") // Crashlytics يعتمد على Analytics ليعمل بكفاءة
}