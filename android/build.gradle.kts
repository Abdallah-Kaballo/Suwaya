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
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            
            // 1. 🟢 إصلاح مشكلة الـ Namespace
            try {
                val getNamespace = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" }
                val setNamespace = androidExt.javaClass.methods.firstOrNull { 
                    it.name == "setNamespace" && it.parameterTypes.size == 1 && it.parameterTypes[0].name == "java.lang.String" 
                }
                if (getNamespace != null && setNamespace != null) {
                    val currentNamespace = getNamespace.invoke(androidExt)
                    if (currentNamespace == null) {
                        setNamespace.invoke(androidExt, "dev.isar." + project.name.replace("-", "_"))
                    }
                }
            } catch (e: Exception) {}

            // 2. 🟢 الحل الجذري المضاد للرصاص لإجبار Isar على الترقية لـ SDK 36
            try {
                val setCompileSdk = androidExt.javaClass.methods.firstOrNull { 
                    (it.name == "setCompileSdk" || it.name == "setCompileSdkVersion") && 
                    it.parameterTypes.size == 1 && 
                    (it.parameterTypes[0].name == "int" || it.parameterTypes[0].name == "java.lang.Integer")
                }
                
                if (setCompileSdk != null) {
                    setCompileSdk.invoke(androidExt, 36) // إجبار الترقية
                }
            } catch (e: Exception) {
                println("SUWAYA WARNING: Failed to update compileSdk for ${project.name}")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}