import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../utils/wallpaper_info.dart';
import '../widgets/animated_splash_loader.dart';

class DetailScreen extends StatefulWidget {
  final String imageUrl;
  final bool isFavorite;
  final String? authorName;
  final String? authorUrl;
  final String? photoUrl;
  final List<WallpaperInfo>? allWallpapers;
  final int? initialIndex;
  const DetailScreen({
    super.key,
    required this.imageUrl,
    required this.isFavorite,
    this.authorName,
    this.authorUrl,
    this.photoUrl,
    this.allWallpapers,
    this.initialIndex,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late bool _isFavorite;
  bool _isLoadingHQ = true;
  bool _hideUI = false; // Nuevo estado para ocultar la UI
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  int? currentIndex;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: currentIndex ?? 0);
    _listenToHQImage();
  }

  void _listenToHQImage() {
    _isLoadingHQ = true;
    final image = NetworkImage(widget.imageUrl);
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
      _imageStream?.removeListener(_imageStreamListener!);
      _listenToHQImage();
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageStreamListener!);
    _pageController?.dispose();
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
          SnackBar(
            content: Text(
              result == true
                  ? 'Fondo de pantalla actualizado correctamente'
                  : 'No se pudo establecer como fondo de pantalla.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al descargar la imagen')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error:  ${e.toString()}')));
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  WallpaperInfo get _currentWallpaper =>
      widget.allWallpapers != null && currentIndex != null
      ? widget.allWallpapers![currentIndex!]
      : WallpaperInfo(
          imageUrl: widget.imageUrl,
          authorName: widget.authorName ?? '',
          authorUrl: widget.authorUrl ?? '',
          photoUrl: widget.photoUrl ?? '',
        );

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
            if (widget.allWallpapers != null &&
                widget.allWallpapers!.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_hideUI) {
                    setState(() {
                      _hideUI = false;
                    });
                  }
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.allWallpapers!.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final wallpaper = widget.allWallpapers![index];
                    return Hero(
                      tag: wallpaper.imageUrl,
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.white],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dst,
                        child: CachedNetworkImage(
                          imageUrl: wallpaper.imageUrl.replaceFirst(
                            '/regular',
                            '/thumb',
                          ),
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          placeholder: (context, url) =>
                              Container(color: Colors.black12),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_hideUI) {
                    setState(() {
                      _hideUI = false;
                    });
                  }
                },
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Hero(
                    tag: _currentWallpaper.imageUrl,
                    child: CachedNetworkImage(
                      imageUrl: _currentWallpaper.imageUrl.replaceFirst(
                        '/regular',
                        '/full',
                      ),
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      placeholder: (context, url) =>
                          Container(color: Colors.black12),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            if (_isLoadingHQ && !_hideUI)
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
            if (!_hideUI)
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
                            color: const Color.fromARGB(255, 37, 27, 27).withOpacity(0.30),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                            tooltip: 'Volver',
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!_hideUI)
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón de favoritos
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 39, 35, 35).withOpacity(0.30),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.30),
                                  ),
                                ),
                                child: Icon(
                                  _isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isFavorite
                                      ? Colors.redAccent
                                      : Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón para ocultar la UI (solo uno)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            setState(() {
                              _hideUI = true;
                            });
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 39, 35, 35).withOpacity(0.30),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.30),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.visibility_off,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón de establecer fondo
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: const Color(0xFF23272A),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                        Icons.home,
                                        color: Colors.white,
                                      ),
                                      title: const Text(
                                        'Pantalla de inicio',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await _handleSetWallpaper(1); // 1: HOME_SCREEN
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.lock,
                                        color: Colors.white,
                                      ),
                                      title: const Text(
                                        'Pantalla de bloqueo',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await _handleSetWallpaper(2); // 2: LOCK_SCREEN
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.smartphone,
                                        color: Colors.white,
                                      ),
                                      title: const Text(
                                        'Ambos',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await _handleSetWallpaper(3); // 3: BOTH_SCREENS
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 39, 27, 39).withOpacity(0.30),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.wallpaper,
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
            // ...resto de la UI (atribución, etc) solo si !_hideUI
            if (_currentWallpaper.authorName.isNotEmpty &&
                _currentWallpaper.authorUrl.isNotEmpty &&
                _currentWallpaper.photoUrl.isNotEmpty &&
                !_hideUI)
              Positioned(
                top: 40,
                right: 24,
                child: Material(
                  color: Colors.transparent,
                    child: Padding(
                    padding: const EdgeInsets.only(top: 20),
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
                            padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                            ),
                            decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              39,
                              27,
                              39,
                            ).withOpacity(0.30),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            ),
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                              'Foto de',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 15,
                              ),
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                _currentWallpaper.authorUrl,
                                );
                                await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                                );
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 120,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                  8,
                                  ),
                                  color: Colors.lightBlueAccent
                                    .withOpacity(0.13),
                                ),
                                child: Text(
                                  _currentWallpaper.authorName,
                                  style: const TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  decoration:
                                    TextDecoration.underline,
                                  ),
                                ),
                                ),
                              ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                _currentWallpaper.photoUrl,
                                );
                                await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                                );
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 120,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                  8,
                                  ),
                                  color: Colors.white.withOpacity(
                                  0.10,
                                  ),
                                ),
                                child: Text(
                                  'Ver en Unsplash',
                                  style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.85,
                                  ),
                                  fontSize: 15,
                                  decoration:
                                    TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                  ),
                                ),
                                ),
                              ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white
                                  .withOpacity(0.30),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  16,
                                ),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () =>
                                Navigator.of(context).pop(),
                              child: const Text('Cerrar'),
                              ),
                            ],
                            ),
                          ),
                          ),
                        ), ),
                        );
                      },
                      child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                          255,
                          41,
                          33,
                          40,
                          ).withOpacity(0.30),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Autor',
                            style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            ),
                          ),
                          ],
                        ),
                        ),
                      ),
                      ),
                    ),
                    ),
                  ),
                ),
                 ], ),

        ),
      );

  }

  // Trigger de descarga a Unsplash
  Future<void> _triggerUnsplashDownload(String? downloadLocation) async {
    if (downloadLocation == null) return;
    try {
      await http.get(Uri.parse(downloadLocation));
    } catch (e) {
      // Ignorar error, solo para reporte de uso
    }
  }

  Future<void> _handleSetWallpaper(int location) async {
    // Guardar estado para restaurar tras posible reinicio
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_wallpaper_url', _currentWallpaper.imageUrl);
    await prefs.setInt('pending_wallpaper_location', location);
    await prefs.setBool('pending_wallpaper', true);

    // Trigger de descarga a Unsplash antes de descargar la imagen
    await _triggerUnsplashDownload(_currentWallpaper.downloadLocation);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                AnimatedSplashLoader(size: 90),
                SizedBox(height: 18),
                Text(
                  'Estableciendo fondo...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final start = DateTime.now();
    try {
      String rawUrl = _currentWallpaper.imageUrl.replaceFirst('/regular', '/raw');
      final response = await http.get(Uri.parse(rawUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final uniqueName = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/wallpaper_$uniqueName.jpg');
        await file.writeAsBytes(bytes);
        bool result = false;
        if (location == 2) {
          // Alternativa nativa para lockscreen
          const platform = MethodChannel('zwallpaper/wallpaper');
          try {
            result = await platform.invokeMethod('setLockScreenWallpaper', {'filePath': file.path});
          } catch (e) {
            Navigator.of(context, rootNavigator: true).pop();
            await prefs.remove('pending_wallpaper_url');
            await prefs.remove('pending_wallpaper_location');
            await prefs.remove('pending_wallpaper');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No es posible establecer el fondo en este dispositivo.')),
            );
            return;
          }
        } else {
          final wallpaperManager = WallpaperManagerFlutter();
          try {
            result = await wallpaperManager.setWallpaper(file, location);
          } catch (e) {
            Navigator.of(context, rootNavigator: true).pop();
            await prefs.remove('pending_wallpaper_url');
            await prefs.remove('pending_wallpaper_location');
            await prefs.remove('pending_wallpaper');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No es posible establecer el fondo en este dispositivo.')),
            );
            return;
          }
        }
        // Limpiar flag tras intento
        await prefs.remove('pending_wallpaper_url');
        await prefs.remove('pending_wallpaper_location');
        await prefs.remove('pending_wallpaper');
        // Esperar hasta que hayan pasado al menos 5 segundos desde que se mostró el loader
        final elapsed = DateTime.now().difference(start);
        if (elapsed.inMilliseconds < 5000) {
          await Future.delayed(Duration(milliseconds: 5000 - elapsed.inMilliseconds));
        }
        Navigator.of(context, rootNavigator: true).pop();
        String successMsg;
        if (location == 2 && result == true) {
          successMsg = 'Fondo de bloqueo actualizado correctamente';
        } else if (result == true) {
          successMsg = 'Fondo de pantalla actualizado correctamente';
        } else {
          successMsg = 'No es posible establecer el fondo en este dispositivo.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
          ),
        );
      } else {
        await prefs.remove('pending_wallpaper_url');
        await prefs.remove('pending_wallpaper_location');
        await prefs.remove('pending_wallpaper');
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al descargar la imagen')),
        );
      }
    } catch (e) {
      await prefs.remove('pending_wallpaper_url');
      await prefs.remove('pending_wallpaper_location');
      await prefs.remove('pending_wallpaper');
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error:  \\${e.toString()}')));
    }
  }
}
