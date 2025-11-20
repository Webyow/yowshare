import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ======================================================
// JVM FIX FOR ALL FLUTTER MODULES & PLUGINS
// ======================================================
subprojects {

    afterEvaluate {

        // Force Java 17 for all Android modules
        extensions.findByName("android")?.let { androidExt ->
            androidExt.javaClass.methods.find { it.name == "getCompileOptions" }
                ?.invoke(androidExt)?.let { compileOptions ->
                    compileOptions.javaClass.methods.find { it.name == "setSourceCompatibility" }
                        ?.invoke(compileOptions, JavaVersion.VERSION_17)
                    compileOptions.javaClass.methods.find { it.name == "setTargetCompatibility" }
                        ?.invoke(compileOptions, JavaVersion.VERSION_17)
                }
        }

        // Force Kotlin JVM 17 for all modules
        tasks.withType<KotlinCompile>().configureEach {
            kotlinOptions.jvmTarget = "17"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
