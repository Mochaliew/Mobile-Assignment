package com.example.asgnmnt

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "asgnmnt/file_opener")
            .setMethodCallHandler { call, result ->
                if (call.method != "openFile") {
                    if (call.method == "renderPdf") {
                        renderPdf(call.argument<String>("path"), result)
                    } else {
                        result.notImplemented()
                    }
                    return@setMethodCallHandler
                }

                val path = call.argument<String>("path")
                val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                if (path.isNullOrBlank()) {
                    result.error("INVALID_PATH", "File path is missing.", null)
                    return@setMethodCallHandler
                }

                val file = File(path)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "File does not exist.", null)
                    return@setMethodCallHandler
                }

                val uri = FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, mimeType)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    clipData = ClipData.newUri(contentResolver, file.name, uri)
                }

                try {
                    val viewers = packageManager.queryIntentActivities(intent, 0)
                    viewers.forEach { viewer ->
                        grantUriPermission(
                            viewer.activityInfo.packageName,
                            uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION
                        )
                    }

                    val chooser = Intent.createChooser(intent, "Open material").apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(chooser)
                    result.success(true)
                } catch (e: ActivityNotFoundException) {
                    result.error("NO_VIEWER", "No app found to open this file.", null)
                }
            }
    }

    private fun renderPdf(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrBlank()) {
            result.error("INVALID_PATH", "File path is missing.", null)
            return
        }

        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "File does not exist.", null)
            return
        }

        try {
            val hash = MessageDigest.getInstance("MD5")
                .digest(path.toByteArray())
                .joinToString("") { "%02x".format(it) }
            val outputDir = File(cacheDir, "pdf_pages/$hash")
            if (!outputDir.exists()) outputDir.mkdirs()

            val pagePaths = mutableListOf<String>()
            ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                PdfRenderer(descriptor).use { renderer ->
                    for (index in 0 until renderer.pageCount) {
                        val pageFile = File(outputDir, "page_${index + 1}.png")
                        if (!pageFile.exists()) {
                            renderer.openPage(index).use { page ->
                                val scale = 2
                                val bitmap = Bitmap.createBitmap(
                                    page.width * scale,
                                    page.height * scale,
                                    Bitmap.Config.ARGB_8888
                                )
                                bitmap.eraseColor(Color.WHITE)
                                page.render(
                                    bitmap,
                                    null,
                                    null,
                                    PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY
                                )
                                FileOutputStream(pageFile).use { stream ->
                                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                }
                                bitmap.recycle()
                            }
                        }
                        pagePaths.add(pageFile.absolutePath)
                    }
                }
            }

            result.success(pagePaths)
        } catch (e: Exception) {
            result.error("RENDER_FAILED", e.message, null)
        }
    }
}
