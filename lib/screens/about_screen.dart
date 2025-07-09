import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos y Licencia'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ZWallpaper utiliza la API de Unsplash para mostrar imágenes de alta calidad proporcionadas por fotógrafos de todo el mundo.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://unsplash.com/license')),
              child: const Text(
                'Licencia de Unsplash',
                style: TextStyle(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://unsplash.com/terms')),
              child: const Text(
                'Términos y condiciones de Unsplash',
                style: TextStyle(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://unsplash.com/privacy')),
              child: const Text(
                'Política de privacidad de Unsplash',
                style: TextStyle(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Esta app no almacena datos personales ni comparte información con terceros. Para más detalles, consulta la política de privacidad de Unsplash.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Spacer(),
            Center(
              child: Text(
                '© 2025 ZWallpaper',
                style: TextStyle(fontSize: 14, color: Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
