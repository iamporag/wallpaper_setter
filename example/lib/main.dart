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
  late final Future<WallpaperCapabilities> _capabilitiesFuture;

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
  void initState() {
    super.initState();
    _capabilitiesFuture = WallpaperPlugin.getCapabilities();
    WallpaperPlugin.setIncomingWallpaperHandler(_onIncomingWallpaper);
  }

  @override
  void dispose() {
    WallpaperPlugin.setIncomingWallpaperHandler(null);
    super.dispose();
  }

  void _onIncomingWallpaper(String imageUri) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PreviewScreen(
              initialUri: imageUri,
              capabilities: WallpaperCapabilities(
                supportsHome: true,
                supportsLock: true,
                supportsBoth: true,
                supportsCapturedWidget: true,
                supportsDirectImageSources: true,
              ),
            ),
      ),
    );
    messenger.hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Wallpaper')),
      body: FutureBuilder<WallpaperCapabilities>(
        future: _capabilitiesFuture,
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
    this.initialUri,
    required this.capabilities,
    this.isLocal = false,
  }) : assert(url != null || isLocal || initialUri != null);

  final String? url;

  /// A `content://` URI received from an external "Use as → Wallpaper" intent.
  final String? initialUri;

  final WallpaperCapabilities capabilities;

  /// When true, the bundled `assets/demo_wallpaper.png` is used as the source.
  final bool isLocal;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with WidgetsBindingObserver {
  final GlobalKey previewContainer = GlobalKey();
  bool _loading = false;
  Uint8List? _localBytes;

  bool _useAsLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isLocal) {
      _loadLocalBytes();
    }
    if (widget.initialUri != null) {
      _pollIncomingUri();
    }
  }

  Future<void> _pollIncomingUri() async {
    // The content:// grant from the sending app is transient. Reading it as
    // soon as possible avoids losing the image if the grant expires.
    final uri = widget.initialUri;
    if (uri == null) return;
    try {
      final bytes = await _readUriBytes(uri);
      if (!mounted || bytes.isEmpty) return;
      setState(() => _localBytes = bytes);
    } catch (e) {
      debugPrint('Failed to read incoming image URI: $e');
    }
  }

  Future<Uint8List> _readUriBytes(String uri) async {
    final result = await WallpaperPlugin.getImageBytesFromUri(uri);
    if (result == null) {
      throw StateError('Could not read image from content URI');
    }
    return result;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _useAsLaunched && mounted) {
      _useAsLaunched = false;
      final messengerState = ScaffoldMessenger.maybeOf(context);
      messengerState?.showSnackBar(
        const SnackBar(content: Text('Sharing launched!')),
      );
    }
  }

  Future<void> _loadLocalBytes() async {
    final data = await rootBundle.load('assets/demo_wallpaper.png');
    if (!mounted) return;
    setState(() => _localBytes = data.buffer.asUint8List());
  }

  ImageProvider? get _imageProvider {
    final bytes = _localBytes;
    if (bytes != null) {
      return MemoryImage(bytes);
    }
    if (widget.initialUri != null) {
      // Awaiting the async read of the incoming content:// image.
      return null;
    }
    if (widget.isLocal) {
      return null;
    }
    return NetworkImage(widget.url!);
  }

  Future<void> _run(
    Future<WallpaperResult> Function() action,
    String successMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      final result = await action();
      if (!mounted) return;
      setState(() => _loading = false);

      if (result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? successMessage)),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${result.message ?? 'Failed'}: ${result.error?.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
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

  Future<void> _setFromUri() {
    final uri = widget.initialUri;
    if (uri == null) return Future.value();
    return _run(
      () => WallpaperPlugin.setWallpaperFromUri(uri, WallpaperTarget.both),
      'Wallpaper set from incoming image!',
    );
  }

  Future<void> _setFromFile() async {
    final data = await rootBundle.load('assets/demo_wallpaper.png');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/demo_wallpaper.png');
    await file.writeAsBytes(data.buffer.asUint8List());
    return _run(
      () => WallpaperPlugin.setWallpaperFromFile(file, WallpaperTarget.home),
      'Wallpaper set from file!',
    );
  }

  Future<void> _useAs() async {
    if (_loading) return; // guard against double-tap / re-entrant redirects
    setState(() => _loading = true);
    try {
      final result = await WallpaperPlugin.useAsImageFromRepaintBoundary(
        previewContainer,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      if (result.isSuccess) {
        _useAsLaunched = true;
      } else {
        _showSnack('${result.message ?? 'Failed'}: ${result.error?.name}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Unexpected error: $e');
    }
  }

  void _showSnack(String text) {
    final messengerState = ScaffoldMessenger.maybeOf(context);
    messengerState?.showSnackBar(SnackBar(content: Text(text)));
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
                          if (widget.initialUri != null) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _setFromUri,
                              icon: const Icon(Icons.wallpaper),
                              label: const Text(
                                'Set from incoming image (Both)',
                              ),
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
