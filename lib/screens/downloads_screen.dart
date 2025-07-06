import 'package:flutter/material.dart';
import '../utils/wallpaper_utils.dart';
import 'detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  final List<String> downloadedUrls;
  const DownloadsScreen({super.key, required this.downloadedUrls});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _precacheFiles();
  }

  Future<void> _precacheFiles() async {
    // Si en el futuro quieres usar localPaths, puedes reactivar esta lógica
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Descargados', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : widget.downloadedUrls.isEmpty
              ? const Center(child: Text('No hay descargas', style: TextStyle(color: Colors.white70)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: widget.downloadedUrls.length,
                  itemBuilder: (context, index) {
                    final url = widget.downloadedUrls[index];
                    final thumbUrl = deriveThumbUrl(url);
                    final imageProvider = NetworkImage(thumbUrl);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(imageUrl: url, isFavorite: false),
                          ),
                        );
                      },
                      child: Hero(
                        tag: url,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FadeInImage(
                            placeholder: const AssetImage('assets/placeholder.jpg'),
                            image: imageProvider,
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
