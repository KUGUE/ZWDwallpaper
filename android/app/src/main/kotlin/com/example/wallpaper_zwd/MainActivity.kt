package com.example.wallpaper_zwd

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "zwallpaper/wallpaper"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setLockScreenWallpaper") {
                val path = call.argument<String>("filePath")
                if (path != null) {
                    val file = File(path)
                    if (file.exists()) {
                        try {
                            val bitmap = BitmapFactory.decodeStream(FileInputStream(file))
                            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                                result.success(true)
                            } else {
                                result.error("UNSUPPORTED", "Solo Android 7.0+ soporta lockscreen", null)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("NOT_FOUND", "Archivo no encontrado", null)
                    }
                } else {
                    result.error("NO_PATH", "Ruta no proporcionada", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
