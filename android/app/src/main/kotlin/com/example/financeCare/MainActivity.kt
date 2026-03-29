package com.example.financeCare

import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager.LayoutParams
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.financeCare/slip_detector"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        channel.setMethodCallHandler { call, result ->
            if (call.method == "scanPastImages") {
                val days = call.argument<Int>("days") ?: 10
                val paths = getPastImages(days)
                result.success(paths)
            } else {
                result.notImplemented()
            }
        }

        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                
                // Query the latest image added to MediaStore
                val projection = arrayOf(MediaStore.Images.Media.DATA)
                val cursor = contentResolver.query(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    projection,
                    null,
                    null,
                    "${MediaStore.Images.Media.DATE_ADDED} DESC"
                )
                
                cursor?.use {
                    if (it.moveToFirst()) {
                        val filePath = it.getString(it.getColumnIndexOrThrow(MediaStore.Images.Media.DATA))
                        // Notify Flutter side
                        channel.invokeMethod("onNewImage", filePath)
                    }
                }
            }
        }

        // Register the observer for images
        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            observer
        )
    }

    private fun getPastImages(days: Int): List<String> {
        val paths = mutableListOf<String>()
        val secondsAgo = System.currentTimeMillis() / 1000 - (days * 24 * 60 * 60)
        
        val projection = arrayOf(MediaStore.Images.Media.DATA)
        val selection = "${MediaStore.Images.Media.DATE_ADDED} >= ?"
        val selectionArgs = arrayOf(secondsAgo.toString())
        
        contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            "${MediaStore.Images.Media.DATE_ADDED} DESC"
        )?.use { cursor ->
            val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            while (cursor.moveToNext()) {
                val path = cursor.getString(dataColumn)
                paths.add(path)
            }
        }
        return paths
    }
}
