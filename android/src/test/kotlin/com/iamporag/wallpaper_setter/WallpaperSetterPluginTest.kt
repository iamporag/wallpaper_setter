package com.iamporag.wallpaper_setter

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import org.mockito.ArgumentCaptor
import org.mockito.Mockito

class WallpaperSetterPluginTest {

    private fun successResult(plugin: WallpaperSetterPlugin, call: MethodCall): Map<*, *> {
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        val captor = ArgumentCaptor.forClass(Any::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success(captor.capture())
        return captor.value as Map<*, *>
    }

    @Test
    fun getCapabilities_returnsHomeSupport() {
        val plugin = WallpaperSetterPlugin()
        val result = successResult(plugin, MethodCall("getCapabilities", null))

        assertTrue(result["home"] == true)
        assertTrue(result["capturedWidget"] == true)
        assertTrue(result["directImageSources"] == true)
    }

    @Test
    fun unknownMethod_returnsNotImplemented() {
        val plugin = WallpaperSetterPlugin()
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(MethodCall("unknown", null), mockResult)

        Mockito.verify(mockResult).notImplemented()
    }

    @Test
    fun setWallpaper_withNullPath_returnsInvalidImage() {
        val plugin = WallpaperSetterPlugin()
        val result =
            successResult(
                plugin,
                MethodCall("setWallpaper", mapOf("target" to "home")),
            )

        assertEquals(false, result["isSuccess"])
        assertEquals("invalidImage", result["error"])
    }

    @Test
    fun setWallpaper_withMissingFile_returnsFileError() {
        val plugin = WallpaperSetterPlugin()
        val result =
            successResult(
                plugin,
                MethodCall(
                    "setWallpaper",
                    mapOf("path" to "/nonexistent/does_not_exist.png", "target" to "home"),
                ),
            )

        assertEquals(false, result["isSuccess"])
        assertEquals("fileError", result["error"])
    }

    @Test
    fun setWallpaper_withUndecodableFile_returnsInvalidImage() {
        val temp = File.createTempFile("wallpaper_test", ".bin")
        try {
            temp.writeBytes(byteArrayOf(1, 2, 3, 4, 5))

            val plugin = WallpaperSetterPlugin()
            val result =
                successResult(
                    plugin,
                    MethodCall(
                        "setWallpaper",
                        mapOf("path" to temp.absolutePath, "target" to "home"),
                    ),
                )

            assertEquals(false, result["isSuccess"])
            assertEquals("invalidImage", result["error"])
        } finally {
            temp.delete()
        }
    }

    @Test
    fun coverCrop_cropsWideSourceToPortraitTarget() {
        val area =
            WallpaperTransformer.coverCropArea(
                WallpaperTransformer.Size(2000, 1000),
                WallpaperTransformer.Size(1000, 2000),
            )

        // scale = max(1000/2000, 2000/1000) = 2 => keep 500x1000 centered.
        assertEquals(750, area.left)
        assertEquals(0, area.top)
        assertEquals(1250, area.right)
        assertEquals(1000, area.bottom)
    }

    @Test
    fun coverCrop_identicalAspectKeepsFullSource() {
        val area =
            WallpaperTransformer.coverCropArea(
                WallpaperTransformer.Size(1000, 2000),
                WallpaperTransformer.Size(500, 1000),
            )

        assertEquals(0, area.left)
        assertEquals(0, area.top)
        assertEquals(1000, area.right)
        assertEquals(2000, area.bottom)
    }

    @Test
    fun containSize_sameAspectScalesToFitTarget() {
        val size =
            WallpaperTransformer.containSize(
                WallpaperTransformer.Size(900, 1600),
                WallpaperTransformer.Size(1000, 2000),
            )

        assertEquals(1000, size.width)
        assertEquals(1778, size.height)
    }

    @Test
    fun containSize_wideSourceIsWidthLimited() {
        val size =
            WallpaperTransformer.containSize(
                WallpaperTransformer.Size(2000, 1000),
                WallpaperTransformer.Size(1000, 2000),
            )

        assertEquals(1000, size.width)
        assertEquals(500, size.height)
    }
}
