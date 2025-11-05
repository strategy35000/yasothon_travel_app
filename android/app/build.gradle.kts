// *** เพิ่มบรรทัดนี้: เพื่อ import คลาส Properties จาก Java ***
import java.util.Properties 
import java.io.FileInputStream // *แนะนำให้เพิ่มด้วย เพื่อใช้จัดการไฟล์ input stream*

val properties = Properties()
val propertiesFile = rootProject.file("key.properties")
if (propertiesFile.exists()) {
    propertiesFile.inputStream().use { properties.load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}



android {
    namespace = "com.example.yasothon_travel_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.travel.yasothon.go.th" // <--- แก้ไขบรรทัดนี้

        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
   //     targetSdk = flutter.targetSdkVersion
        targetSdk = 36 // หรือ flutter.targetSdkVersion หากคุณมั่นใจว่าค่าใน flutter.gradle ถูกต้อง
        compileSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

        // *** เพิ่ม: บล็อกการตั้งค่าการลงนาม (Signing Configuration) ***
    signingConfigs {
        create("release") {
            storeFile = file(properties.getProperty("storeFile"))
            storePassword = properties.getProperty("storePassword")
            keyAlias = properties.getProperty("keyAlias")
            keyPassword = properties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            // signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release") // <--- บรรทัดสำคัญ: ใช้คีย์ Release

        }
    }
}

flutter {
    source = "../.."
}
