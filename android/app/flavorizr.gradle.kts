import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("combined") {
            dimension = "flavor-type"
            applicationId = "com.altherat.lurk"
            resValue(type = "string", name = "app_name", value = "Lurk")
        }
        create("reddit") {
            dimension = "flavor-type"
            applicationId = "com.altherat.lurk.reddit"
            resValue(type = "string", name = "app_name", value = "Lurk Reddit")
        }
        create("digg") {
            dimension = "flavor-type"
            applicationId = "com.altherat.lurk.digg"
            resValue(type = "string", name = "app_name", value = "Lurk Digg")
        }
        create("lemmy") {
            dimension = "flavor-type"
            applicationId = "com.altherat.lurk.lemmy"
            resValue(type = "string", name = "app_name", value = "Lurk Lemmy")
        }
    }
}