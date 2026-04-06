package com.example.financeCare

import android.database.ContentObserver
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.financeCare/slip_detector"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scanPastImages" -> {
                    val days = call.argument<Int>("days") ?: 10
                    val filePaths = scanPastImages(days)
                    result.success(filePaths)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Register ContentObserver to detect new images
        registerImageObserver()
    }

    private fun scanPastImages(days: Int): List<String> {
        val filePaths = mutableListOf<String>()
        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        
        val projection = arrayOf(MediaStore.Images.Media.DATA)
        
        // Calculate timestamp for N days ago (MediaStore uses seconds for DATE_ADDED)
        val daysInMillis = TimeUnit.DAYS.toMillis(days.toLong())
        val cutoffTimeSeconds = (System.currentTimeMillis() - daysInMillis) / 1000
        
        val selection = "${MediaStore.Images.Media.DATE_ADDED} >= ?"
        val selectionArgs = arrayOf(cutoffTimeSeconds.toString())
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        try {
            contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                while (cursor.moveToNext()) {
                    val path = cursor.getString(dataColumn)
                    filePaths.add(path)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return filePaths
    }

    private fun registerImageObserver() {
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                // When a new image is added, get the latest one
                // Simple implementation: just fetch the most recent image
                val latestPath = getLatestImagePath()
                if (latestPath != null) {
                    methodChannel?.invokeMethod("onNewImage", latestPath)
                }
            }
        }
        
        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            observer
        )
    }

    private fun getLatestImagePath(): String? {
        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(MediaStore.Images.Media.DATA)
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC LIMIT 1"
        
        try {
            contentResolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                    return cursor.getString(dataColumn)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}

