class WallpaperInfo {
  final String imageUrl;
  final String authorName;
  final String authorUrl;
  final String photoUrl;
  final String? downloadLocation; // Nueva propiedad para Unsplash

  WallpaperInfo({
    required this.imageUrl,
    required this.authorName,
    required this.authorUrl,
    required this.photoUrl,
    this.downloadLocation, // Nueva propiedad opcional
  });
}
