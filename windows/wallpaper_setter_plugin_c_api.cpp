#include "include/wallpaper_setter/wallpaper_setter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "wallpaper_setter_plugin.h"

void WallpaperSetterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  wallpaper_setter::WallpaperSetterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
