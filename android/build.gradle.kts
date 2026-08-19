allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val applyNamespace = {
        val android = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android != null) {
            android.compileSdkVersion(34)
            if (name.contains("flutter_bluetooth_serial")) {
                android.namespace = "io.github.edufolly.flutterbluetoothserial"
            } else if (android.namespace == null) {
                android.namespace = "com.example." + name.replace('-', '_')
            }
        }
        val manifestFile = file("src/main/AndroidManifest.xml")
        if (manifestFile.exists()) {
            val content = manifestFile.readText()
            if (content.contains("package=")) {
                val updated = content.replace(Regex("""package="[^"]*""""), "")
                manifestFile.writeText(updated)
            }
        }
    }
    if (state.executed) {
        applyNamespace()
    } else {
        afterEvaluate { applyNamespace() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
