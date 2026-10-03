package dev.pounce.pounce

import android.app.Activity
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Play build: updates exclusively via Google's in-app update API (no own download).
 * Channel "pounce/updates": check → {available, versionCode}, start → launches the Play dialog.
 */
class UpdateBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val manager = AppUpdateManagerFactory.create(activity)

    init {
        MethodChannel(messenger, "pounce/updates").setMethodCallHandler { call, result ->
            when (call.method) {
                "store" -> result.success("play")
                "app" -> result.success(
                    mapOf(
                        "store" to "play",
                        "version" to activity.packageManager.getPackageInfo(activity.packageName, 0).versionName,
                    )
                )
                "check" -> manager.appUpdateInfo
                    .addOnSuccessListener { info ->
                        result.success(
                            mapOf(
                                "available" to (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE),
                                "versionCode" to info.availableVersionCode(),
                            )
                        )
                    }
                    .addOnFailureListener { result.success(mapOf("available" to false)) }
                "start" -> manager.appUpdateInfo
                    .addOnSuccessListener { info ->
                        val options = AppUpdateOptions.defaultOptions(AppUpdateType.FLEXIBLE)
                        manager.startUpdateFlow(info, activity, options)
                        result.success(true)
                    }
                    .addOnFailureListener { result.success(false) }
                else -> result.notImplemented()
            }
        }
    }
}
