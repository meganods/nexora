import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = File("C:/Users/Vishal/AppData/Local/Temp/urban_company_builds/urbanuser")
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
