import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galería de Wallpapers',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const WallpaperGallery(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WallpaperGallery extends StatefulWidget {
  const WallpaperGallery({super.key});

  @override
  State<WallpaperGallery> createState() => _WallpaperGalleryState();
}

class _WallpaperGalleryState extends State<WallpaperGallery> {
  final List<String> categories = [
    'nature',
    'space',
    'animals',
    'cars',
    'abstract',
  ];
  String selectedCategory = 'nature';
  List<String> wallpapers = [];
  List<String> highQualityUrls = [];
  bool isLoading = false;
  Set<String> favoriteUrls = {};
  List<String> downloadedUrls = [];

  @override
  void initState() {
    super.initState();
    fetchWallpapers();
    loadFavoritesAndDownloads();
  }

  Future<void> fetchWallpapers() async {
    setState(() => isLoading = true);
    final url = 'https://api.unsplash.com/search/photos?query=$selectedCategory&per_page=20&client_id=_YHrck5FuuZUOytFWmxc-6cLoMXShJ8smKtS9aMFX58';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        setState(() {
          wallpapers = results.map<String>((img) => img['urls']['small'] as String).toList(); // Previews de menor calidad
          highQualityUrls = results.map<String>((img) {
            final raw = img['urls']['raw'] as String?;
            if (raw != null) {
              // Forzar máxima calidad
              return raw + '?auto=format&w=4096&q=100';
            } else {
              final full = img['urls']['full'] as String?;
              return full != null ? full + '?auto=format&w=4096&q=100' : img['urls']['regular'] as String;
            }
          }).toList();
        });
        // Predescargar imágenes en alta calidad
        prefetchHighQualityImages();
      } else {
        setState(() { wallpapers = []; highQualityUrls = []; });
        Fluttertoast.showToast(msg: 'Error al cargar imágenes');
      }
    } catch (e) {
      setState(() { wallpapers = []; highQualityUrls = []; });
      Fluttertoast.showToast(msg: 'Error de red');
    }
    setState(() => isLoading = false);
  }

  // --- CACHE LOCAL DE IMÁGENES DE ALTA CALIDAD ---
  Future<String> _getCachePathForUrl(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = Uri.parse(url).pathSegments.last.split('?').first;
    return '${dir.path}/wallcache_$filename.jpg';
  }

  Future<bool> _isImageCached(String url) async {
    final path = await _getCachePathForUrl(url);
    return File(path).exists();
  }

  Future<File?> _getCachedImageFile(String url) async {
    final path = await _getCachePathForUrl(url);
    final file = File(path);
    return await file.exists() ? file : null;
  }

  Future<void> _cacheImageFromNetwork(String url) async {
    final path = await _getCachePathForUrl(url);
    final file = File(path);
    if (!await file.exists()) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        }
      } catch (_) {}
    }
  }

  // Precarga en background de imágenes de alta calidad no cacheadas
  Future<void> prefetchHighQualityImages() async {
    for (final url in highQualityUrls) {
      _isImageCached(url).then((cached) {
        if (!cached) {
          _cacheImageFromNetwork(url);
        }
      });
    }
  }

  Future<void> loadFavoritesAndDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteUrls = prefs.getStringList('favorites')?.toSet() ?? {};
      downloadedUrls = prefs.getStringList('downloads') ?? [];
    });
  }

  /// Cambia el estado de favorito y devuelve el nuevo estado (true si es favorito)
  Future<bool> toggleFavorite(String url) async {
    bool isNowFavorite = false;
    setState(() {
      if (favoriteUrls.contains(url)) {
        favoriteUrls.remove(url);
        isNowFavorite = false;
      } else {
        favoriteUrls.add(url);
        isNowFavorite = true;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favoriteUrls.toList());
    return isNowFavorite;
  }

  Future<void> addDownloaded(String url) async {
    if (!downloadedUrls.contains(url)) {
      setState(() {
        downloadedUrls.add(url);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloads', downloadedUrls);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A), // gris oscuro
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Galería de Wallpapers', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              dropdownColor: const Color(0xFF23272A),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat[0].toUpperCase() + cat.substring(1), style: const TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() { selectedCategory = value; });
                  fetchWallpapers();
                }
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : wallpapers.isEmpty
                  ? const Center(child: Text('No hay imágenes', style: TextStyle(color: Colors.white70)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: wallpapers.length,
                      itemBuilder: (context, index) {
                        final imageUrl = wallpapers[index];
                        final highQualityUrl = highQualityUrls.length > index ? highQualityUrls[index] : imageUrl;
                        final isFavorite = favoriteUrls.contains(highQualityUrl);
                        return FutureBuilder<File?>(
                          future: _getCachedImageFile(highQualityUrl),
                          builder: (context, snapshot) {
                            final cachedFile = snapshot.data;
                            return GestureDetector(
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                                );
                                try {
                                  await precacheImage(NetworkImage(highQualityUrl), context);
                                } catch (_) {}
                                Navigator.of(context, rootNavigator: true).pop();
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WallpaperDetail(imageUrl: highQualityUrl, isFavorite: isFavorite),
                                  ),
                                );
                                if (result == true) {
                                  // Si hubo cambio en favoritos, recargar
                                  await loadFavoritesAndDownloads();
                                  setState(() {});
                                }
                              },
                              child: Hero(
                                tag: highQualityUrl,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2C2F33),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        cachedFile != null
                                          ? Image.file(cachedFile, fit: BoxFit.cover)
                                          : Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return const Center(child: CircularProgressIndicator(color: Colors.white));
                                              },
                                            ),
                                        // Corazón para favoritos
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () async {
                                              await toggleFavorite(highQualityUrl);
                                              setState(() {}); // Fuerza la actualización visual del corazón
                                            },
                                            child: Icon(
                                              favoriteUrls.contains(highQualityUrl) ? Icons.favorite : Icons.favorite_border,
                                              color: favoriteUrls.contains(highQualityUrl) ? Colors.redAccent : Colors.white70,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
          // Dashboard lateral
          _DashboardButton(onOpen: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dashboard',
              transitionDuration: const Duration(milliseconds: 420),
              pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
              transitionBuilder: (context, anim1, anim2, child) {
                final slide = Tween<Offset>(begin: const Offset(-0.5, 0.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutExpo));
                final fade = CurvedAnimation(parent: anim1, curve: Curves.easeInOut);
                return Stack(
                  children: [
                    // Área táctil para cerrar al hacer tap fuera
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Opacity(
                        opacity: fade.value * 0.95,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            color: Colors.transparent,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                          ),
                        ),
                      ),
                    ),
                    // Panel lateral animado con FadeTransition
                    FadeTransition(
                      opacity: fade,
                      child: Transform.translate(
                        offset: Offset(MediaQuery.of(context).size.width * slide.value.dx, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _DashboardPanel(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class WallpaperDetail extends StatefulWidget {
  final String imageUrl;
  final bool isFavorite;
  const WallpaperDetail({super.key, required this.imageUrl, required this.isFavorite});

  @override
  State<WallpaperDetail> createState() => _WallpaperDetailState();
}

class _WallpaperDetailState extends State<WallpaperDetail> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFavoriteState();
  }

  @override
  void didUpdateWidget(covariant WallpaperDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _syncFavoriteState();
    }
  }

  void _syncFavoriteState() {
    final state = context.findAncestorStateOfType<_WallpaperGalleryState>();
    if (state != null) {
      final isFav = state.favoriteUrls.contains(widget.imageUrl);
      if (_isFavorite != isFav) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  void _toggleFavorite({bool animated = false}) async {
    final state = context.findAncestorStateOfType<_WallpaperGalleryState>();
    bool isNowFavorite;
    if (state != null) {
      isNowFavorite = await state.toggleFavorite(widget.imageUrl);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final favs = prefs.getStringList('favorites')?.toSet() ?? {};
      if (favs.contains(widget.imageUrl)) {
        favs.remove(widget.imageUrl);
        isNowFavorite = false;
      } else {
        favs.add(widget.imageUrl);
        isNowFavorite = true;
      }
      await prefs.setStringList('favorites', favs.toList());
    }
    setState(() {
      _isFavorite = isNowFavorite;
    });
  }

  void _downloadImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF23272A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
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
            ],
          ),
        );
      },
    );
  }

  void _handleDownloadAndSetWallpaper(int location) async {
    final state = context.findAncestorStateOfType<_WallpaperGalleryState>();
    if (state != null) {
      await state.addDownloaded(widget.imageUrl);
    }
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/wallpaper.jpg');
        await file.writeAsBytes(response.bodyBytes);
        final wallpaperManager = WallpaperManagerFlutter();
        final result = await wallpaperManager.setWallpaper(file, location);
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fondo de pantalla actualizado correctamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo establecer como fondo de pantalla.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al descargar la imagen')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    },
                  ),
                ),
              ),
            ),
            // Botón volver
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
            // Botones glass abajo
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón favorito
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _toggleFavorite(animated: true),
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
                    // Botón descargar
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
          ],
        ),
      ),
    );
  }
}

// Widget para el botón flotante en el borde izquierdo centrado
class _DashboardButton extends StatelessWidget {
  final VoidCallback onOpen;
  const _DashboardButton({required this.onOpen});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      top: MediaQuery.of(context).size.height / 2 - 32, // Centrado vertical
      child: GestureDetector(
        onTap: onOpen,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xCC23272A), // gris oscuro translúcido
                border: Border.all(color: Colors.white.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Pantalla genérica para mostrar una galería de imágenes (favoritos o descargados)
class GalleryScreen extends StatelessWidget {
  final List<String> imageUrls;
  final String title;
  final Set<String> favoriteUrls;
  final void Function(String url) onToggleFavorite;
  final bool showFavoriteButton;

  const GalleryScreen({
    super.key,
    required this.imageUrls,
    required this.title,
    required this.favoriteUrls,
    required this.onToggleFavorite,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: imageUrls.isEmpty
          ? const Center(child: Text('No hay imágenes', style: TextStyle(color: Colors.white70)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final url = imageUrls[index];
                final isFavorite = favoriteUrls.contains(url);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WallpaperDetail(imageUrl: url, isFavorite: isFavorite),
                      ),
                    );
                  },
                  child: Hero(
                    tag: url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                            },
                          ),
                          if (showFavoriteButton)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  onToggleFavorite(url);
                                },
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.redAccent : Colors.white70,
                                  size: 28,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Panel lateral tipo dashboard con borde curveado derecho y glass gris
class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel();
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_WallpaperGalleryState>();
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xCC23272A),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(40)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24,
              offset: Offset(8, 0),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 32),
              ListTile(
                leading: Icon(Icons.download_rounded, color: Colors.white70),
                title: Text('Descargados', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  if (state != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DownloadsScreen(downloadedUrls: state.downloadedUrls),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.pinkAccent),
                title: Text('Favoritos', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  if (state != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FavoritesScreen(favoriteUrls: state.favoriteUrls.toList()),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.explore, color: Colors.lightBlueAccent),
                title: Text('Explorar', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.white70),
                title: Text('Ajustes', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              Divider(color: Colors.white24, height: 32),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.white70),
                title: Text('Acerca de', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  showAboutDialog(
                    context: context,
                    applicationName: 'Galería de Wallpapers',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Desarrollado por Emmanuel Kugue Tapiz',
                  );
                },
              ),
              Spacer(),
              Text('© 2025', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }
}

// Vista dedicada para Favoritos
class FavoritesScreen extends StatelessWidget {
  final List<String> favoriteUrls;
  const FavoritesScreen({super.key, required this.favoriteUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Favoritos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: favoriteUrls.isEmpty
          ? const Center(child: Text('No hay favoritos', style: TextStyle(color: Colors.white70)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: favoriteUrls.length,
              itemBuilder: (context, index) {
                final url = favoriteUrls[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WallpaperDetail(imageUrl: url, isFavorite: true),
                      ),
                    );
                    if (result == true) {
                      // Recargar favoritos
                      final prefs = await SharedPreferences.getInstance();
                      final favs = prefs.getStringList('favorites') ?? [];
                      favoriteUrls.clear();
                      favoriteUrls.addAll(favs);
                      (context as Element).markNeedsBuild();
                    }
                  },
                  child: Hero(
                    tag: url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Vista dedicada para Descargados
class DownloadsScreen extends StatelessWidget {
  final List<String> downloadedUrls;
  const DownloadsScreen({super.key, required this.downloadedUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Descargados', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: downloadedUrls.isEmpty
          ? const Center(child: Text('No hay descargas', style: TextStyle(color: Colors.white70)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: downloadedUrls.length,
              itemBuilder: (context, index) {
                final url = downloadedUrls[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WallpaperDetail(imageUrl: url, isFavorite: false),
                      ),
                    );
                  },
                  child: Hero(
                    tag: url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

