import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../models/video_info.dart';
import 'binary_manager.dart';

class DownloadProgress {
  final double? percent;
  final String? speed;
  final String? eta;
  final String? totalSize;
  final String? phase;

  const DownloadProgress({
    this.percent,
    this.speed,
    this.eta,
    this.totalSize,
    this.phase,
  });
}

class DownloadFailure implements Exception {
  final String message;
  final String details;
  final int? exitCode;

  const DownloadFailure(this.message, {this.details = '', this.exitCode});

  @override
  String toString() => message;
}

class YtDlpService {
  final BinaryManager _binaryManager;
  final Map<String, Process> _activeProcesses = {};

  YtDlpService(this._binaryManager);

  /// Extract video metadata without downloading
  Future<VideoInfo> extractInfo(String url) async {
    final result = await Process.run(_binaryManager.ytDlpPath, [
      '--dump-json',
      '--no-download',
      '--no-warnings',
      '--ffmpeg-location',
      _binaryManager.ffmpegLocation,
      url.trim(),
    ]);

    if (result.exitCode != 0) {
      throw _failureFromProcessResult(result, 'Failed to extract media info');
    }

    final json = jsonDecode(result.stdout.toString().trim());
    return VideoInfo.fromJson(json as Map<String, dynamic>);
  }

  /// Extract playlist info without downloading entries.
  Future<PlaylistInfo> extractPlaylistInfo(String url) async {
    final result = await Process.run(_binaryManager.ytDlpPath, [
      '--dump-single-json',
      '--flat-playlist',
      '--no-warnings',
      url.trim(),
    ]);

    if (result.exitCode != 0) {
      throw _failureFromProcessResult(result, 'Failed to extract playlist');
    }

    final json =
        jsonDecode(result.stdout.toString().trim()) as Map<String, dynamic>;
    final entries = json['entries'] as List<dynamic>? ?? const [];
    final videos = <VideoInfo>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        videos.add(VideoInfo.fromJson(entry));
      } catch (_) {
        // Skip malformed entries
      }
    }

    return PlaylistInfo(
      url: json['webpage_url'] as String? ?? url.trim(),
      title: json['title'] as String? ?? 'Playlist',
      platform:
          json['extractor_key'] as String? ?? json['extractor'] as String?,
      thumbnailUrl: json['thumbnail'] as String?,
      entries: videos,
    );
  }

  /// Download video only (no audio) with real-time progress
  Stream<DownloadProgress> downloadVideo({
    required String taskId,
    required String url,
    required String outputPath,
    required String quality,
    String format = 'mp4',
  }) async* {
    final args = [
      '--newline',
      '--progress',
      '--no-warnings',
      '--ffmpeg-location',
      _binaryManager.ffmpegLocation,
      '-f',
      'bestvideo[height<=$quality]',
      '-o',
      outputPath,
      url.trim(),
    ];

    yield* _runProcess(taskId, args);
  }

  /// Download video WITH audio merged via FFmpeg
  Stream<DownloadProgress> downloadVideoWithAudio({
    required String taskId,
    required String url,
    required String outputPath,
    required String quality,
    String format = 'mp4',
  }) async* {
    final formatStr =
        AppConstants.videoFormats[quality] ?? 'bestvideo+bestaudio/best';

    final args = [
      '--newline',
      '--progress',
      '--no-warnings',
      '--ffmpeg-location',
      _binaryManager.ffmpegLocation,
      '-f',
      formatStr,
      '--merge-output-format',
      format,
      '--postprocessor-args',
      'Merger+ffmpeg:-c:a aac -b:a 192k',
      '-o',
      outputPath,
      url.trim(),
    ];

    yield* _runProcess(taskId, args);
  }

  /// Download audio only with real-time progress
  Stream<DownloadProgress> downloadAudio({
    required String taskId,
    required String url,
    required String outputPath,
    String audioFormat = 'mp3',
    String audioQuality = '192',
  }) async* {
    final args = [
      '--newline',
      '--progress',
      '--no-warnings',
      '--ffmpeg-location',
      _binaryManager.ffmpegLocation,
      '-x',
      '--audio-format',
      audioFormat,
      '--audio-quality',
      audioQuality,
      '-o',
      outputPath,
      url.trim(),
    ];

    yield* _runProcess(taskId, args);
  }

  Stream<DownloadProgress> _runProcess(
    String taskId,
    List<String> args,
  ) async* {
    final process = await Process.start(_binaryManager.ytDlpPath, args);
    _activeProcesses[taskId] = process;

    final controller = StreamController<DownloadProgress>();
    final stderrLines = <String>[];

    // Listen to stdout for progress updates
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final progress = _parseLine(line);
          if (progress != null) {
            controller.add(progress);
          }
          final phase = _parsePhase(line);
          if (phase != null) {
            controller.add(DownloadProgress(phase: phase));
          }
        });

    // Log stderr for debugging
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stderrLines.add(line);
          debugPrint('[yt-dlp stderr] $line');
        });

    // Wait for process to finish, then close the stream
    process.exitCode.then((exitCode) {
      _activeProcesses.remove(taskId);
      if (exitCode != 0) {
        controller.addError(_failureFromLines(stderrLines, exitCode: exitCode));
      }
      controller.close();
    });

    // Forward all progress events until controller closes
    yield* controller.stream;
  }

  DownloadProgress? _parseLine(String line) => parseProgressLine(line);

  @visibleForTesting
  static DownloadProgress? parseProgressLine(String line) {
    // Full progress line: [download]  45.2% of ~150.3MiB at 5.2MiB/s ETA 00:15
    final fullMatch = AppConstants.progressRegex.firstMatch(line);
    if (fullMatch != null) {
      return DownloadProgress(
        percent: double.parse(fullMatch.group(1)!),
        totalSize: fullMatch.group(2),
        speed: fullMatch.group(3),
        eta: fullMatch.group(4),
      );
    }

    // Simple progress: [download]  45.2%
    final simpleMatch = AppConstants.progressSimpleRegex.firstMatch(line);
    if (simpleMatch != null) {
      return DownloadProgress(percent: double.parse(simpleMatch.group(1)!));
    }

    return null;
  }

  static String? _parsePhase(String line) {
    if (line.startsWith('[Merger]')) return 'merging';
    if (line.startsWith('[ExtractAudio]')) return 'converting';
    return null;
  }

  DownloadFailure _failureFromProcessResult(
    ProcessResult result,
    String fallback,
  ) {
    final details = result.stderr.toString().trim();
    return _failureFromText(
      details.isEmpty ? result.stdout.toString().trim() : details,
      fallback: fallback,
      exitCode: result.exitCode,
    );
  }

  DownloadFailure _failureFromLines(
    List<String> lines, {
    required int exitCode,
  }) {
    return _failureFromText(
      lines.join('\n').trim(),
      fallback: 'The download failed.',
      exitCode: exitCode,
    );
  }

  DownloadFailure _failureFromText(
    String text, {
    required String fallback,
    int? exitCode,
  }) {
    final lower = text.toLowerCase();
    String message;
    if (lower.contains('unsupported url')) {
      message = 'This site or URL is not supported by yt-dlp.';
    } else if (lower.contains('private video') ||
        lower.contains('login') ||
        lower.contains('cookies')) {
      message =
          'This media requires login or cookies before it can be downloaded.';
    } else if (lower.contains('requested format is not available') ||
        lower.contains('format is not available')) {
      message =
          'The selected format or quality is not available for this media.';
    } else if (lower.contains('ffmpeg') && lower.contains('not found')) {
      message =
          'FFmpeg was not found. Run setup again from a writable install.';
    } else if (lower.contains('network') ||
        lower.contains('timed out') ||
        lower.contains('connection')) {
      message =
          'Network error while downloading. Check your connection and retry.';
    } else {
      message = fallback;
    }

    return DownloadFailure(message, details: text, exitCode: exitCode);
  }

  /// Cancel an active download
  void cancelDownload(String taskId) {
    final process = _activeProcesses[taskId];
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      _activeProcesses.remove(taskId);
    }
  }

  /// Cancel all active downloads
  void cancelAll() {
    for (final process in _activeProcesses.values) {
      process.kill(ProcessSignal.sigterm);
    }
    _activeProcesses.clear();
  }

  int get activeCount => _activeProcesses.length;
}
