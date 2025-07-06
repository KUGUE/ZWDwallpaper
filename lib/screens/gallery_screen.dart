import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dashboard_button.dart';
import '../widgets/dashboard_panel.dart';
import '../utils/wallpaper_utils.dart';
import '../utils/wallpaper_info.dart';
import 'detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  final String? initialCategory;
  const GalleryScreen({super.key, this.initialCategory});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<String> categories = [
    'nature',
    'space',
    'animals',
    'cars',
    'abstract',
    'city',
    'people',
    'food',
    'flowers',
    'mountains',
    'beach',
    'technology',
    'music',
    'travel',
    'sports',
    'fashion',
    'books',
    'architecture',
    'night',
    'vintage',
    'minimal',
    'macro',
    'patterns',
    'street',
    'rain',
    'fire',
    'desert',
    'ocean',
    'forest',
    'sunset',
  ];
  late String selectedCategory;
  List<WallpaperInfo> wallpapers = [];
  bool isLoading = false;
  Set<String> favoriteUrls = {};
  List<String> downloadedUrls = [];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory?.toLowerCase() ?? 'nature';
    if (!categories.contains(selectedCategory)) {
      categories.add(selectedCategory);
    }
    fetchWallpapers();
    loadFavoritesAndDownloads();
  }

  Future<void> fetchWallpapers() async {
    setState(() => isLoading = true);
    final topicMap = {
      'nature': 'nature',
      'space': 'space',
      'animals': 'animals',
      'cars': 'cars',
      'abstract': 'abstract',
    };
    String url;
    bool triedTopic = false;
    if (topicMap.containsKey(selectedCategory)) {
      url = 'https://api.unsplash.com/topics/${topicMap[selectedCategory]}/photos?per_page=20&client_id=_YHrck5FuuZUOytFWmxc-6cLoMXShJ8smKtS9aMFX58';
      triedTopic = true;
    } else {
      url = 'https://api.unsplash.com/search/photos?query=$selectedCategory&per_page=20&client_id=_YHrck5FuuZUOytFWmxc-6cLoMXShJ8smKtS9aMFX58';
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data is List ? data : data['results'];
        final validResults = results.where((img) =>
          img != null &&
          img['urls'] != null &&
          img['urls']['regular'] != null &&
          img['user'] != null &&
          img['user']['name'] != null &&
          img['user']['links'] != null &&
          img['user']['links']['html'] != null &&
          img['links'] != null &&
          img['links']['html'] != null
        ).toList();
        setState(() {
          wallpapers = validResults.map<WallpaperInfo>((img) => WallpaperInfo(
            imageUrl: img['urls']['regular'],
            authorName: img['user']['name'],
            authorUrl: img['user']['links']['html'],
            photoUrl: img['links']['html'],
          )).toList();
        });
        if (wallpapers.isEmpty && triedTopic) {
          // Si el topic no trajo resultados, intenta con búsqueda
          await fetchWallpapersFallback();
        } else if (wallpapers.isEmpty) {
          Fluttertoast.showToast(msg: 'No se encontraron imágenes válidas');
        }
      } else if (triedTopic && response.statusCode == 404) {
        // Si el topic no existe, intenta búsqueda sin mostrar error
        await fetchWallpapersFallback();
      } else {
        setState(() { wallpapers = []; });
        Fluttertoast.showToast(msg: 'Error al cargar imágenes (code: {response.statusCode})');
        debugPrint('Unsplash error: code={response.statusCode}, body={response.body}');
      }
    } catch (e) {
      setState(() { wallpapers = []; });
      Fluttertoast.showToast(msg: 'Error de red: {e.toString()}');
      debugPrint('Network error: {e.toString()}');
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchWallpapersFallback() async {
    // Intenta cargar por búsqueda si el topic falla
    final url = 'https://api.unsplash.com/search/photos?query=$selectedCategory&per_page=20&client_id=_YHrck5FuuZUOytFWmxc-6cLoMXShJ8smKtS9aMFX58';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        final validResults = results.where((img) =>
          img != null &&
          img['urls'] != null &&
          img['urls']['thumb'] != null &&
          img['urls']['regular'] != null
        ).toList();
        setState(() {
          wallpapers = validResults.map<WallpaperInfo>((img) => WallpaperInfo(
            imageUrl: img['urls']['regular'],
            authorName: img['user']['name'],
            authorUrl: img['user']['links']['html'],
            photoUrl: img['links']['html'],
          )).toList();
        });
        if (wallpapers.isEmpty) {
          Fluttertoast.showToast(msg: 'No se encontraron imágenes válidas');
        }
      } else {
        setState(() { wallpapers = []; });
        Fluttertoast.showToast(msg: 'Error al cargar imágenes (fallback, code: ${response.statusCode})');
        debugPrint('Unsplash fallback error: code=${response.statusCode}, body=${response.body}');
      }
    } catch (e) {
      setState(() { wallpapers = []; });
      Fluttertoast.showToast(msg: 'Error de red (fallback): ${e.toString()}');
      debugPrint('Network error (fallback): ${e.toString()}');
    }
  }

  Future<void> loadFavoritesAndDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteUrls = prefs.getStringList('favorites')?.toSet() ?? {};
      downloadedUrls = prefs.getStringList('downloads') ?? [];
    });
  }

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
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Galería de Wallpapers', style: TextStyle(color: Colors.white)),
        elevation: 0,
        // Eliminado el Dropdown de categorías
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
                        final wallpaper = wallpapers[index];
                        final isFavorite = favoriteUrls.contains(wallpaper.imageUrl);
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  imageUrl: wallpaper.imageUrl,
                                  isFavorite: isFavorite,
                                  authorName: wallpaper.authorName,
                                  authorUrl: wallpaper.authorUrl,
                                  photoUrl: wallpaper.photoUrl,
                                ),
                              ),
                            );
                            if (result == true) {
                              await loadFavoritesAndDownloads();
                              setState(() {});
                            }
                          },
                          child: Hero(
                            tag: wallpaper.imageUrl,
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
                                    Image.network(
                                      wallpaper.imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                                      },
                                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.red)),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await toggleFavorite(wallpaper.imageUrl);
                                          setState(() {});
                                        },
                                        child: Icon(
                                          favoriteUrls.contains(wallpaper.imageUrl)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: favoriteUrls.contains(wallpaper.imageUrl)
                                              ? Colors.redAccent
                                              : Colors.white70,
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
                    ),
          // Botón de Dashboard siempre presente
          DashboardButton(onOpen: () {
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
                    FadeTransition(
                      opacity: fade,
                      child: Transform.translate(
                        offset: Offset(MediaQuery.of(context).size.width * slide.value.dx, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DashboardPanel(
                            downloadedUrls: downloadedUrls,
                            favoriteUrls: favoriteUrls.toList(),
                          ),
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
