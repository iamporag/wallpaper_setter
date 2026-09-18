import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wallpaper_setter/wallpaper_setter.dart';
import 'package:web/web.dart' as web;

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

// ---------------------------------------------------------------------------
// Home Screen
// ---------------------------------------------------------------------------

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
      'https://picsum.photos/id/10/1920/1080',
    ),
    _WallpaperItem(
      'Mountains',
      'https://picsum.photos/id/29/1920/1080',
    ),
    _WallpaperItem(
      'Forest',
      'https://picsum.photos/id/15/1920/1080',
    ),
    _WallpaperItem(
      'Ocean',
      'https://picsum.photos/id/37/1920/1080',
    ),
    _WallpaperItem(
      'Desert',
      'https://picsum.photos/id/29/1920/1080',
    ),
    _WallpaperItem(
      'Waterfall',
      'https://picsum.photos/id/10/1920/1080',
    ),
    _WallpaperItem(
      'Lake',
      'https://picsum.photos/id/164/1920/1080',
    ),
    _WallpaperItem(
      'Sky',
      'https://picsum.photos/id/1015/1920/1080',
    ),
    _WallpaperItem(
      'Valley',
      'https://picsum.photos/id/1039/1920/1080',
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
    if (kIsWeb) {
      return _buildWebHome();
    }
    return _buildNativeHome();
  }

  // ---------------------------------------------------------------------------
  // Native Home
  // ---------------------------------------------------------------------------

  Widget _buildNativeHome() {
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

  // ---------------------------------------------------------------------------
  // Web Home - responsive grid
  // ---------------------------------------------------------------------------

  Widget _buildWebHome() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Wallpaper Gallery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<WallpaperCapabilities>(
        future: _capabilitiesFuture,
        builder: (context, snapshot) {
          final caps = snapshot.data ?? WallpaperCapabilities.none;
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount =
                  width > 1200
                      ? 5
                      : width > 900
                          ? 4
                          : width > 600
                              ? 3
                              : 2;
              final padding = width > 600 ? 20.0 : 12.0;

              return GridView.builder(
                padding: EdgeInsets.all(padding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: padding,
                  mainAxisSpacing: padding,
                  childAspectRatio: 0.65,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _WebWallpaperCard(
                    item: item,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            fullscreenDialog: true,
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
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

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

class _WebWallpaperCard extends StatelessWidget {
  const _WebWallpaperCard({required this.item, required this.onTap});
  final _WallpaperItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                item.url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    ),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF16213E),
                    const Color(0xFF1A1A2E),
                  ],
                ),
              ),
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview Screen
// ---------------------------------------------------------------------------

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    this.url,
    this.initialUri,
    required this.capabilities,
    this.isLocal = false,
  }) : assert(url != null || isLocal || initialUri != null);

  final String? url;
  final String? initialUri;
  final WallpaperCapabilities capabilities;
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
    if (widget.initialUri != null) return null;
    if (widget.isLocal) return null;
    return NetworkImage(widget.url!);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

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
    if (_loading) return;
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebPreview(context);
    }
    return _buildNativePreview(context);
  }

  // ---------------------------------------------------------------------------
  // Web Preview - OS-style full-screen wallpaper layout
  // ---------------------------------------------------------------------------

  Widget _buildWebPreview(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen wallpaper image
          Positioned.fill(
            child:
                _imageProvider == null
                    ? Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                    : Image(
                      image: _imageProvider!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Close button (top-left)
          Positioned(
            top: padding.top + 12,
            left: 16,
            child: _GlassButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Title (top-center)
          Positioned(
            top: padding.top + 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Wallpaper Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Bottom OS-style controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildOsStyleBottomBar(padding),
          ),
        ],
      ),
    );
  }

  Widget _buildOsStyleBottomBar(EdgeInsets padding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 20),
      child: _loading
          ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
          : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Download & Set Wallpaper button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _downloadForWallpaper,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wallpaper_rounded, size: 22),
                      SizedBox(width: 10),
                      Text('Download & Set Wallpaper'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Image will download, then follow the steps to set as desktop wallpaper.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
    );
  }

  // ---------------------------------------------------------------------------
  // Web: Download image and show OS wallpaper instructions
  // ---------------------------------------------------------------------------

  Future<void> _downloadForWallpaper() async {
    final url = widget.url;
    if (url == null) return;

    setState(() => _loading = true);

    try {
      // Fetch image through CORS proxy to get raw bytes
      final proxyUrl =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
      final client = HttpClient();
      try {
        client.connectionTimeout = const Duration(seconds: 15);
        final request = await client.getUrl(Uri.parse(proxyUrl));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        if (!mounted) return;
        setState(() => _loading = false);

        if (bytes.isNotEmpty) {
          _triggerDownload(bytes, 'wallpaper.png');
          _showWallpaperInstructionsDialog();
        } else {
          _showSnack('Failed to download image.');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Fallback: try direct download via anchor
      _tryDirectDownload(url);
      _showWallpaperInstructionsDialog();
    }
  }

  void _triggerDownload(Uint8List bytes, String filename) {
    // Encode to base64 data URL for download
    final base64Str = base64Encode(bytes);
    final dataUrl = 'data:image/png;base64,$base64Str';

    // Create download anchor
    final anchor = web.HTMLAnchorElement()
      ..href = dataUrl
      ..download = filename
      ..style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }

  void _tryDirectDownload(String url) {
    // Fallback: direct anchor download (may or may not work depending on CORS)
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = 'wallpaper.png'
      ..style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }

  void _showWallpaperInstructionsDialog() {

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Image Downloaded!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow these steps to set it as your desktop wallpaper:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildInstructionStep(
                      '1',
                      'Right-click on your desktop',
                      'Empty area on your home screen',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '2',
                      'Click "Personalize"',
                      'Or go to Settings > Personalization',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '3',
                      'Click "Background"',
                      'Select "Picture" as background type',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '4',
                      'Click "Browse photos"',
                      'Navigate to your Downloads folder',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '5',
                      'Select "wallpaper.png"',
                      'The downloaded image will be set as wallpaper',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildInstructionStep(
    String number,
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Native Preview
  // ---------------------------------------------------------------------------

  Widget _buildNativePreview(BuildContext context) {
    final canSet = widget.capabilities.supportsWallpaperSetting;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RepaintBoundary(
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

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
