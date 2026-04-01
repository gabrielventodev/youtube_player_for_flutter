pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        kotlin("multiplatform") version "2.1.0"
        id("com.android.library") version "8.9.1"
    }
}

rootProject.name = "shared"
