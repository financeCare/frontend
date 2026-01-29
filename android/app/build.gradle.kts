plugins {
    id("com.android.application")
<<<<<<< Updated upstream
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")

=======
    id("kotlin-android")
>>>>>>> Stashed changes
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // เปิดใช้งาน Desugaring เพื่อรองรับ Java 8+ APIs (เช่น Time/Date) บน Android รุ่นเก่า
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // แนะนำให้ตั้ง Application ID ของคุณที่นี่
        applicationId = "com.example.flutter_application_1"

        // กำหนดค่า SDK โดยอ้างอิงจาก Flutter config
        // แนะนำให้ใช้ minSdk อย่างน้อย 21 เพื่อประสิทธิภาพที่ดีที่สุด
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // เปิดใช้งาน MultiDex เพื่อรองรับจำนวน Method ที่มากขึ้นในโปรเจกต์ขนาดใหญ่
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // การตั้งค่าสำหรับการปล่อยแอป (Release)
            // ในที่นี้ใช้ debug key ชั่วคราวเพื่อให้คำสั่ง `flutter run --release` ทำงานได้
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // เพิ่มไลบรารีสำหรับการทำ Desugaring เพื่อแก้ปัญหา Error เกี่ยวกับ JDK APIs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
