package com.iamporag.wallpaper_setter

import android.app.WallpaperManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.security.AccessControlException
import kotlin.math.roundToInt

class WallpaperSetterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.iamporag/wallpaper")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setWallpaper" -> handleSetWallpaper(call, result)
            "useAsImage" -> handleUseAsImage(call, result)
            "getCapabilities" -> handleGetCapabilities(result)
            "getScreenInfo" -> handleGetScreenInfo(result)
            else -> result.notImplemented()
        }
    }

    private fun handleGetCapabilities(result: MethodChannel.Result) {
        val supportsLock = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N
        result.success(
            mapOf(
                "home" to true,
                "lock" to supportsLock,
                "both" to supportsLock,
                "capturedWidget" to true,
                "directImageSources" to true,
            )
        )
    }

    private fun handleGetScreenInfo(result: MethodChannel.Result) {
        val metrics = context.resources.displayMetrics
        result.success(
            mapOf(
                "width" to metrics.widthPixels.toDouble(),
                "height" to metrics.heightPixels.toDouble(),
                "pixelDensity" to metrics.density.toDouble(),
                "orientation" to
                    if (metrics.widthPixels > metrics.heightPixels) "landscape" else "portrait",
            )
        )
    }

    private fun handleSetWallpaper(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val target = call.argument<String>("target")
        val fit = call.argument<String>("fit")

        if (path == null) {
            result.success(errorMap("invalidImage", "Image path is null"))
            return
        }

        val file = File(path)
        if (!file.exists()) {
            result.success(errorMap("fileError", "Wallpaper image file does not exist"))
            return
        }

        val bitmap = loadBitmap(path) ?: run {
            result.success(errorMap("invalidImage", "Unable to decode image"))
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N && target != null && target != "home") {
            result.success(errorMap("unsupported", "Lock screen wallpaper requires Android 7.0+"))
            return
        }

        try {
            val wallpaperManager = WallpaperManager.getInstance(context)
            val flag = when (target) {
                "lock" -> WallpaperManager.FLAG_LOCK
                "both" -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                else -> WallpaperManager.FLAG_SYSTEM
            }

            val applied = if (fit == null) bitmap else scaleForFit(fit, bitmap)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    wallpaperManager.setBitmap(applied, null, true, flag)
                } else {
                    wallpaperManager.setBitmap(applied)
                }
            } finally {
                // Free any scaled intermediate produced by [scaleForFit] and
                // the decoded source bitmap. WallpaperManager serializes the
                // image before returning, so it is safe to recycle afterwards.
                if (applied !== bitmap) applied.recycle()
                bitmap.recycle()
            }

            result.success(successMap("Wallpaper set successfully."))
        } catch (e: SecurityException) {
            result.success(errorMap("permissionDenied", "Permission denied: ${e.message}"))
        } catch (e: IOException) {
            result.success(errorMap("platformError", "Failed to set wallpaper: ${e.message}"))
        } catch (e: AccessControlException) {
            result.success(errorMap("permissionDenied", "Permission denied: ${e.message}"))
        } catch (e: OutOfMemoryError) {
            // OutOfMemoryError is an Error, not an Exception, so it must be
            // caught explicitly to avoid crashing the process on low-memory
            // devices when a large wallpaper image is decoded.
            result.success(errorMap("platformError", "Insufficient memory to set wallpaper"))
        } catch (e: Exception) {
            result.success(errorMap("platformError", "Unexpected error: ${e.message}"))
        }
    }

    private fun handleUseAsImage(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.success(errorMap("invalidImage", "Image path is null"))
            return
        }

        val imageFile = File(path)
        if (!imageFile.exists()) {
            result.success(errorMap("fileError", "Image file does not exist"))
            return
        }

        try {
            val uri: Uri = FileProvider.getUriForFile(
                context,
                context.packageName + ".wallpaper_setter.fileprovider",
                imageFile
            )

            val intent = Intent(Intent.ACTION_ATTACH_DATA).apply {
                setDataAndType(uri, "image/*")
                putExtra("mimeType", "image/*")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val chooser = Intent.createChooser(intent, "Use image as")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooser)

            result.success(successMap("Use-as launched."))
        } catch (e: Exception) {
            result.success(errorMap("platformError", "Unable to launch use-as intent: ${e.message}"))
        }
    }

    /**
     * Decodes a wallpaper image while bounding the maximum decoded size to
     * roughly twice the screen resolution. This keeps memory usage predictable
     * for very large images while preserving plenty of resolution for a
     * wallpaper. Returns `null` when the file is not a decodable image.
     */
    private fun loadBitmap(path: String): Bitmap? {
        return try {
            val maxWidth = context.resources.displayMetrics.widthPixels * 2
            val maxHeight = context.resources.displayMetrics.heightPixels * 2

            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            var sample = 1
            while (bounds.outWidth / (sample * 2) >= maxWidth &&
                bounds.outHeight / (sample * 2) >= maxHeight
            ) {
                sample *= 2
            }

            val options = BitmapFactory.Options().apply { inSampleSize = sample }
            BitmapFactory.decodeFile(path, options)
        } catch (e: OutOfMemoryError) {
            null
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Scales [source] to match the screen so it can be applied as a wallpaper
     * without distortion:
     *  - `cover`: center-crop then scale to exactly fill the screen.
     *  - `contain`: scale to fit inside the screen, letterboxing with black.
     *  - `fill`: stretch to exactly fill the screen.
     */
    private fun scaleForFit(fit: String, source: Bitmap): Bitmap {
        val metrics = context.resources.displayMetrics
        val target = WallpaperTransformer.Size(metrics.widthPixels, metrics.heightPixels)
        val sourceSize = WallpaperTransformer.Size(source.width, source.height)

        return when (fit) {
            "cover" -> {
                val crop = WallpaperTransformer.coverCropArea(sourceSize, target)
                val cropped = Bitmap.createBitmap(
                    source,
                    crop.left,
                    crop.top,
                    crop.right - crop.left,
                    crop.bottom - crop.top,
                )
                val scaled = Bitmap.createScaledBitmap(cropped, target.width, target.height, true)
                if (scaled !== cropped) cropped.recycle()
                scaled
            }
            "contain" -> {
                val size = WallpaperTransformer.containSize(sourceSize, target)
                val scaled = Bitmap.createScaledBitmap(source, size.width, size.height, true)
                val out = Bitmap.createBitmap(target.width, target.height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(out)
                canvas.drawColor(Color.BLACK)
                canvas.drawBitmap(
                    scaled,
                    (target.width - size.width) / 2f,
                    (target.height - size.height) / 2f,
                    null,
                )
                scaled.recycle()
                out
            }
            else -> Bitmap.createScaledBitmap(source, target.width, target.height, true)
        }
    }

    private fun successMap(message: String): Map<String, Any> =
        mapOf("isSuccess" to true, "message" to message)

    private fun errorMap(code: String, message: String): Map<String, Any> =
        mapOf("isSuccess" to false, "error" to code, "message" to message)

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

/**
 * Pure sizing math used to scale a wallpaper bitmap to the screen.
 *
 * Kept free of Android OS calls (it only uses plain data types) so it can be
 * exercised by plain JVM unit tests.
 */
internal object WallpaperTransformer {
    data class Size(val width: Int, val height: Int)

    /** An integer crop area. Pure data so it can be asserted in JVM tests. */
    data class CropArea(val left: Int, val top: Int, val right: Int, val bottom: Int)

    /** Aspect calculations for `cover` fit. */
    fun coverCropArea(source: Size, target: Size): CropArea {
        val scale = maxOf(target.width.toFloat() / source.width, target.height.toFloat() / source.height)
        val scaledWidth = (target.width / scale).roundToInt()
        val scaledHeight = (target.height / scale).roundToInt()
        val left = ((source.width - scaledWidth) / 2).coerceAtLeast(0)
        val top = ((source.height - scaledHeight) / 2).coerceAtLeast(0)
        return CropArea(left, top, left + scaledWidth, top + scaledHeight)
    }

    /** Size calculations for `contain` fit. */
    fun containSize(source: Size, target: Size): Size {
        val scale = minOf(target.width.toFloat() / source.width, target.height.toFloat() / source.height)
        return Size((source.width * scale).roundToInt(), (source.height * scale).roundToInt())
    }
}