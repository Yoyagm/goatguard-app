package com.goatguard.goatguard_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.goatguard.goatguard_app/notifications"
        ).setMethodCallHandler { call, result ->
            if (call.method == "createNotificationChannel") {
                val id = call.argument<String>("id") ?: "default"
                val name = call.argument<String>("name") ?: "Default"
                val desc = call.argument<String>("description") ?: ""
                val importance = call.argument<Int>("importance")
                    ?: NotificationManager.IMPORTANCE_HIGH

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val channel = NotificationChannel(id, name, importance).apply {
                        description = desc
                        enableVibration(true)
                    }
                    val manager = getSystemService(NotificationManager::class.java)
                    manager.createNotificationChannel(channel)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
