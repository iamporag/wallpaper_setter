Pod::Spec.new do |s|
  s.name             = 'wallpaper_setter'
  s.version          = '2.0.0'
  s.summary          = 'A Flutter plugin for setting device wallpapers and using images.'
  s.description      = <<-DESC
A Flutter plugin for setting wallpapers (Android) and sharing/using images (iOS).
                       DESC
  s.homepage         = 'https://github.com/iamporag/wallpaper_setter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'iamporag' => 'iamporag@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'wallpaper_setter/Sources/wallpaper_setter/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # See Package.swift: the privacy manifest travels with the plugin's Swift
  # sources so both CocoaPods and Swift Package Manager consumers get it.
  s.resource_bundles = {
    'wallpaper_setter_privacy' => ['wallpaper_setter/Sources/wallpaper_setter/PrivacyInfo.xcprivacy']
  }
end
