import 'package:flutter/material.dart';
import '../utils/wallpaper_utils.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final List<String> historyUrls;
  const HistoryScreen({super.key, required this.historyUrls});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _precacheFiles();
  }

  Future<void> _precacheFiles() async {
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
        title: const Text('Historial', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : widget.historyUrls.isEmpty
              ? const Center(child: Text('No hay historial', style: TextStyle(color: Colors.white70)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: widget.historyUrls.length,
                  itemBuilder: (context, index) {
                    final url = widget.historyUrls[index];
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
