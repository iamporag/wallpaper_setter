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
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.security.AccessControlException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.roundToInt

class WallpaperSetterPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activityContext: Context? = null
    private lateinit var incomingChannel: MethodChannel
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.iamporag/wallpaper")
        channel.setMethodCallHandler(this)
        incomingChannel = MethodChannel(binding.binaryMessenger, "com.iamporag/wallpaper_incoming")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityContext = binding.activity
        binding.activity.intent?.let { forwardIncomingIntent(it) }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityContext = binding.activity
        binding.activity.intent?.let { forwardIncomingIntent(it) }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityContext = null
    }

    override fun onDetachedFromActivity() {
        activityContext = null
    }

    /**
     * Called by the host Activity to deliver an incoming "Use as → Wallpaper"
     * intent after a recreation (cold start) or while already running (warm
     * start via onNewIntent). Called on the main thread after the engine is
     * attached, so the channel exists; if it does not yet exist the URI is
     * buffered until the engine is attached.
     */
    private var pendingIncomingUri: String? = null

    fun forwardIncomingIntent(intent: Intent) {
        val uri = extractImageUri(intent) ?: return
        pendingIncomingUri = uri.toString()
        // If the Dart handler is already registered we can deliver immediately;
        // otherwise it will be picked up when Dart registers / polls.
        if (::incomingChannel.isInitialized) {
            incomingChannel.invokeMethod("incomingImage", pendingIncomingUri)
        }
    }

    /** Returns and clears the most recent incoming image URI, or null. */
    fun consumePendingIncomingUri(): String? {
        val uri = pendingIncomingUri
        pendingIncomingUri = null
        return uri
    }

    /**
     * Extracts the image URI from any of the standard intent carriers an
     * external gallery/wallpaper app may use: the data URI, EXTRA_STREAM, or
     * ClipData. Returns null if none carry an image.
     */
    private fun extractImageUri(intent: Intent?): Uri? {
        if (intent == null) return null
        val type = intent.type
        val isImage = type == null || type.startsWith("image/")

        if (isImage) {
            intent.data?.let { return it }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                intent.clipData?.let { clip ->
                    for (i in 0 until clip.itemCount) {
                        val itemUri = clip.getItemAt(i).uri
                        if (itemUri != null) return itemUri
                    }
                }
            }
        }
        val stream = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        if (stream != null) return stream
        return null
    }

    companion object {
        /** Sentinel used by the example Activity to locate this plugin. */
        const val TAG = "WallpaperSetterPlugin"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setWallpaper" -> handleSetWallpaper(call, result)
            "setWallpaperFromUri" -> handleSetWallpaperFromUri(call, result)
            "getImageBytesFromUri" -> handleGetImageBytesFromUri(call, result)
            "getPendingIncomingImage" ->
                result.success(consumePendingIncomingUri())
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

        executor.execute {
            val bitmap = loadBitmap(path) ?: run {
                postResult(result, errorMap("invalidImage", "Unable to decode image"))
                return@execute
            }
            applyBitmapWallpaper(bitmap, target, fit, result)
        }
    }

    private fun handleSetWallpaperFromUri(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        val target = call.argument<String>("target")
        val fit = call.argument<String>("fit")

        if (uriString == null) {
            result.success(errorMap("invalidImage", "Image URI is null"))
            return
        }

        val uri = try {
            Uri.parse(uriString)
        } catch (e: Exception) {
            result.success(errorMap("invalidImage", "Malformed image URI"))
            return
        }

        executor.execute {
            val bitmap = loadBitmapFromUri(uri) ?: run {
                postResult(result, errorMap("invalidImage", "Unable to decode image from URI"))
                return@execute
            }

            applyBitmapWallpaper(bitmap, target, fit, result)
        }
    }

    private fun handleGetImageBytesFromUri(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.success(null)
            return
        }

        val uri = Uri.parse(uriString)
        executor.execute {
            val bytes = readBytesFromUri(uri)
            postResult(result, bytes)
        }
    }

    /**
     * Reads the encoded bytes of an image referenced by a `content://` URI via
     * the ContentResolver. Returns `null` if the URI cannot be opened (e.g. the
     * sending app's read-URI grant has expired). Runs on the background executor
     * so large images do not block the UI thread.
     */
    private fun readBytesFromUri(uri: Uri): ByteArray? {
        return try {
            var input: InputStream? = null
            try {
                input = context.contentResolver.openInputStream(uri) ?: return null
                input.readBytes()
            } finally {
                try {
                    input?.close()
                } catch (_: IOException) {
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun applyBitmapWallpaper(
        bitmap: Bitmap,
        target: String?,
        fit: String?,
        result: MethodChannel.Result,
    ) {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N && target != null && target != "home") {
                postResult(result, errorMap("unsupported", "Lock screen wallpaper requires Android 7.0+"))
                return
            }

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

            postResult(result, successMap("Wallpaper set successfully."))
        } catch (e: SecurityException) {
            postResult(result, errorMap("permissionDenied", "Permission denied: ${e.message}"))
        } catch (e: IOException) {
            postResult(result, errorMap("platformError", "Failed to set wallpaper: ${e.message}"))
        } catch (e: AccessControlException) {
            postResult(result, errorMap("permissionDenied", "Permission denied: ${e.message}"))
        } catch (e: OutOfMemoryError) {
            // OutOfMemoryError is an Error, not an Exception, so it must be
            // caught explicitly to avoid crashing the process on low-memory
            // devices when a large wallpaper image is decoded.
            postResult(result, errorMap("platformError", "Insufficient memory to set wallpaper"))
        } catch (e: Exception) {
            postResult(result, errorMap("platformError", "Unexpected error: ${e.message}"))
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

            val chooser = Intent.createChooser(intent, "Use image as").apply {
                putExtra(
                    Intent.EXTRA_EXCLUDE_COMPONENTS,
                    arrayOf(
                        android.content.ComponentName(
                            context,
                            "${context.packageName}.MainActivity",
                        ),
                    ),
                )
            }

            // Launch from the current Activity context *without*
            // FLAG_ACTIVITY_NEW_TASK so Android keeps the app's task/back stack
            // and returns to the previous Flutter screen after the user picks a
            // wallpaper. Launching from the bare applicationContext with
            // NEW_TASK destroys/resets the activity stack, which makes the app
            // appear to restart and lose its previous screen.
            val launchContext = activityContext ?: context
            if (launchContext == context) {
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            launchContext.startActivity(chooser)

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
            decodeSampledBitmap { options ->
                BitmapFactory.decodeFile(path, options)
            }
        } catch (e: OutOfMemoryError) {
            null
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Decodes an image referenced by a `content://` URI (as delivered by an
     * external "Use as → Wallpaper" intent). Opens the stream through the
     * ContentResolver and never converts the URI to a filesystem path. If the
     * read-URI grant from the sending app has already expired, this returns
     * `null` and the caller reports an invalid-image error.
     */
    private fun loadBitmapFromUri(uri: Uri): Bitmap? {
        return try {
            decodeSampledBitmap { options ->
                var input: InputStream? = null
                try {
                    input = context.contentResolver.openInputStream(uri) ?: return@decodeSampledBitmap null
                    BitmapFactory.decodeStream(input, null, options)
                } finally {
                    try {
                        input?.close()
                    } catch (_: IOException) {
                    }
                }
            }
        } catch (e: OutOfMemoryError) {
            null
        } catch (e: Exception) {
            null
        }
    }

    /** Decodes via [decode] after first sampling-down to bound memory usage. */
    private fun decodeSampledBitmap(decode: (BitmapFactory.Options) -> Bitmap?): Bitmap? {
        val maxWidth = context.resources.displayMetrics.widthPixels * 2
        val maxHeight = context.resources.displayMetrics.heightPixels * 2

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        decode(bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sample = 1
        while (bounds.outWidth / (sample * 2) >= maxWidth &&
            bounds.outHeight / (sample * 2) >= maxHeight
        ) {
            sample *= 2
        }

        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        return decode(options)
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

    /**
     * Delivers a `MethodChannel.Result` on the Android main thread. Methods that
     * run on [executor] must use this instead of calling `result.success`
     * directly, because Flutter requires channel callbacks on the platform
     * thread.
     */
    private fun postResult(result: MethodChannel.Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }

    private fun successMap(message: String): Map<String, Any> =
        mapOf("isSuccess" to true, "message" to message)

    private fun errorMap(code: String, message: String): Map<String, Any> =
        mapOf("isSuccess" to false, "error" to code, "message" to message)

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        activityContext = null
        pendingIncomingUri = null
        executor.shutdown()
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