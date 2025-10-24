plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties // Import for Properties

android {
    namespace = "com.ramil.foundation_school"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Load keystore properties if available
    val keystorePropertiesFile = file("keystore.properties")
    val keystoreProperties = Properties().apply {
        if (keystorePropertiesFile.exists()) {
            load(keystorePropertiesFile.inputStream())
        }
    }

    signingConfigs {
        create("release") {
            // Use properties if available, else fallback to placeholder values
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: "release"
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: "3000usa$"
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "release-key.jks")
            storePassword = keystoreProperties.getProperty("storePassword") ?: "3000usa$"
        }
    }

    defaultConfig {
        applicationId = "com.ramil.foundation_school"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    ndkVersion = "27.0.12077973"

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.android.gms:play-services-ads:23.4.0")
}