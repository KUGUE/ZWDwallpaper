import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dashboard_button.dart';
import '../widgets/dashboard_panel.dart';
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
  ];
  late String selectedCategory;
  List<WallpaperInfo> wallpapers = [];
  bool isLoading = false;
  Set<String> favoriteUrls = {};

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory?.toLowerCase() ?? 'nature';
    if (!categories.contains(selectedCategory)) {
      categories.add(selectedCategory);
    }
    fetchWallpapers();
    loadFavorites();
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
            downloadLocation: img['links'] != null ? img['links']['download_location'] : null,
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
        Fluttertoast.showToast(msg: 'Error al cargar imágenes (code: ${response.statusCode})');
        debugPrint('Unsplash error: code=${response.statusCode}, body=${response.body}');
      }
    } catch (e) {
      setState(() { wallpapers = []; });
      Fluttertoast.showToast(msg: 'Error de red: ${e.toString()}');
      debugPrint('Network error: ${e.toString()}');
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
            downloadLocation: img['links'] != null ? img['links']['download_location'] : null,
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

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteUrls = prefs.getStringList('favorites')?.toSet() ?? {};
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

  Future<void> _openDetailScreen(int initialIndex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          imageUrl: wallpapers[initialIndex].imageUrl,
          isFavorite: favoriteUrls.contains(wallpapers[initialIndex].imageUrl),
          authorName: wallpapers[initialIndex].authorName,
          authorUrl: wallpapers[initialIndex].authorUrl,
          photoUrl: wallpapers[initialIndex].photoUrl,
          allWallpapers: wallpapers,
          initialIndex: initialIndex,
        ),
      ),
    );
    await loadFavorites();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Galería de Wallpapers', style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                        return GestureDetector(
                          onTap: () async {
                            _openDetailScreen(index);
                          },
                          child: Hero(
                            tag: wallpaper.imageUrl,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: FadeInImage(
                                placeholder: const AssetImage('assets/placeholder.jpg'),
                                image: NetworkImage(wallpaper.imageUrl),
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(milliseconds: 350),
                                placeholderErrorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image, color: Colors.white38)),
                                imageErrorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.red)),
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
                    FadeTransition(
                      opacity: fade,
                      child: Transform.translate(
                        offset: Offset(MediaQuery.of(context).size.width * slide.value.dx, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DashboardPanel(
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
