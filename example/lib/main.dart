import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wallpaper_setter/wallpaper_setter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _WallpaperItem {
  const _WallpaperItem(this.title, this.url);
  final String title;
  final String? url;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_WallpaperItem> _items = const [
    _WallpaperItem(
      'Nature',
      'https://img.freepik.com/free-photo/'
          'gorgeous-view-calm-lake-surrounded-by-mountains-daylight_181624-48879.jpg',
    ),
    _WallpaperItem(
      'Mountains',
      'https://img.freepik.com/free-photo/'
          'majestic-mountain-peak-tranquil-wilderness-scenery-generative-ai_188544-9950.jpg',
    ),
    _WallpaperItem(
      'Grand Teton',
      'https://img.freepik.com/free-photo/'
          'beautiful-landscape-grand-teton-national-park-wyoming-united-states_181624-60981.jpg',
    ),
    _WallpaperItem(
      'Patagonia',
      'https://img.freepik.com/free-photo/'
          'breathtaking-view-snowy-mountains-cloudy-sky-patagonia-chile_181624-9696.jpg',
    ),
    _WallpaperItem(
      'Bamboo',
      'https://img.freepik.com/free-photo/'
          'beautiful-landscape-bamboo-grove-forest-arashiyama-kyoto_74190-16.jpg',
    ),
    _WallpaperItem(
      'Beach',
      'https://img.freepik.com/free-photo/tropical-beach-ocean-paradise_1203-2044.jpg',
    ),
    _WallpaperItem(
      'Starry Night',
      'https://img.freepik.com/free-photo/starry-sky-night-mountain-landscape_1048-2670.jpg',
    ),
    _WallpaperItem(
      'Milky Way',
      'https://img.freepik.com/free-photo/milky-way-night-sky-stars_1048-4658.jpg',
    ),
    _WallpaperItem(
      'Sunset',
      'https://img.freepik.com/free-photo/'
          'purple-sunset-mountain-illustration_23-2148743473.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Wallpaper')),
      body: FutureBuilder<WallpaperCapabilities>(
        future: WallpaperPlugin.getCapabilities(),
        builder: (context, snapshot) {
          final caps = snapshot.data ?? WallpaperCapabilities.none;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _LocalFileCard(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PreviewScreen(
                                capabilities: caps,
                                isLocal: true,
                              ),
                        ),
                      ),
                );
              }
              final item = _items[index - 1];
              return _NetworkCard(
                item: item,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PreviewScreen(
                              url: item.url!,
                              capabilities: caps,
                            ),
                      ),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LocalFileCard extends StatelessWidget {
  const _LocalFileCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.sd_storage, size: 48, color: Colors.deepPurple),
            SizedBox(height: 8),
            Text('Demo File'),
          ],
        ),
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  const _NetworkCard({required this.item, required this.onTap});
  final _WallpaperItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GridTile(
        footer: GridTileBar(
          backgroundColor: Colors.black54,
          title: Text(item.title),
        ),
        child: Image.network(
          item.url!,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => const ColoredBox(
                color: Colors.black26,
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
        ),
      ),
    );
  }
}

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    this.url,
    required this.capabilities,
    this.isLocal = false,
  }) : assert(url != null || isLocal);

  final String? url;
  final WallpaperCapabilities capabilities;

  /// When true, the bundled `assets/demo_wallpaper.png` is used as the source.
  final bool isLocal;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final GlobalKey previewContainer = GlobalKey();
  bool _loading = false;
  Uint8List? _localBytes;

  @override
  void initState() {
    super.initState();
    if (widget.isLocal) {
      _loadLocalBytes();
    }
  }

  Future<void> _loadLocalBytes() async {
    final data = await rootBundle.load('assets/demo_wallpaper.png');
    if (!mounted) return;
    setState(() => _localBytes = data.buffer.asUint8List());
  }

  ImageProvider? get _imageProvider {
    if (widget.isLocal) {
      final bytes = _localBytes;
      if (bytes == null) return null;
      return MemoryImage(bytes);
    }
    return NetworkImage(widget.url!);
  }

  Future<void> _run(
    Future<WallpaperResult> Function() action,
    String successMessage,
  ) async {
    setState(() => _loading = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _loading = false);

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? successMessage)),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${result.message ?? 'Failed'}: ${result.error?.name}'),
        ),
      );
    }
  }

  Future<void> _setFromRepaintBoundary(WallpaperTarget target) {
    return _run(
      () => WallpaperPlugin.setWallpaperFromRepaintBoundary(
        previewContainer,
        target,
      ),
      'Wallpaper set!',
    );
  }

  Future<void> _setFromUrl() {
    final url = widget.url;
    if (url == null) return Future.value();
    return _run(
      () => WallpaperPlugin.setWallpaperFromUrl(url, WallpaperTarget.both),
      'Wallpaper set from URL!',
    );
  }

  Future<void> _setFromFile() async {
    final data = await rootBundle.load('assets/demo_wallpaper.png');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/demo_wallpaper.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return _run(
      () => WallpaperPlugin.setWallpaperFromFile(file, WallpaperTarget.home),
      'Wallpaper set from file!',
    );
  }

  Future<void> _useAs() {
    return _run(
      () => WallpaperPlugin.useAsImageFromRepaintBoundary(previewContainer),
      'Sharing launched!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSet = widget.capabilities.supportsWallpaperSetting;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: previewContainer,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(
                  child:
                      _imageProvider == null
                          ? const Center(child: CircularProgressIndicator())
                          : PhotoView(
                            imageProvider: _imageProvider!,
                            backgroundDecoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2,
                          ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canSet) ...[
                          ElevatedButton(
                            onPressed:
                                () => _setFromRepaintBoundary(
                                  WallpaperTarget.home,
                                ),
                            child: const Text('Set as Home Screen'),
                          ),
                          const SizedBox(height: 8),
                          if (widget.capabilities.supportsLock)
                            ElevatedButton(
                              onPressed:
                                  () => _setFromRepaintBoundary(
                                    WallpaperTarget.lock,
                                  ),
                              child: const Text('Set as Lock Screen'),
                            ),
                          if (widget.capabilities.supportsBoth) ...[
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed:
                                  () => _setFromRepaintBoundary(
                                    WallpaperTarget.both,
                                  ),
                              child: const Text('Set Both'),
                            ),
                          ],
                          if (widget.url != null) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _setFromUrl,
                              icon: const Icon(Icons.link),
                              label: const Text('Set from URL (Both)'),
                            ),
                          ],
                          if (widget.isLocal) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _setFromFile,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Set from File (Home)'),
                            ),
                          ],
                          const SizedBox(height: 10),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Wallpaper cannot be set programmatically on this platform. '
                              'Use the share option below.',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        ElevatedButton.icon(
                          onPressed: _useAs,
                          icon: const Icon(Icons.share),
                          label: const Text('Use As...'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
