class UrlValidator {
  UrlValidator._();

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String? detectPlatform(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    final host = uri.host.toLowerCase();

    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return 'YouTube';
    } else if (host.contains('tiktok.com')) {
      return 'TikTok';
    } else if (host.contains('instagram.com')) {
      return 'Instagram';
    } else if (host.contains('twitter.com') || host.contains('x.com')) {
      return 'Twitter';
    } else if (host.contains('facebook.com') || host.contains('fb.watch')) {
      return 'Facebook';
    } else if (host.contains('soundcloud.com')) {
      return 'SoundCloud';
    }
    return null;
  }

  static bool isPlaylist(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    return uri.queryParameters.containsKey('list') ||
        uri.path.contains('/playlist');
  }
}
