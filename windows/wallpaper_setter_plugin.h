#ifndef FLUTTER_PLUGIN_WALLPAPER_SETTER_PLUGIN_H_
#define FLUTTER_PLUGIN_WALLPAPER_SETTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace wallpaper_setter {

class WallpaperSetterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WallpaperSetterPlugin();

  virtual ~WallpaperSetterPlugin();

  // Disallow copy and assign.
  WallpaperSetterPlugin(const WallpaperSetterPlugin&) = delete;
  WallpaperSetterPlugin& operator=(const WallpaperSetterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace wallpaper_setter

#endif  // FLUTTER_PLUGIN_WALLPAPER_SETTER_PLUGIN_H_
