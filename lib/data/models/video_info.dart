class VideoInfo {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? duration;
  final String? uploader;
  final String? platform;
  final List<FormatOption> formats;
  final bool isPlaylist;
  final int? playlistCount;

  const VideoInfo({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.duration,
    this.uploader,
    this.platform,
    this.formats = const [],
    this.isPlaylist = false,
    this.playlistCount,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    final formatsList = <FormatOption>[];
    if (json['formats'] != null) {
      final seen = <String>{};
      for (final f in json['formats'] as List) {
        final height = f['height'];
        final ext = f['ext'] as String?;
        final vcodec = f['vcodec'] as String?;
        final acodec = f['acodec'] as String?;

        if (height != null && vcodec != null && vcodec != 'none') {
          final key = '${height}p_$ext';
          if (!seen.contains(key)) {
            seen.add(key);
            formatsList.add(
              FormatOption(
                formatId: f['format_id'] as String? ?? '',
                ext: ext ?? 'mp4',
                quality: '${height}p',
                height: height as int,
                filesize: f['filesize'] as int?,
                hasVideo: true,
                hasAudio: acodec != null && acodec != 'none',
              ),
            );
          }
        }
      }
      formatsList.sort((a, b) => b.height.compareTo(a.height));
    }

    final id = json['id'] as String? ?? '';
    final platform =
        json['extractor_key'] as String? ?? json['extractor'] as String?;
    var url = json['webpage_url'] as String? ?? json['url'] as String? ?? '';
    if (!url.startsWith('http') && id.isNotEmpty) {
      url = _resolveUrlFromId(platform, id, url);
    }

    return VideoInfo(
      id: json['id'] as String? ?? '',
      url: url,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail'] as String?,
      duration: json['duration'] != null
          ? (json['duration'] as num).toInt()
          : null,
      uploader: json['uploader'] as String? ?? json['channel'] as String?,
      platform: platform,
      formats: formatsList,
      isPlaylist: json['_type'] == 'playlist',
      playlistCount: json['playlist_count'] as int?,
    );
  }

  static String _resolveUrlFromId(
    String? platform,
    String id,
    String fallback,
  ) {
    final normalized = platform?.toLowerCase() ?? '';
    if (normalized.contains('youtube')) {
      return 'https://www.youtube.com/watch?v=$id';
    }
    if (normalized.contains('soundcloud') && fallback.startsWith('http')) {
      return fallback;
    }
    return fallback;
  }
}

class PlaylistInfo {
  final String url;
  final String title;
  final String? platform;
  final String? thumbnailUrl;
  final List<VideoInfo> entries;

  const PlaylistInfo({
    required this.url,
    required this.title,
    this.platform,
    this.thumbnailUrl,
    this.entries = const [],
  });

  VideoInfo toVideoInfo() {
    return VideoInfo(
      id: url,
      url: url,
      title: title,
      thumbnailUrl: thumbnailUrl,
      platform: platform,
      isPlaylist: true,
      playlistCount: entries.length,
    );
  }
}

class FormatOption {
  final String formatId;
  final String ext;
  final String quality;
  final int height;
  final int? filesize;
  final bool hasVideo;
  final bool hasAudio;

  const FormatOption({
    required this.formatId,
    required this.ext,
    required this.quality,
    required this.height,
    this.filesize,
    this.hasVideo = true,
    this.hasAudio = false,
  });

  String get label {
    final size = filesize != null
        ? ' (~${(filesize! / (1024 * 1024)).toStringAsFixed(0)} MB)'
        : '';
    return '$quality $ext$size';
  }
}
