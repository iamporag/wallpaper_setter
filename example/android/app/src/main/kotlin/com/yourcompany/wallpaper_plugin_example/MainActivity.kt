package com.yourcompany.wallpaper_plugin_example

import android.content.Intent
import com.iamporag.wallpaper_setter.WallpaperSetterPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var plugin: WallpaperSetterPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        plugin = flutterEngine.plugins.get(WallpaperSetterPlugin::class.java)
            as? WallpaperSetterPlugin
        // Cold start: the incoming intent was delivered to onCreate before the
        // engine was configured. Hand it to the plugin now that it's ready.
        plugin?.forwardIncomingIntent(intent)
    }

    // Warm start / singleTop: the activity is already running when a new
    // "Use as → Wallpaper" intent arrives (the app was in the background or
    // already on top). onNewIntent delivers it without recreating the activity.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        plugin?.forwardIncomingIntent(intent)
    }
}
