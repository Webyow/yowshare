allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

/* ----------------------------------------------------------
   🔥 Global Fix for all Flutter plugins (AGP 8.x Compatible)
   IMPORTANT:
   - DO NOT ENABLE desugaring in plugins!
   - ONLY apply Java 17, Kotlin 17, Multidex.
---------------------------------------------------------- */
subprojects {

    // Apply Java 17 + Multidex to all Android Library modules
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {

            defaultConfig {
                multiDexEnabled = true
            }

            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17

                // ❗ CRITICAL FIX:
                // DO NOT ENABLE DESUGARING IN PLUGINS
                // isCoreLibraryDesugaringEnabled must NOT be set here.
            }
        }
    }

    // Apply Kotlin JVM 17 to all plugin modules
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = JavaVersion.VERSION_17.toString()
        }
    }
}

/* Clean task */
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
