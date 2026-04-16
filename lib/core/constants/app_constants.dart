class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'DownloaderMedia';
  static const String appVersion = '1.0.0';

  // Window
  static const double windowMinWidth = 900;
  static const double windowMinHeight = 600;
  static const double windowDefaultWidth = 1200;
  static const double windowDefaultHeight = 750;
  static const double sidebarWidth = 72;
  static const double sidebarExpandedWidth = 200;

  // Downloads
  static const int maxConcurrentDownloads = 3;
  static const String defaultAudioFormat = 'mp3';
  static const String defaultAudioQuality = '192';
  static const String defaultVideoFormat = 'mp4';
  static const String defaultVideoQuality = '1080';

  // Binary URLs
  static const String ytDlpDownloadUrl =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
  static const String ffmpegDownloadUrl =
      'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip';

  // Supported platforms (for UI badges)
  static const List<String> supportedPlatforms = [
    'YouTube',
    'TikTok',
    'Instagram',
    'Twitter',
    'Facebook',
    'SoundCloud',
  ];

  // Regex for parsing yt-dlp progress output
  static final RegExp progressRegex = RegExp(
    r'\[download\]\s+([\d.]+)%\s+of\s+~?\s*([\d.]+\w+)\s+at\s+([\d.]+\w+/s)\s+ETA\s+([\d:]+)',
  );

  static final RegExp progressSimpleRegex = RegExp(
    r'\[download\]\s+([\d.]+)%',
  );

  // yt-dlp format strings
  static const Map<String, String> videoFormats = {
    '2160': 'bestvideo[height<=2160]+bestaudio/best[height<=2160]',
    '1440': 'bestvideo[height<=1440]+bestaudio/best[height<=1440]',
    '1080': 'bestvideo[height<=1080]+bestaudio/best[height<=1080]',
    '720': 'bestvideo[height<=720]+bestaudio/best[height<=720]',
    '480': 'bestvideo[height<=480]+bestaudio/best[height<=480]',
    '360': 'bestvideo[height<=360]+bestaudio/best[height<=360]',
  };
}
