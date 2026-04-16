enum DownloadStatus {
  queued,
  fetchingInfo,
  downloading,
  merging,
  converting,
  completed,
  failed,
  cancelled,
}

enum DownloadType { video, videoWithAudio, audio }

class DownloadTask {
  final String id;
  final String url;
  final String title;
  final String? thumbnailUrl;
  final String? platform;
  final String outputPath;
  final DownloadType type;
  final String format;
  final String quality;
  final DownloadStatus status;
  final double progress;
  final String? speed;
  final String? eta;
  final String? fileSize;
  final int? duration;
  final String? error;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.thumbnailUrl,
    this.platform,
    required this.outputPath,
    required this.type,
    required this.format,
    required this.quality,
    required this.status,
    this.progress = 0.0,
    this.speed,
    this.eta,
    this.fileSize,
    this.duration,
    this.error,
    required this.createdAt,
    this.completedAt,
  });

  DownloadTask copyWith({
    String? id,
    String? url,
    String? title,
    String? thumbnailUrl,
    String? platform,
    String? outputPath,
    DownloadType? type,
    String? format,
    String? quality,
    DownloadStatus? status,
    double? progress,
    String? speed,
    String? eta,
    String? fileSize,
    int? duration,
    String? error,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      platform: platform ?? this.platform,
      outputPath: outputPath ?? this.outputPath,
      type: type ?? this.type,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.fetchingInfo ||
      status == DownloadStatus.merging ||
      status == DownloadStatus.converting;

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isCancelled => status == DownloadStatus.cancelled;
  bool get isQueued => status == DownloadStatus.queued;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'platform': platform,
      'output_path': outputPath,
      'type': type.name,
      'format': format,
      'quality': quality,
      'status': status.name,
      'progress': progress,
      'file_size': fileSize,
      'duration': duration,
      'error': error,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'] as String,
      url: map['url'] as String,
      title: map['title'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      platform: map['platform'] as String?,
      outputPath: map['output_path'] as String,
      type: DownloadType.values.byName(map['type'] as String),
      format: map['format'] as String,
      quality: map['quality'] as String,
      status: DownloadStatus.values.byName(map['status'] as String),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      fileSize: map['file_size'] as String?,
      duration: map['duration'] as int?,
      error: map['error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
    );
  }
}
