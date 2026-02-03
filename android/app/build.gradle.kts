import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.befit_fitness.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.befitfitness.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Read Google Maps API key from local.properties
        val mapsApiKey = run {
            val localPropertiesFile = rootProject.file("local.properties")
            if (localPropertiesFile.exists()) {
                val props = Properties()
                localPropertiesFile.inputStream().use { stream ->
                    props.load(stream)
                }
                props.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
            } else {
                ""
            }
        }
        
        // Set manifest placeholders
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { stream ->
            val rawProperties = Properties()
            rawProperties.load(stream)
            // Trim all keys and values to handle encoding/whitespace issues
            rawProperties.forEach { key, value ->
                keystoreProperties.setProperty(key.toString().trim(), value.toString().trim())
            }
        }
        println("INFO: key.properties loaded. Cleaned keys: ${keystoreProperties.keys}")
    } else {
        println("WARNING: key.properties NOT found at ${keystorePropertiesFile.absolutePath}")
    }

    signingConfigs {
        val alias = keystoreProperties.getProperty("keyAlias")
        val keyPass = keystoreProperties.getProperty("keyPassword")
        val storePass = keystoreProperties.getProperty("storePassword")
        val storePath = keystoreProperties.getProperty("storeFile")

        if (alias != null && keyPass != null && storePass != null && storePath != null) {
            create("release") {
                keyAlias = alias
                keyPassword = keyPass
                storeFile = rootProject.file("app/$storePath")
                storePassword = storePass
            }
            println("INFO: Release signing configuration created successfully.")
        } else {
            if (keystoreProperties.isNotEmpty()) {
                println("DEBUG: Cleaned keys found: ${keystoreProperties.keys}")
                println("DEBUG: Required keys missing. Checking for common issues...")
            }
            println("WARNING: Missing properties in key.properties. Build will fail back to debug signing.")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            val releaseConfig = signingConfigs.findByName("release")
            if (releaseConfig != null) {
                signingConfig = releaseConfig
                println("INFO: Using RELEASE signing configuration.")
            } else {
                signingConfig = signingConfigs.getByName("debug")
                println("CAUTION: FALLING BACK TO DEBUG SIGNING CONFIGURATION!")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
