import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dashboard_button.dart';
import '../widgets/dashboard_panel.dart';
import 'gallery_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<Map<String, dynamic>> categories = const [
    {"name": "Naturaleza", "images": [
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Espacio", "images": [
      "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1465101178521-c1a9136a3b99?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Animales", "images": [
      "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Autos", "images": [
      "https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Flores", "images": [
      "https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1465101178521-c1a9136a3b99?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    
    {"name": "Playa", "images": [
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Tecnología", "images": [
      "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Música", "images": [
      "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Viajes", "images": [
      "https://images.unsplash.com/photo-1465101178521-c1a9136a3b99?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Deportes", "images": [
      "https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=400&q=80", // Jugadores de fútbol en acción
      "https://images.unsplash.com/photo-1505843275257-8493c9b41b6b?auto=format&fit=crop&w=400&q=80" // Balón de baloncesto en cancha
    ]},
    {"name": "Moda", "images": [
      "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Libros", "images": [
      "https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Arquitectura", "images": [
      "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?auto=format&fit=crop&w=400&q=80", // Edificio moderno
      "https://images.unsplash.com/photo-1465101178521-c1a9136a3b99?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Noche", "images": [
      "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Vintage", "images": [
      "https://images.unsplash.com/photo-1504196606672-aef5c9cefc92?auto=format&fit=crop&w=400&q=80", // Foto vintage
      "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Minimalista", "images": [
      "https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80", // Fondo blanco con una silla simple
      "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80" // Fondo claro con objeto minimalista (diferente imagen)
    ]},
    {"name": "Ciudad", "images": [
      "https://images.unsplash.com/photo-1467269204594-9661b134dd2b?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Patrones", "images": [
      "https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Calle", "images": [
      "https://images.unsplash.com/photo-1467269204594-9661b134dd2b?auto=format&fit=crop&w=400&q=80", // Calle urbana de noche
      "https://images.unsplash.com/photo-1504196606672-aef5c9cefc92?auto=format&fit=crop&w=400&q=80" // Calle con ambiente vintage
    ]},
    {"name": "Lluvia", "images": [
      "https://images.unsplash.com/photo-1502086223501-7ea6ecd79368?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Matemáticas", "images": [
      "https://images.unsplash.com/photo-1465101178521-c1a9136a3b99?auto=format&fit=crop&w=400&q=80", // Fórmulas matemáticas en una pizarra
      "https://images.unsplash.com/photo-1503676382389-4809596d5290?auto=format&fit=crop&w=400&q=80" // Libros y calculadora
    ]},
    {"name": "Desierto", "images": [
      "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Océano", "images": [
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Bosque", "images": [
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80"
    ]},
    {"name": "Atardecer", "images": [
      "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80"
    ]},
  ];

  List<String> favoriteUrls = [];
  List<String> downloadedUrls = [];

  @override
  void initState() {
    super.initState();
    _loadFavoritesAndDownloads();
  }

  Future<void> _loadFavoritesAndDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteUrls = prefs.getStringList('favorites') ?? [];
      downloadedUrls = prefs.getStringList('downloads') ?? [];
    });
  }

  Widget _categoryImage(List<String> images, int idx) {
    if (images.isEmpty) {
      return const Icon(Icons.broken_image, color: Colors.white, size: 48);
    }
    // Siempre muestra la PRIMERA imagen de la lista de la categoría
    return Image.network(
      images[0],
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Si falla, intenta con la siguiente imagen de la lista (de la misma categoría)
        return images.length > 1
            ? Image.network(
                images[1],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
              )
            : const Icon(Icons.broken_image, color: Colors.white, size: 48);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Explorar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // Oculta el botón de back
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final images = (cat["images"] is List && cat["images"] != null)
                        ? List<String>.from(cat["images"])
                        : <String>[];
                    return GestureDetector(
                      onTap: () {
                        // Navega a la galería filtrada por categoría
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GalleryScreen(initialCategory: cat["name"]!.toLowerCase()),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _categoryImage(images, 0),
                            Container(
                              color: Colors.black.withOpacity(0.35),
                            ),
                            Center(
                              child: Text(
                                cat["name"]!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: GestureDetector(
                  onTap: () async {
                    // Abre Unsplash en el navegador
                    final url = Uri.parse('https://unsplash.com');
                    // ignore: deprecated_member_use
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  child: Text(
                    'Imágenes proporcionadas por Unsplash',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          DashboardButton(
            onOpen: () async {
              await _loadFavoritesAndDownloads();
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
                              favoriteUrls: favoriteUrls,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
