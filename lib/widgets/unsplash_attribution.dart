import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UnsplashAttribution extends StatelessWidget {
  final String photographerName;
  final String photographerUrl;
  final String photoUrl;
  final bool compact;
  const UnsplashAttribution({
    super.key,
    required this.photographerName,
    required this.photographerUrl,
    required this.photoUrl,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Foto de ', style: TextStyle(fontSize: 12, color: Colors.white70)),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(photographerUrl)),
            child: Text(
              photographerName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(' en ', style: TextStyle(fontSize: 12, color: Colors.white70)),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(photoUrl)),
            child: const Text(
              'Unsplash',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
