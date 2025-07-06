String deriveThumbUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null && uri.host.contains('unsplash.com')) {
    final segments = List<String>.from(uri.pathSegments);
    if (segments.length > 2 && segments[segments.length - 2] == 'photo-') {
      return url;
    }
    if (segments.isNotEmpty) {
      final newUri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        'fm': 'jpg',
        'q': '20',
        'w': '300',
      });
      return newUri.toString();
    }
  }
  return url;
}
