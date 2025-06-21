# wallpaper_plugin

[![Pub Version](https://img.shields.io/pub/v/wallpaper_plugin.svg)](https://pub.dev/packages/wallpaper_plugin)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter Compatibility](https://img.shields.io/badge/flutter-%3E%3D1.20.0-blue)](https://flutter.dev)

A Flutter plugin for setting device wallpapers on both Android and iOS platforms with simple, intuitive APIs.

## Features

- Set wallpaper for home screen
- Set wallpaper for lock screen (Android only)
- Set wallpaper for both screens simultaneously (Android only)
- Supports common image formats (JPEG, PNG)
- Returns detailed success/error messages
- Handles platform-specific requirements automatically

## Installation

Add this to your project's `pubspec.yaml` file:

```yaml
dependencies:
  wallpaper_plugin: ^1.0.0

Then run the following command:
  flutter pub get

How to Use:
 Read Documentation

Platform Setup:
 - Android
Add these permissions to your AndroidManifest.xml:
<uses-permission android:name="android.permission.SET_WALLPAPER"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/file_paths" />
        </provider>


#Create xml File 
android\app\src\main\res\xml\file_paths.xml

<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <cache-path
        name="cache"
        path="." />
    <external-path
        name="external_files"
        path="." />
    <external-files-path
        name="external_files"
        path="." />
    <files-path
        name="files"
        path="." />
</paths>


flutter clean
flutter pub get
flutter run

😍😍😍😍😍