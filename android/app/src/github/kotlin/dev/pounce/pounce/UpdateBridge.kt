package dev.pounce.pounce

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * GitHub/F-Droid build: the updater module downloads the APK itself (after consent, SHA-256 checked);
 * here it's only handed to the system installer. The user confirms the installation.
 */
class UpdateBridge(private val activity: Activity, messenger: BinaryMessenger) {
    init {
        MethodChannel(messenger, "pounce/updates").setMethodCallHandler { call, result ->
            when (call.method) {
                "store" -> result.success("github")
                "app" -> result.success(
                    mapOf(
                        "store" to "github",
                        "version" to activity.packageManager.getPackageInfo(activity.packageName, 0).versionName,
                    )
                )
                "canInstall" -> result.success(
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.O || activity.packageManager.canRequestPackageInstalls()
                )
                "allowInstall" -> {
                    activity.startActivity(
                        Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}"))
                    )
                    result.success(null)
                }
                "install" -> {
                    val file = File(call.arguments as String)
                    val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
                    activity.startActivity(
                        Intent(Intent.ACTION_VIEW)
                            .setDataAndType(uri, "application/vnd.android.package-archive")
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
