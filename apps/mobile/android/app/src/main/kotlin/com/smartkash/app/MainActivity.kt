package com.smartkash.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "smartkash/files"
    private val createDocumentRequestCode = 8150
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePngToDownloads" -> {
                    val fileName = call.argument<String>("fileName") ?: "smartkash-qr.png"
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("EMPTY_FILE", "QR image bytes are empty.", null)
                        return@setMethodCallHandler
                    }
                    if (pendingResult != null) {
                        result.error("SAVE_IN_PROGRESS", "Another save request is already open.", null)
                        return@setMethodCallHandler
                    }

                    pendingResult = result
                    pendingBytes = bytes
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "image/png"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                    startActivityForResult(intent, createDocumentRequestCode)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != createDocumentRequestCode) {
            return
        }

        val result = pendingResult
        val bytes = pendingBytes
        pendingResult = null
        pendingBytes = null

        if (result == null) {
            return
        }

        if (resultCode != Activity.RESULT_OK) {
            result.error("SAVE_CANCELLED", "QR save was cancelled.", null)
            return
        }

        val uri: Uri? = data?.data
        if (uri == null || bytes == null) {
            result.error("SAVE_FAILED", "No save location was selected.", null)
            return
        }

        try {
            contentResolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            } ?: run {
                result.error("SAVE_FAILED", "Could not open selected file.", null)
                return
            }
            result.success(true)
        } catch (exception: Exception) {
            result.error("SAVE_FAILED", exception.message ?: "Could not save QR image.", null)
        }
    }
}
