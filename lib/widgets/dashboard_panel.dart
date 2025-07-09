import 'package:flutter/material.dart';
import 'dart:ui';
import '../screens/favorites_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/about_screen.dart';

class DashboardPanel extends StatelessWidget {
  final List<String> favoriteUrls;
  const DashboardPanel({super.key, required this.favoriteUrls});
  @override
  Widget build(BuildContext context) {
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
              const Text('Dashboard', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.pinkAccent),
                title: const Text('Favoritos', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FavoritesScreen(favoriteUrls: favoriteUrls),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.explore, color: Colors.lightBlueAccent),
                title: const Text('Explorar', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExploreScreen(),
                    ),
                  );
                },
              ),
              const Divider(color: Colors.white24, height: 30),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white70),
                title: const Text('Acerca de', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  });
                },
              ),
              const Spacer(),
              const Text('© 2025', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }
}
