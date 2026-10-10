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

subprojects {
    val configureCompileSdk = Action<Project> {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val compileSdkVersionMethod = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                compileSdkVersionMethod.invoke(android, 36)
            } catch (e: Exception) {
                try {
                    val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdkVersion.invoke(android, 36)
                } catch (e2: Exception) {
                    try {
                        val setCompileSdk = android.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                        setCompileSdk.invoke(android, 36)
                    } catch (e3: Exception) {
                        // ignore
                    }
                }
            }
        }
    }
    if (state.executed) {
        configureCompileSdk.execute(this)
    } else {
        afterEvaluate {
            configureCompileSdk.execute(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
