import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.applifylab.ai_chat_app.dev"
            resValue(type = "string", name = "app_name", value = "Ai Chat App Dev")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.applifylab.ai_chat_app"
            resValue(type = "string", name = "app_name", value = "Ai Chat App")
        }
    }
}