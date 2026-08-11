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
    val setNdk: Project.() -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val setNdkVersion = android.javaClass.methods.firstOrNull { it.name == "setNdkVersion" && it.parameterCount == 1 }
                setNdkVersion?.invoke(android, "27.3.13750724")
            } catch (_: Exception) {
            }
        }
    }
    if (state.executed) {
        setNdk()
    } else {
        afterEvaluate { setNdk() }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
