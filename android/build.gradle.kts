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

// Unele plugin-uri (tflite_flutter, flutter_timezone, camera_android_camerax) nu
// setează explicit targetul JVM, iar toolchain-ul auto-detectat de Kotlin (21) ajunge
// să nu se potrivească cu javac (11). Forțăm 17 peste tot ca să elimine conflictul.
// tflite_flutter (0.12.1) își fixează propriul compileOptions Java la 11 în build.gradle-ul
// pachetului, ceea ce intră în conflict cu targetul Kotlin implicit (21, luat din JDK-ul curent).
// Aliniem doar targetul Kotlin al acestui modul la 11, fără să atingem celelalte plugin-uri
// (camera_android_camerax, flutter_timezone), care își gestionează deja corect targetul la 17.
gradle.projectsEvaluated {
    rootProject.project(":tflite_flutter") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
