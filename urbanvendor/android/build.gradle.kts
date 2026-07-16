import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val flutterProjectRoot = if (rootProject.projectDir.name == "android") rootProject.projectDir.parentFile else rootProject.projectDir
val newBuildDir = File(flutterProjectRoot, "build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val subBuildDir = File(newBuildDir, project.name)
    project.layout.buildDirectory.set(subBuildDir)
    
    if (project.name != "app") {
        evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
