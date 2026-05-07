import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_media/core/utils/url_validator.dart';

void main() {
  group('UrlValidator', () {
    test('accepts http and https URLs', () {
      expect(UrlValidator.isValidUrl('https://youtube.com/watch?v=abc'), true);
      expect(UrlValidator.isValidUrl('http://example.com/video'), true);
    });

    test('rejects unsupported or malformed URLs', () {
      expect(UrlValidator.isValidUrl('ftp://example.com/file'), false);
      expect(UrlValidator.isValidUrl('not a url'), false);
      expect(UrlValidator.isValidUrl('https:///missing-host'), false);
    });

    test('detects common platforms', () {
      expect(UrlValidator.detectPlatform('https://youtu.be/abc'), 'YouTube');
      expect(
        UrlValidator.detectPlatform('https://www.tiktok.com/@a/video/1'),
        'TikTok',
      );
      expect(
        UrlValidator.detectPlatform('https://x.com/user/status/1'),
        'Twitter',
      );
    });

    test('detects playlists', () {
      expect(
        UrlValidator.isPlaylist('https://youtube.com/watch?v=1&list=abc'),
        true,
      );
      expect(UrlValidator.isPlaylist('https://example.com/playlist/abc'), true);
      expect(UrlValidator.isPlaylist('https://youtube.com/watch?v=1'), false);
    });
  });
}
