import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/wallpaper_utils.dart';

class DetailScreen extends StatefulWidget {
  final String imageUrl;
  final bool isFavorite;
  final String? authorName;
  final String? authorUrl;
  final String? photoUrl;
  const DetailScreen({
    super.key,
    required this.imageUrl,
    required this.isFavorite,
    this.authorName,
    this.authorUrl,
    this.photoUrl,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late bool _isFavorite;
  late String _thumbUrl;
  late String _regularUrl;
  bool _isLoadingHQ = true;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _thumbUrl = deriveThumbUrl(widget.imageUrl);
    _regularUrl = widget.imageUrl;
    _listenToHQImage();
  }

  void _listenToHQImage() {
    _isLoadingHQ = true;
    final image = NetworkImage(_regularUrl);
    _imageStream = image.resolve(const ImageConfiguration());
    _imageStreamListener = ImageStreamListener((_, __) {
      if (mounted && _isLoadingHQ) {
        setState(() => _isLoadingHQ = false);
      }
    });
    _imageStream?.addListener(_imageStreamListener!);
  }

  @override
  void didUpdateWidget(covariant DetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _thumbUrl = deriveThumbUrl(widget.imageUrl);
      _regularUrl = widget.imageUrl;
      _imageStream?.removeListener(_imageStreamListener!);
      _listenToHQImage();
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageStreamListener!);
    super.dispose();
  }

  void _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites')?.toSet() ?? {};
    if (favs.contains(widget.imageUrl)) {
      favs.remove(widget.imageUrl);
      _isFavorite = false;
    } else {
      favs.add(widget.imageUrl);
      _isFavorite = true;
    }
    await prefs.setStringList('favorites', favs.toList());
    setState(() {});
  }

  void _downloadImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF23272A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Fondo de pantalla', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _handleDownloadAndSetWallpaper(WallpaperManagerFlutter.homeScreen);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.white),
              title: const Text('Pantalla de bloqueo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _handleDownloadAndSetWallpaper(WallpaperManagerFlutter.lockScreen);
              },
            ),
            ListTile(
              leading: const Icon(Icons.smartphone, color: Colors.white),
              title: const Text('Ambos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _handleDownloadAndSetWallpaper(WallpaperManagerFlutter.bothScreens);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.lightBlueAccent),
              title: const Text('Descargar', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _saveToDownloads();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToDownloads() async {
    try {
      String rawUrl = widget.imageUrl.replaceFirst('/regular', '/raw');
      final response = await http.get(Uri.parse(rawUrl));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final filename = Uri.parse(rawUrl).pathSegments.last.split('?').first;
        final file = File('${dir.path}/wallcache_$filename.jpg');
        await file.writeAsBytes(response.bodyBytes);
        final prefs = await SharedPreferences.getInstance();
        final downloads = prefs.getStringList('downloads') ?? [];
        if (!downloads.contains(rawUrl)) {
          downloads.add(rawUrl);
          await prefs.setStringList('downloads', downloads);
        }
        Fluttertoast.showToast(msg: 'Imagen guardada en Descargas');
      } else {
        Fluttertoast.showToast(msg: 'Error al descargar la imagen');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }

  void _handleDownloadAndSetWallpaper(int location) async {
    try {
      String downloadUrl = widget.imageUrl.replaceFirst('/regular', '/raw');
      final testRaw = await http.head(Uri.parse(downloadUrl));
      if (testRaw.statusCode != 200) {
        downloadUrl = widget.imageUrl.replaceFirst('/regular', '/full');
      }
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/wallpaper.jpg');
        await file.writeAsBytes(response.bodyBytes);
        final wallpaperManager = WallpaperManagerFlutter();
        final result = await wallpaperManager.setWallpaper(file, location);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result == true
              ? 'Fondo de pantalla actualizado correctamente'
              : 'No se pudo establecer como fondo de pantalla.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al descargar la imagen')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error:  ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF23272A),
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Hero(
                  tag: widget.imageUrl,
                  child: FadeInImage(
                    placeholder: NetworkImage(_thumbUrl),
                    image: NetworkImage(_regularUrl),
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 350),
                    placeholderErrorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image, color: Colors.white38)),
                    imageErrorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.red)),
                  ),
                ),
              ),
            ),
            if (_isLoadingHQ)
              Positioned(
                left: 24,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3.2,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              top: 32,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          tooltip: 'Volver',
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _toggleFavorite,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? Colors.redAccent : Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _downloadImage,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.authorName != null && widget.authorUrl != null && widget.photoUrl != null)
              Positioned(
                top: 40,
                right: 24,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                width: 320,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Foto de', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15)),
                                    const SizedBox(height: 2),
                                    GestureDetector(
                                      onTap: () async {
                                        final url = Uri.parse(widget.authorUrl!);
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 120),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.lightBlueAccent.withOpacity(0.13),
                                          ),
                                          child: Text(
                                            widget.authorName!,
                                            style: const TextStyle(
                                              color: Colors.lightBlueAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () async {
                                        final url = Uri.parse(widget.photoUrl!);
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 120),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.white.withOpacity(0.10),
                                          ),
                                          child: Text(
                                            'Ver en Unsplash',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.85),
                                              fontSize: 15,
                                              decoration: TextDecoration.underline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.18),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cerrar'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.info_outline, color: Colors.white, size: 22),
                              SizedBox(width: 6),
                              Text('Autor', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
