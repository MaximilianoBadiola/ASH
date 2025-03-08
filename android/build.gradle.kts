allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

tasks.register("renameReleaseApk") {
    dependsOn("assembleRelease")
    doLast {
        val sourceApk = file("../build/app/outputs/flutter-apk/app-release.apk")
        val destApk = file("../build/app/outputs/flutter-apk/ash.apk")
        if (sourceApk.exists()) {
            if (destApk.exists()) {
                destApk.delete()
            }
            println("Renombrando APK de: ${sourceApk.absolutePath}")
            println("A: ${destApk.absolutePath}")
            sourceApk.renameTo(destApk)
            println("APK renombrado exitosamente")
        } else {
            println("¡El archivo de origen no existe en: ${sourceApk.absolutePath}!")
        }
    }
}