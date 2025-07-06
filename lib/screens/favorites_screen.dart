import 'package:flutter/material.dart';
import '../utils/wallpaper_utils.dart';
import 'detail_screen.dart';

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
                final thumbUrl = deriveThumbUrl(url);
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(imageUrl: url, isFavorite: true),
                      ),
                    );
                  },
                  child: Hero(
                    tag: url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: FadeInImage(
                        placeholder: NetworkImage(thumbUrl),
                        image: NetworkImage(url),
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
    );
  }
}
