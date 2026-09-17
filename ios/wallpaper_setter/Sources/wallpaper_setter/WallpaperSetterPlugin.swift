import Flutter
import UIKit

public class WallpaperSetterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.iamporag/wallpaper", binaryMessenger: registrar.messenger())
        let instance = WallpaperSetterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setWallpaper":
            // iOS does not allow third-party apps to set the wallpaper
            // programmatically. Return an explicit unsupported result instead
            // of pretending to succeed.
            result(successMap(success: false, error: "unsupported", message: "Setting a wallpaper is not supported on iOS."))
        case "useAsImage":
            if let args = call.arguments as? [String: Any],
               let path = args["path"] as? String {
                shareImage(path: path, result: result)
            } else {
                result(successMap(success: false, error: "invalidImage", message: "Missing path"))
            }
        case "getCapabilities":
            // iOS cannot set home, lock or both wallpapers programmatically, so
            // every wallpaper-setting capability is reported as unsupported.
            // (Sharing an image via `useAsImageFromRepaintBoundary` is still
            // available - it is a separate operation, not wallpaper setting.)
            result([
                "home": false,
                "lock": false,
                "both": false,
                "capturedWidget": false,
                "directImageSources": false,
            ])
        case "getScreenInfo":
            let screen = UIScreen.main
            result([
                "width": screen.bounds.width * screen.scale,
                "height": screen.bounds.height * screen.scale,
                "pixelDensity": screen.scale,
                "orientation": orientationName(),
            ])
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Returns the foreground-active `UIWindowScene`, falling back to the first
    /// connected scene. Uses the scene API instead of the deprecated
    /// `UIApplication.shared.windows` and handles multiple scenes by preferring
    /// the active one. `connectedScenes` is available from iOS 13, which is the
    /// plugin's minimum deployment target, so no availability fallback is
    /// required.
    private func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }

    /// Returns the key window of the active scene, falling back to the scene's
    /// first window. Preferring the key window avoids assuming `windows.first`
    /// is the Flutter window when a scene hosts more than one window.
    private func activeWindow() -> UIWindow? {
        guard let scene = activeWindowScene() else { return nil }
        return scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
    }

    private func orientationName() -> String {
        let orientation = activeWindowScene()?.interfaceOrientation
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            return "landscape"
        default:
            return "portrait"
        }
    }

    private func shareImage(path: String, result: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: path) else {
            result(successMap(success: false, error: "invalidImage", message: "Unable to read image"))
            return
        }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        guard let rootVC = activeWindow()?.rootViewController else {
            result(successMap(success: false, error: "platformError", message: "No root view controller found"))
            return
        }
        rootVC.present(activityVC, animated: true) {
            result(self.successMap(success: true, message: "Use-as launched."))
        }
    }

    private func successMap(success: Bool = true, error: String? = nil, message: String? = nil) -> [String: Any] {
        var map: [String: Any] = ["isSuccess": success]
        if let error = error {
            map["error"] = error
        }
        if let message = message {
            map["message"] = message
        }
        return map
    }
}
